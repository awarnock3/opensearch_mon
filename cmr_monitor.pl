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

use Menu;

=pod

=encoding UTF-8

=head1 CMR Monitoring script

=head2 NAME cmr_monitor.pl

=head2 SYNOPSIS

Monitor CMR and remote CWIC hosts for responses. Run out of cron.

=head1 SUBROUTINES

=cut

my $verbose = '';
my $source = '';
GetOptions(
    verbose => \$verbose,
    'source=s' => \$source,
    );

my $inifile = q{cmr.ini};
my $config  = Config::Tiny->read( $inifile, 'utf8' );
#my $browser = LWP::UserAgent->new();
my $browser = WWW::Mechanize::Timed->new(
    protocols_allowed => ['http', 'https'],
    ssl_opts => { verify_hostname => 1 }
    );

{
    my $name;
    my $osdd;
    my $granule;
    if ($source and length $source > 0) {
        $name = $config->{$source}->{name};
        say "Got $name from config" if $name;
        $osdd = $config->{$source}->{osdd};
        if ($osdd) {
            say "  - Got $osdd for $name";
            my $osdd_status = get_osdd($osdd);
            foreach my $key (%$osdd_status) {
                say "  - $key: " . $osdd_status->{$key}
                if $osdd_status->{$key};
            }
        }
    }
    else {
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
}

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
