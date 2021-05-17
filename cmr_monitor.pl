#! /usr/bin/perl
#
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);

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
}
