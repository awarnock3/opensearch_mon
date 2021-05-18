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

=pod

=encoding UTF-8

=head1 CMR Monitoring script

=head2 NAME cmr_monitor.pl

=head2 SYNOPSIS

Monitor CMR and remote CWIC hosts for responses. Run out of cron.

=head1 SUBROUTINES

=cut

my $verbose = '';
GetOptions(
    verbose => \$verbose,
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
    foreach my $key (sort keys %$config) {
        $name = $config->{$key}->{name};
        say "Got $name from config" if $name;
        $osdd = $config->{$key}->{osdd};
        if ($osdd) {
            say "  - Got $osdd for $name";
            my $osdd_status = get_osdd($osdd);
            foreach $key (%$osdd_status) {
                say "  - $key: " . $osdd_status->{$key}
                if $osdd_status->{$key};
            }
        }
    }
}

sub get_osdd {
    my $url = shift;
    my %status;
    my $response = $browser->get( $url );
    $status{code}         = $response->status_line;
    if ($response->is_success) {
        $status{content_type} = $response->content_type;
        $status{total_time}   = $browser->client_total_time;
        $status{elapsed_time} = $browser->client_elapsed_time;
        my $content = $response->content;
        $content =~  s/^\s+//;
        my $document;
        eval {
            $document = XML::LibXML->load_xml(string => $content);
        };
        if ($@) {
            say "Failed to parse XML";
        }
        else {
            my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
            $pp->pretty_print($document); # modified in-place
            say $document->toString;
        }
    }

    return \%status;
}
