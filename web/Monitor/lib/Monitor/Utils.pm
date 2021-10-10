package Monitor::Utils;
use Dancer2;
use Dancer2::Plugin::Database;

use Data::Dumper::Concise;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

sub motd {
  my $dbh = shift;
  my $param = q{motd};
  my $motd = $dbh->selectrow_arrayref(
     q{SELECT value FROM config WHERE param = ?}, {}, $param);
  return $motd->[0];
}

sub script_path {
  my $dbh = shift;
  my $param = q{cmr_monitor};
  my $script_path = $dbh->selectrow_arrayref(
     q{SELECT value FROM config WHERE param = ?}, {}, $param);
  return $script_path->[0];
}

true;
