#! /usr/bin/perl -w
#
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);
use 5.010;

use Data::Dumper::Concise;
use Getopt::Long;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '.', 'lib');
use Pod::Usage;

use Init;
use Menu;
use DBUtils;
use Utils;
use OSUtils;

=pod

=encoding UTF-8

=head1 NAME cmr_monitor.pl - CMR Monitoring script

=head1 SYNOPSIS

./cmr_monitor.pl [--help|--man|--verbose|--batch|--save|--source=XXX|--osdd_only|--granule_only]

=over 4

Monitor CMR and remote CWIC hosts for responses. Usually run out of cron. There is a single entry available (see --source). If neither --source nor --batch are specified, presents a menu for selecting a single source.

=over 4

--help

=over 2

Show this help

=back

--man

=over 2

Show the man page

=back

--verbose

=over 2

Print extra output, notably retrieved XML

=back

--batch

=over 2

Run in batch mode - test each active provider in cmr.ini

=back

--save

=over 2

Save results to the database

=back

--mail

=over 2

Send an email alert if any errors occur

=back

--source=XXX

=over 2

Test just one source specified in cmr.ini

=back

--ping

=over 2

Just ping the selected host

=back

--osdd

=over 2

Just test the OSDD link (skip the granules)

=back

--granule

=over 2

Just test the granule request link (skip the OSDD)

=back

=back

=back

=head1 SUBROUTINES

=cut

GetOptions(
           'help|h|?'  => \$help,
           man         => \$man,
           'verbose|v' => \$verbose,
           'source=s'  => \$source,
           batch       => \$batch,
           save        => \$save,
           mail        => \$mail_alert,
           ping        => \$ping_only,
           osdd        => \$osdd_only,
           granule     => \$granule_only,
          ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my $links = DBUtils::get_links_all();

MAIN:
{
  if ($batch) {
    batch();
  }
  elsif ($source) {
    get_single($source);
  }
  else {
    menu();
  }
}
# $dbh->disconnect;

=head2 menu()

Present the interative menu of sources

=cut

sub menu {
  my $menu = Menu->new( );
  $menu->title( q{Test CWIC Source} );

  my $sources = DBUtils::get_active_sources();
  foreach my $source (sort keys %$sources) {
    $menu->add(
               $sources->{$source}->{label} => sub{
                 get_single( $source );
                 Utils::pause();
                 $menu->print();
               },
              );
  }

  # Build the rest of the menu
  $menu->add(
             'Options'    => sub{ options_menu(); },
            );
  $menu->add(
             'Exit'       => sub{ $menu->exit(1); },
            );

  $menu->print();
  return 0;
}

=head2 options_menu()

Present the menu to set optional parameters

=cut

sub options_menu {
  my $options = Menu->new( );
  $options->title( q{Set parameters} );

  if ($save) {
    $options->add(
                  'Set save off'      => sub{ $save = 0; },
                 );
  }
  else {
    $options->add(
                  'Set save on'       => sub{ $save = 1; },
                 );
  }
  if ($verbose) {
    $options->add(
                  'Set verbose off'   => sub{ $verbose = 0; },
                 );
  }
  else {
    $options->add(
                  'Set verbose on'    => sub{ $verbose = 1; },
                 );
  }
  unless ($osdd_only) {
    $options->add(
                  'Get OSDD only'     => sub{
                    $osdd_only    = 1;
                    $granule_only = 0;
                  },
                 );
  }
  unless ($granule_only) {
    $options->add(
                  'Get granules only' => sub{
                    $granule_only = 1;
                    $osdd_only    = 0;
                  },
                 );
  }
  $options->add( 'Return'     => sub{ menu();} );
  $options->print();
  menu();
  return 0;
}

=head2 batch()

Run in batch mode across all sources

=cut

sub batch {
  my $name;

  foreach my $key (sort keys %$links) {
    $name = $links->{uc $key}->{fk_source};
    next unless DBUtils::is_active($name);

    unless ($osdd_only or $granule_only) {
      my $head = OSUtils::fetch_head($name);
      if ($head) {
        say qq{Source $name is up} if $verbose;
        $name = $links->{uc $name}->{fk_source};
        say qq{Got $name from config} if $name and $verbose;
      }
      else {
        say "Source $name is down";
      }
    }

    unless ($ping_only or $granule_only) {
      my $osdd_link = $links->{uc $key}->{osdd};
      if ($osdd_link) {
        say "  - Got $osdd_link for $name" if $verbose;
        my $get_status = OSUtils::get_osdd($osdd_link);
        $get_status->{source} = uc $key;
        if (defined $get_status->{error} and $mail_alert) {
          my $source  = $get_status->{source};
          my $type    = $get_status->{request_type};
          my $subject = qq{CWIC Monitor Alert};
          $subject   .= qq{: $source $type};
          my $msg     = qq{Error retrieving $type:\n};
          $msg       .= Dumper( $get_status );
          Utils::mail_alert($subject, $msg);
        }
        if ($verbose) {
          foreach my $param (%$get_status) {
            say "  - $param: " . $get_status->{$param}
              if ($get_status->{$param});
          }
        }
        DBUtils::db_save($get_status) if $save;
      }
    }

    unless ($ping_only or $osdd_only) {
      my $granule_link = $links->{uc $key}->{granule};
      if ($granule_link) {
        say "  - Got $granule_link for $name" if $verbose;
        my $get_status = OSUtils::get_granules($granule_link);
        $get_status->{source} = uc $key;
        if (defined $get_status->{error} and $mail_alert) {
          my $source  = $get_status->{source};
          my $type    = $get_status->{request_type};
          my $subject = qq{CWIC Monitor Alert};
          $subject   .= qq{: $source $type};
          my $msg     = qq{Error retrieving $type:\n};
          $msg       .= Dumper( $get_status );
          Utils::mail_alert($subject, $msg);
        }
        if ($verbose) {
          foreach my $key (sort keys %$get_status) {
            say "  - $key: " . $get_status->{$key}
              if $get_status->{$key};
          }
        }
        DBUtils::db_save($get_status) if $save;
      }
    }
  }
  return 0;
}

=head2 get_single()

Test one specified source

=cut

sub get_single {
  my $target = shift;
  return unless DBUtils::is_active($target);

  my $name;

  if ($target and length $target > 0) {
    unless ($osdd_only or $granule_only) {
      my $head = OSUtils::fetch_head($target);
      if ($head) {
        say qq{Source $target is up};
        $name = $links->{uc $target}->{fk_source};
        say qq{Got $name from config} if $name and $verbose;
      }
      else {
        say "Source $target is down";
      }
    }

    unless ($ping_only or $granule_only) {
      my $osdd_link = $links->{uc $target}->{osdd};
      if ($osdd_link) {
        say "";
        say "  OSDD response:";
        say "  - Got $osdd_link for $target";
        my $get_status = OSUtils::get_osdd($osdd_link);
        $get_status->{source} = uc $target;
        foreach my $key (sort keys %$get_status) {
          if ($key eq 'osdd_response') {
            my $osdd_response = $get_status->{$key};
            foreach my $response (sort keys %$osdd_response) {
              say "  - OSDD:num <$response>: " . $osdd_response->{$response}
                if defined $osdd_response->{$response};
            }
          }
          else {
            say "  - $key: " . $get_status->{$key}
              if $get_status->{$key};
          }
        }
        DBUtils::db_save($get_status) if $save;
      }
    }

    unless ($ping_only or $osdd_only) {
      my $granule_link = $links->{uc $target}->{granule};
      if ($granule_link) {
        say "";
        say "  Granule response:";
        say "  - Got $granule_link for $target";
        my $get_status = OSUtils::get_granules($granule_link);
        foreach my $key (sort keys %$get_status) {
          $get_status->{source} = uc $target;
          if ($key eq 'granule_response') {
            my $granule_response = $get_status->{$key};
            foreach my $response (sort keys %$granule_response) {
              say "  - Granule:num <$response>: " . $granule_response->{$response}
                if defined $granule_response->{$response};
            }
          }
          else {
            say "  - $key: " . $get_status->{$key}
              if $get_status->{$key};
          }
        }
        DBUtils::db_save($get_status) if $save;
      }
    }

  }
  else {
    say "No source specified";
  }
  return 0;
}

# ABSTRACT: Monitor/test CWIC OpenSearch sources
__END__

=head1 DESCRIPTION

./cmr_monitor.pl

=over 4

Test all sources in cmr.ini

=back

./cmr_monitor.pl --source=ccmeo

=over 4


Test one source in cmr.ini

=back

=head1 AUTHOR

Archie Warnock (warnock@awcubed.com)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by A/WWW Enterprises under contract to NASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
