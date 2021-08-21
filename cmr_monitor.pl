#! /usr/bin/perl -w
#
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);
use 5.010;

use Config::Tiny;
use Data::Dumper::Concise;
use Getopt::Long;
use LWP;
use LWP::UserAgent ();
use LWP::Protocol::https;
use WWW::Mechanize::Timed;
use XML::LibXML;
use XML::LibXML::PrettyPrint;
use FindBin;
use File::Basename;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '.', 'lib');
use Pod::Usage;
use DBI;

use Menu;
use Utils;
use DBUtils;

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

my $verbose      = 0;
my $source       = '';
my $exit_status  = 0;
my $help         = 0;
my $man          = 0;
my $batch        = 0;
my $save         = 0;
my $ping_only    = 0;
my $osdd_only    = 0;
my $granule_only = 0;
my $mail_alert   = 0;

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

my $dirname = dirname(__FILE__);
my $inifile = $dirname . q{/cmr.ini};
my $config  = Config::Tiny->read( $inifile, 'utf8' );
my $ua  = LWP::UserAgent->new(
    protocols_allowed => ['http', 'https'],
    timeout           => 10,
);
$ua->requests_redirectable(['GET', 'HEAD',]);
$ua->max_redirect( 7 );
my $browser = WWW::Mechanize::Timed->new(
    agent             => $ua,
    protocols_allowed => ['http', 'https'],
    ssl_opts          => { verify_hostname => 1 }
    );

# Database config
my $dbname = $config->{database}->{dbname};
my $dbuser = $config->{database}->{dbuser};
my $dbpass = $config->{database}->{dbpass};
my $dsn    = qq{dbi:mysql:$dbname};

our $dbh = DBI->connect($dsn,$dbuser,$dbpass)
    or die "Couldn't connect to database: " . DBI->errstr;

my $links = DBUtils::get_links_all($dbh);

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
$dbh->disconnect;

=head2 menu()

Present the interative menu of sources

=cut

sub menu {
  my $menu = Menu->new( );
  $menu->title( q{Test CWIC Source} );

  my $sources = DBUtils::get_active_sources($dbh);
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
    next unless DBUtils::is_active($dbh, $name);

    unless ($osdd_only or $granule_only) {
      my $head = fetch_head($name);
      if ($head) {
        say qq{Source $name is up};
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
        my $get_status = get_osdd($osdd_link);
        $get_status->{source} = uc $key;
        if (defined $get_status->{error} and $mail_alert) {
          my $source  = $get_status->{source};
          my $type    = $get_status->{request_type};
          my $subject = qq{CWIC Monitor Alert};
          $subject   .= qq{: $source $type};
          my $msg     = qq{Error retrieving $type:\n};
          $msg       .= Dumper( $get_status );
          Utils::mail_alert($subject, $msg, $config);
        }
        if ($verbose) {
          foreach my $param (%$get_status) {
            say "  - $param: " . $get_status->{$param}
              if ($get_status->{$param});
          }
        }
        DBUtils::db_save($dbh, $get_status) if $save;
      }
    }

    unless ($ping_only or $osdd_only) {
      my $granule_link = $links->{uc $key}->{granule};
      if ($granule_link) {
        say "  - Got $granule_link for $name" if $verbose;
        my $get_status = get_granules($granule_link);
        $get_status->{source} = uc $key;
        if (defined $get_status->{error} and $mail_alert) {
          my $source  = $get_status->{source};
          my $type    = $get_status->{request_type};
          my $subject = qq{CWIC Monitor Alert};
          $subject   .= qq{: $source $type};
          my $msg     = qq{Error retrieving $type:\n};
          $msg       .= Dumper( $get_status );
          Utils::mail_alert($subject, $msg, $config);
        }
        if ($verbose) {
          foreach my $key (sort keys %$get_status) {
            say "  - $key: " . $get_status->{$key}
              if $get_status->{$key};
          }
        }
        DBUtils::db_save($dbh, $get_status) if $save;
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
  return unless DBUtils::is_active($dbh, $target);

  my $name;

  if ($target and length $target > 0) {
    unless ($osdd_only or $granule_only) {
      my $head = fetch_head($target);
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
        my $get_status = get_osdd($osdd_link);
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
        DBUtils::db_save($dbh, $get_status) if $save;
      }
    }

    unless ($ping_only or $osdd_only) {
      my $granule_link = $links->{uc $target}->{granule};
      if ($granule_link) {
        say "";
        say "  Granule response:";
        say "  - Got $granule_link for $target";
        my $get_status = get_granules($granule_link);
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
        DBUtils::db_save($dbh, $get_status) if $save;
      }
    }

  }
  else {
    say "No source specified";
  }
  return 0;
}

=head2 get_osdd($url)

Retrieve the OSDD response from the remote source

=cut

sub get_osdd {
  my $url    = shift;
  my $type   = 'osdd';
  my $status = process($type, $url);
  $status->{request_type} = $type;
  return $status;
}

=head2 get_granules($url)

Retrieve the granule response from the remote source

=cut

sub get_granules {
  my $url    = shift;
  my $type   = 'granule';
  my $status = process($type, $url);
  $status->{request_type} = $type;
  return $status;
}

=head2 process($type, $url)

Retrieve the response from the URL and attempt to parse it. Return
the status hash.

=cut

sub process {
  my $type = shift;
  my $url  = shift;
  my %status;

  my $response     = $browser->get( $url );
  $status{url}     = $url;
  $status{code}    = $response->code;
  $status{message} = $response->status_line;
  if ($response->is_success) {
    $status{total_time}   = $browser->client_total_time;
    $status{elapsed_time} = $browser->client_elapsed_time;
    if ($status{code} == 200) {
      my $content = $response->decoded_content;
      my $document;
      eval {
        $document = XML::LibXML->new->load_xml(string => $content);
      };
      if ($@) {
        $status{parsed} = "failed";
        my $error = $@;
        $status{error} = $error->{code} . " " . $error->{message};
        say "Failed to parse XML: $status{error}" if $verbose;
      }
      else {
        $status{parsed} = "success";
        if ($type eq 'osdd') {
          my $osdd_response = check_osdd_response($document);
          $status{osdd_response} = $osdd_response;
        }
        elsif ($type eq 'granule') {
          my $granule_response = check_granule_response($document);
          $status{granule_response} = $granule_response;
        }

        if ($verbose) {
          my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
          $pp->pretty_print($document); # modified in-place
          say $document->toString;
        }
      }
    }
    else {
      $status{parsed} = "failed";
      $status{error}  = "HTTP GET " . $status{code};
    }
  }
  else {
    $status{parsed} = "failed";
    $status{error}  = "HTTP GET failed";
  }
  return \%status;
}

=head2 check_osdd_response($document)

Look for necessary contents in the returned document

=cut

sub check_osdd_response {
  my $dom = shift;
  my %response;

  my $urls = 0;
  my $queries = 0;
  foreach my $node ($dom->findnodes( q{//*} )) {
    my $node_name = $node->nodeName;
    next if $node_name eq 'OpenSearchDescription';
    if ($node_name eq 'Url') {
      my $url_type = $node->getAttribute('type');
      if ($node->hasAttribute('type') and $url_type eq 'application/atom+xml') {
#        say "Url: " . $node->getAttribute('type');
        $urls++;
      }
    }
    elsif ($node_name eq 'Query') {
      if ($node->hasAttribute('role')) {
#        say "Query: " . $node->getAttribute('role');
        $queries++;
      }
    }
    else {
#      say qq{$node_name: } . $node->textContent;
    }
  }
  $response{Url} = "$urls" . q{ (type='application/atom+xml')};
  $response{Query} = $queries ;

  my $count = $dom->getElementsByTagName("ShortName");
  $response{ShortName} = $count->size();

  $count = $dom->getElementsByTagName("Description");
  $response{Description} = $count->size();

  $count = $dom->getElementsByTagName("Contact");
  $response{Contact} = $count->size();

  $count = $dom->getElementsByTagName("URL");
  $response{URL} = $count->size();

  $count = $dom->getElementsByTagName("Query");
  $response{Query} = $count->size();

  return \%response;
}

=head2 check_granule_response($document)

Look for necessary contents in the returned document

=cut

sub check_granule_response {
  my $dom = shift;
  my %response;

  my $count = $dom->getElementsByTagName("feed");
  $response{feed} = $count->size();

  $count = $dom->getElementsByTagName("title");
  $response{title} = $count->size();

  $count = $dom->getElementsByTagName("opensearch:totalResults");
  $response{totalResults} = $count->size();

  $count = $dom->getElementsByTagName("opensearch:startIndex");
  $response{startIndex} = $count->size();

  $count = $dom->getElementsByTagName("opensearch:startPage");
  $response{startPage} = $count->size();

  $count = $dom->getElementsByTagName("opensearch:itemsPerPage");
  $response{itemsPerPage} = $count->size();

  return \%response;
}

=head2 fetch_head

Ping the source via a HEAD request

=cut

sub fetch_head {
  my $source = shift;
  return undef unless $source;
  # say "fetch_head source: $source";

  my $host = DBUtils::get_base($dbh, $source);
  return undef unless $host;
  # say "fetch_head host: $host";

  my $ret;
  my $url      = $host;
  my $response = $browser->head( $url );
  say "Status: " . $browser->status;
  # say "Response: " . Dumper( $response );

  if ($response->is_success) {
    say "fetch_head: set $source up" if $verbose;
    $ret = set_ping(uc $source, 'up');
  }
  elsif ($response->is_redirect) {
    say "fetch_head: set $source redirected" if $verbose;
    my $location = $browser->response()->header('Location');
    if (defined $location) {
      say "Redirected to $location" if $verbose;
      my $redirect = $browser->head( $location );
      if ($redirect->is_success) {
        say "fetch_head: set $source up" if $verbose;
        $ret = set_ping(uc $source, 'up');
      }
      else {
        say "fetch_head: set $source down" if $verbose;
        $ret = set_ping(uc $source, 'down');
      }
    }
  }
  else {
    say "fetch_head: set $source down" if $verbose;
    $ret = set_ping(uc $source, 'down');
  }
  return $ret;
}

=head2 get_ping

Get the current value of ping from the source table

=cut

sub get_ping {
  my $source = shift;
  return undef unless $source;

  my $sql  = q{SELECT ping FROM source WHERE source = ?};
  my $pingval;
  eval {
    $pingval = $dbh->selectrow_arrayref($sql, {}, $source);
  };
  if ($@) {
    return undef;
  }
  return $pingval->[0];
}

=head2 set_ping

Save the current value of ping from the source table

=cut

sub set_ping {
  my $source  = shift;
  my $pingval = shift;
  # say "Setting source $source to $pingval";
  return undef unless $source;
  return undef unless ($pingval eq 'up' or $pingval eq 'down');

  my $sql = q{UPDATE source SET ping = ? WHERE source = ?};
  my $ret;
  eval {
    $ret = $dbh->do($sql, {}, $pingval, $source);
  };
  if ($@) {
    return undef;
  }
  return $ret;
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
