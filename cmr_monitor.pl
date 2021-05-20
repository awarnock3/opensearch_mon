#! /usr/bin/perl
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
use LWP::Protocol::https;
use WWW::Mechanize::Timed;
use XML::LibXML;
use XML::LibXML::PrettyPrint;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '.', 'lib');
use Pod::Usage;
use DBI;

use Menu;

=pod

=encoding UTF-8

=head1 NAME cmr_monitor.pl - CMR Monitoring script

=head1 SYNOPSIS

./cmr_monitor.pl

Monitor CMR and remote CWIC hosts for responses. Usually run out of cron.

=head1 SUBROUTINES

=cut

my $verbose     = 0;
my $source      = '';
my $exit_status = 0;
my $help        = 0;
my $man         = 0;
my $batch       = 0;
my $save        = 0;

GetOptions(
    'help|h|?'  => \$help,
    man         => \$man,
    'verbose|v' => \$verbose,
    'source=s'  => \$source,
    batch       => \$batch,
    save        => \$save,
    ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my $inifile = q{cmr.ini};
my $config  = Config::Tiny->read( $inifile, 'utf8' );
#my $browser = LWP::UserAgent->new();
my $browser = WWW::Mechanize::Timed->new(
    protocols_allowed => ['http', 'https'],
    ssl_opts => { verify_hostname => 1 }
    );

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

=head2 menu()

Present the interative menu of sources

=cut

sub menu {
    say "No menu system available yet.";
}

=head2 batch()

Run in batch mode across all sources

=cut

sub batch {
    my $name;
    my $osdd;
    my $granule;

    foreach my $key (sort keys %$config) {
        $name = $config->{$key}->{name};
        say "Got $name from config" if $name;
        $osdd = $config->{$key}->{osdd};
        if ($osdd) {
            say "  - Got $osdd for $name";
            my $osdd_status = get_osdd($osdd);
            foreach my $param (%$osdd_status) {
                say "  - $param: " . $osdd_status->{$param}
                if $osdd_status->{$param};
            }
        }
    }
}

=head2 get_single()

Test one specified source

=cut

sub get_single {
    my $target = shift;
    
    my $name;
    my $osdd;
    my $granule;

    if ($target and length $target > 0) {
        $name = $config->{$target}->{name};
        say "Got $name from config" if $name;
        $osdd = $config->{$target}->{osdd};
        if ($osdd) {
            say "  - Got $osdd for $name";
            my $osdd_status = get_osdd($osdd);
            $osdd_status->{source} = uc $target;
            foreach my $key (sort keys %$osdd_status) {
                say "  - $key: " . $osdd_status->{$key}
                if $osdd_status->{$key};
            }
            db_save($osdd_status) if $save;
        }
    }
    else {
        say "No source specified";
    }
}

=head2 get_osdd($url)

Retrieve the OSDD from the remote source

=cut

sub get_osdd {
    my $url = shift;
    my %status;
    my $response = $browser->get( $url );
    $status{code}         = $response->code;
    $status{message}      = $response->message;
    if ($response->is_success) {
        $status{content_type} = $response->content_type;
        $status{total_time}   = $browser->client_total_time;
        $status{elapsed_time} = $browser->client_elapsed_time;
        if ($status{code} == 200) {
            my $content = $response->content;
            $content =~  s/^\s+//;
            my $document;
            eval {
                $document = XML::LibXML->new->load_xml(string => $content);
            };
            if ($@) {
                $status{parsed} = "failed";
                $status{error}  = $@;
                say "Failed to parse XML: $@" if $verbose;
            }
            else {
                $status{parsed} = "success";
                if ($verbose) {
                    my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
                    $pp->pretty_print($document); # modified in-place
                    say $document->toString;
                }
            }
        }
    }

    return \%status;
}

sub db_save {
    my $status = shift;

    # Database config
    my $dbname = $config->{database}->{dbname};
    my $dbuser = $config->{database}->{dbuser};
    my $dbpass = $config->{database}->{dbpass};
    my $dsn = qq{dbi:mysql:$dbname};

    my $dbh = DBI->connect($dsn,$dbuser,$dbpass)
        or die "Couldn't connect to database: " . DBI->errstr;
    my $sql = q{INSERT INTO monitor 
                       (id, http_status, total_time, elapsed_time, http_message,
                        parsed, fk_sourceid)
                 VALUES (NULL, ?, ?, ?, ?, ?,
                         (SELECT sourceid FROM source WHERE source = ?))};
    eval {
        $dbh->do($sql, {}, $status->{code}, $status->{total_time},
                 $status->{elapsed_time}, $status->{message},
                 $status->{parsed}, $status->{source} );
    };
    if ($@) {
        die "Insert failed";
    }
    if ($status->{parsed} eq 'failed') {
        my $monitor_id = $dbh->{mysql_insertid};
        $dbh->do(q{UPDATE monitor SET error = ? WHERE id = ?},
                 {}, $status->{error}, $monitor_id);
    }
}

# ABSTRACT: Monitor/test CWIC OpenSearch sources
__END__

=head1 DESCRIPTION

./cmr_monitor.pl

Test all sources in cmr.ini

./cmr_monitor.pl --source=ccmeo

Test one source in cmr.ini

=head1 AUTHOR

Archie Warnock (warnock@awcubed.com)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by A/WWW Enterprises under contract to NASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
