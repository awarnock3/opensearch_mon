package Init {
  #########################################################
  # Initial global variables
  #########################################################

  # Always use these
  use strict;
  use warnings;
  use utf8;
  use 5.010;

  # Other use statements
  use Carp;
  use Exporter;
  use DBI;
  use Config::Tiny;

  our (@EXPORT, @ISA);     # Global variables

  @ISA = qw(Exporter);      # Take advantage of Exporter's capabilities
  @EXPORT = qw{$config $verbose $source $exit_status $help $man $batch
            $save $ping_only $osdd_only $granule_only $mail_alert};

  my $inifile = q{cmr.ini};
  our $config  = Config::Tiny->read( $inifile, 'utf8' );

  our $verbose      = 0;
  our $source       = '';
  our $exit_status  = 0;
  our $help         = 0;
  our $man          = 0;
  our $batch        = 0;
  our $save         = 0;
  our $ping_only    = 0;
  our $osdd_only    = 0;
  our $granule_only = 0;
  our $mail_alert   = 0;

};

1;
