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
#use Encode qw(decode encode);

use Menu;

=pod

=encoding UTF-8

=head1 NAME cmr_monitor.pl - CMR Monitoring script

=head1 SYNOPSIS

./cmr_monitor.pl [--help|--man|--verbose|--batch|--save|--source=XXX|--osdd_only|--granule_only]

=over 4

Monitor CMR and remote CWIC hosts for responses. Usually run out of cron. There is a single entry available (see --source).

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

--source=XXX

=over 2

Test just one source specified in cmr.ini

=back

--osdd_only

=over 2

Just test the OSDD link (skip the granules)

=back

--granule_only

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
my $osdd_only    = 0;
my $granule_only = 0;

GetOptions(
    'help|h|?'   => \$help,
    man          => \$man,
    'verbose|v'  => \$verbose,
    'source=s'   => \$source,
    batch        => \$batch,
    save         => \$save,
    osdd_only    => \$osdd_only,
    granule_only => \$granule_only,
    ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my $inifile = q{cmr.ini};
my $config  = Config::Tiny->read( $inifile, 'utf8' );
#my $browser = LWP::UserAgent->new(
#    protocols_allowed => ['http', 'https'],
#    ssl_opts => { verify_hostname => 1 }
#    );
my $browser = WWW::Mechanize::Timed->new(
    protocols_allowed => ['http', 'https'],
    ssl_opts => { verify_hostname => 1 }
    );

# Database config
my $dbname = $config->{database}->{dbname};
my $dbuser = $config->{database}->{dbuser};
my $dbpass = $config->{database}->{dbpass};
my $dsn = qq{dbi:mysql:$dbname};

my $dbh = DBI->connect($dsn,$dbuser,$dbpass)
    or die "Couldn't connect to database: " . DBI->errstr;

my $links = get_links_all();

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
    say "No menu system available yet.";
}

=head2 batch()

Run in batch mode across all sources

=cut

sub batch {
    my $name;

    foreach my $key (sort keys %$links) {
        $name = $links->{uc $key}->{fk_source};
        next unless is_active($name);

        say "Got $name from config" if ($name and $verbose);
        unless ($granule_only) {
            my $osdd_link = $links->{uc $key}->{osdd};
            if ($osdd_link) {
                say "  - Got $osdd_link for $name" if $verbose;
                my $get_status = get_osdd($osdd_link);
                $get_status->{source} = uc $key;
                if ($verbose) {
                    foreach my $param (%$get_status) {
                        say "  - $param: " . $get_status->{$param}
                        if ($get_status->{$param});
                    }
                }
                db_save($get_status) if $save;
            }
        }
        unless ($osdd_only) {
            my $granule_link = $links->{uc $key}->{granule};
            if ($granule_link) {
                say "  - Got $granule_link for $name";
                my $get_status = get_granules($granule_link);
                $get_status->{source} = uc $key;
                foreach my $key (sort keys %$get_status) {
                    say "  - $key: " . $get_status->{$key}
                    if $get_status->{$key};
                }
                db_save($get_status) if $save;
            }
        }
    }
}

=head2 get_single()

Test one specified source

=cut

sub get_single {
    my $target = shift;
    return unless is_active($target);
    
    my $name;

    if ($target and length $target > 0) {
        $name = $links->{uc $target}->{fk_source};
        say "Got $name from config" if $name;
        unless ($granule_only) {
            my $osdd_link = $links->{uc $target}->{osdd};
            if ($osdd_link) {
                say "  - Got $osdd_link for $name";
                my $get_status = get_osdd($osdd_link);
                $get_status->{source} = uc $target;
                foreach my $key (sort keys %$get_status) {
                    say "  - $key: " . $get_status->{$key}
                    if $get_status->{$key};
                }
                db_save($get_status) if $save;
            }
        }
        unless ($osdd_only) {
            my $granule_link = $links->{uc $target}->{granule};
            if ($granule_link) {
                say "  - Got $granule_link for $name";
                my $get_status = get_granules($granule_link);
                $get_status->{source} = uc $target;
                foreach my $key (sort keys %$get_status) {
                    say "  - $key: " . $get_status->{$key}
                    if $get_status->{$key};
                }
                db_save($get_status) if $save;
            }
        }
    }
    else {
        say "No source specified";
    }
}

=head2 get_osdd($url)

Retrieve the OSDD response from the remote source

=cut

sub get_osdd {
    my $url = shift;
    my $status = process($url);
    $status->{request_type} = 'osdd';
    return $status;
}

=head2 get_granules($url)

Retrieve the granule response from the remote source

=cut

sub get_granules {
    my $url = shift;
    my $status = process($url);
    $status->{request_type} = 'granule';
    return $status;
}

=head2 process($url)

Retrieve the response from the URL and attempt to parse it. Return
the status hash.

=cut

sub process {
    my $url = shift;
    my %status;
    my $response = $browser->get( $url );
    $status{url}          = $url;
    $status{code}         = $response->code;
    $status{message}      = $response->status_line;
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
                #                $status{error}  = $@;
                my $error = $@;
                $status{error} = $error->{code} . " " . $error->{message};
                say "Failed to parse XML: $status{error}" if $verbose;
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
        else {
            $status{parsed} = "failed";
            $status{error} = "HTTP GET " . $status{code};
        }
    }
    else {
        $status{parsed} = "failed";
        $status{error} = "HTTP GET failed";
    }
    return \%status;
}

=head2 db_save($status_hashptr)

Persist the status hash into the database

=cut

sub db_save {
    my $status = shift;

    my $sql = q{INSERT INTO monitor 
                       (id, request_type, http_status, total_time,
                        elapsed_time, http_message, parsed, fk_source, url)
                 VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?)};
    eval {
        $dbh->do($sql, {}, $status->{request_type}, $status->{code},
                 $status->{total_time}, $status->{elapsed_time},
                 $status->{message}, $status->{parsed}, $status->{source},
                 $status->{url} );
    };
    if ($@) {
        die "Insert failed";
    }
    if (defined $status->{parsed} and $status->{parsed} eq 'failed') {
        my $monitor_id = $dbh->{mysql_insertid};
        $dbh->do(q{UPDATE monitor SET error = ? WHERE id = ?},
                 {}, $status->{error}, $monitor_id);
    }
}

=head2 get_links_all

Grab the OSDD and Granule request links from the database

=cut

sub get_links_all {
    my $sql = q{SELECT fk_source,osdd,granule from links};
    my $links = $dbh->selectall_hashref($sql, 'fk_source');
    return $links;
}

=head2 is_active

Return 1 if the source is activef

=cut

sub is_active {
    my $source = shift;
    my $sql = q{SELECT status FROM source where source = ?};
    my $active = $dbh->selectrow_arrayref($sql, {}, $source);
    return ($active->[0] eq 'ACTIVE') ? 1 : 0;
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
