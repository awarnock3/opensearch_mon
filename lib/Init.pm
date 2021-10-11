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
  use FindBin;
  use Getopt::Long;
  use Pod::Usage;

  our (@EXPORT, @ISA);     # Global variables

  @ISA = qw(Exporter);      # Take advantage of Exporter's capabilities
  @EXPORT = qw{$config $verbose $source $exit_status $help $man $batch
            $save $ping_only $osdd_only $granule_only $mail_alert $inifile};
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

  my $ini;
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
             'ini=s'     => \$ini,
            ) or pod2usage(2);
  pod2usage(1) if $help;
  pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

  our $inifile; # May come from command line parameter set in main
  if ($ini and -f $ini) {
    $inifile = $ini;
  }
  elsif ($ini and ! -f $ini) {
    my $dirname = $FindBin::Bin;
    $inifile = qq{$dirname/$ini};
  }
  else {
    my $dirname = $FindBin::Bin;
    $inifile = qq{$dirname/os_monitor.ini};
  }
  say "Loading config from $inifile";
  our $config  = Config::Tiny->read( $inifile, 'utf8' );

};

1;
