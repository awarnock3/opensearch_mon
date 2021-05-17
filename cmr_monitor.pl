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

my $inifile  = q{cmr.ini};
my $config   = Config::Tiny->read( $inifile, 'utf8' );

{
    my $name;
    my $osdd;
    my $granule;
    foreach my $key (sort keys %$config) {
        $name = $config->{$key}->{name};
        say "Got $name from config" if $name;
        $osdd = $config->{$key}->{osdd};
        say "  - Got $osdd for $name" if $osdd;
    }
}
