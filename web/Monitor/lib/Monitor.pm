package Monitor;
use 5.10.0;
use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Template::TemplateToolkit;
use Data::Dumper::Concise;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Monitor::Utils;

our $VERSION = '0.2';

sub connect_db {
    my $dbname = q{cmr_monitor};
    my $dbuser = q{cwic_user};
    my $dbpass = q{Quasar06$cwic};
    my $dsn    = qq{dbi:mysql:$dbname};

    my $dbh = DBI->connect($dsn,$dbuser,$dbpass)
        or die "Couldn't connect to database: " . DBI->errstr;

    return $dbh;
}

my $dbh = connect_db();

get '/' => sub {
  # Get the MOTD
  my $motd = Monitor::Utils::motd($dbh);

  # Get some summary statistics
  my $sql = q{SELECT request_type, TRUNCATE(MIN(elapsed_time), 4) AS min_et,
                    TRUNCATE(MAX(elapsed_time), 4) AS max_et,
                    TRUNCATE(AVG(elapsed_time), 4) AS avg_et,
                    label, COUNT(id) AS total_requests, source,
                    (SELECT count(*)
                       FROM monitor
                      WHERE error is not null
                            AND fk_source = s.source
                            AND request_type = m.request_type) AS errors,
                      (SELECT count(*)
                       FROM monitor
                      WHERE error is not null
                            AND fk_source = s.source
                            AND request_type = m.request_type
                       AND timestamp >= NOW() - INTERVAL 7 DAY) AS errors_week,
                      (SELECT count(*)
                       FROM monitor
                      WHERE error is not null
                            AND fk_source = s.source
                            AND request_type = m.request_type
                       AND timestamp >= NOW() - INTERVAL 14 DAY) AS errors_2weeks,
                      (SELECT count(*)
                       FROM monitor
                      WHERE error is not null
                            AND fk_source = s.source
                            AND request_type = m.request_type
                       AND timestamp >= NOW() - INTERVAL 1 MONTH) AS errors_month  
               FROM monitor m
                    JOIN source s ON (m.fk_source = s.source)
              WHERE s.status = 'Active'
              GROUP BY fk_source,request_type
              ORDER BY fk_source};
  my $stats = $dbh->selectall_arrayref($sql, { Slice => {} });
  # DEBUG Dumper( $stats );

  # Build the output table
  my %sources;
  foreach my $row (@$stats) {
    my $source  = $row->{source};
    my $request = $row->{request_type};
    if ($request eq 'osdd') {
      my %osdd_test;
      $osdd_test{max_et}         = $row->{max_et};
      $osdd_test{min_et}         = $row->{min_et};
      $osdd_test{avg_et}         = $row->{avg_et};
      $osdd_test{label}          = $row->{label};
      $osdd_test{errors_week}    = $row->{errors_week};
      $osdd_test{errors_2weeks}  = $row->{errors_2weeks};
      $osdd_test{errors_month}   = $row->{errors_month};
      $osdd_test{errors}         = $row->{errors};
      $osdd_test{total_requests} = $row->{total_requests};
      $sources{$source}{osdd} = \%osdd_test;
    }
    elsif ($request eq 'granule') {
      my %granule_test;
      $granule_test{max_et}         = $row->{max_et};
      $granule_test{min_et}         = $row->{min_et};
      $granule_test{avg_et}         = $row->{avg_et};
      $granule_test{label}          = $row->{label};
      $granule_test{errors_week}    = $row->{errors_week};
      $granule_test{errors_2weeks}  = $row->{errors_2weeks};
      $granule_test{errors_month}   = $row->{errors_month};
      $granule_test{errors}         = $row->{errors};
      $granule_test{total_requests} = $row->{total_requests};
      $sources{$source}{granule} = \%granule_test;
    }

    # Figure out number of errors in the past 7, 14, 30 days for each
  }
  #DEBUG Dumper( %sources );

  template 'index' => {
                       title      => 'Statistics',
                       statistics => \%sources,
                       motd       => $motd,
                      };
};

get '/results' => sub {
  my $sql = q{SELECT request_type, http_status,
                     TRUNCATE(total_time, 4) AS total_time,
                     TRUNCATE(elapsed_time, 4) AS elapsed_time,
                     http_message, parsed, error,
                     timestamp, url, label, source
                FROM monitor m
                     JOIN source s ON (m.fk_source = s.source)
               WHERE s.status = 'Active'
                     AND timestamp >= NOW() - INTERVAL 7 DAY};

  my $results = $dbh->selectall_arrayref($sql, { Slice => {} } );
  # DEBUG Dumper( $results );

  template 'results' => {
                         title   => 'Monitor',
                         results => $results,
                        };
};

get '/results/:source' => sub {
  my $source = route_parameters->get('source');
  # DEBUG "Got source $source";

  my $sql = q{SELECT request_type, http_status,
                     TRUNCATE(total_time, 4) AS total_time,
                     TRUNCATE(elapsed_time, 4) AS elapsed_time,
                     http_message, parsed, error,
                     timestamp, url, label, source
                FROM monitor m
                     JOIN source s ON (m.fk_source = s.source)
               WHERE s.source = ?};
  my $results = $dbh->selectall_arrayref($sql, { Slice => {} }, $source );
  # DEBUG Dumper( $results );

  template 'results' => {
                         title   => 'Monitor',
                         results => $results,
                        };
};

post '/results' => sub {
  my $time_int = body_parameters->get('Days');
  # DEBUG qq{Asking for $time_int days};

  my $results;
  my $where = q{WHERE s.status = 'Active'};
  if ($time_int > 0) {
    $where .= q{ AND timestamp >= NOW() - INTERVAL ? DAY};
  }
  my $sql = qq{SELECT request_type, http_status,
                     TRUNCATE(total_time, 4) AS total_time,
                     TRUNCATE(elapsed_time, 4) AS elapsed_time,
                     http_message, parsed, error,
                     timestamp, url, label, source
                FROM monitor m
                     JOIN source s ON (m.fk_source = s.source)
               $where};

  if ($time_int > 0) {
    $results = $dbh->selectall_arrayref($sql, { Slice => {} }, $time_int );
  } else {
    $results = $dbh->selectall_arrayref($sql, { Slice => {} });
  }

  template 'results' => {
                         title   => 'Monitor',
                         results => $results,
                        };
};

get '/source' => sub {

  my $sql = q{SELECT source,label,status,ping FROM source ORDER BY source};
  my $sources = $dbh->selectall_hashref($sql, 'source' );
  # DEBUG Dumper( $sources );

  template 'source' => {
                        title   => 'Monitor - Sources',
                        sources => $sources,
                       };
};

get '/link' => sub {
  my $sql = q{SELECT source,osdd,granule,label
                FROM links l
                     JOIN source s ON (l.fk_source = s.source)};
  my $links = $dbh->selectall_hashref($sql, 'source' );
  # DEBUG Dumper( $links );

  template 'link' => {
                      title => 'Monitor - Links',
                      links => $links,
                     };
};

get '/check' => sub {
  my $sql     = q{SELECT source,label FROM source WHERE status = 'ACTIVE'};
  my $sources = $dbh->selectall_hashref($sql, 'source');
  template 'check' => {
                       title   => 'Check a Source',
                       sources => $sources,
                      };
};

post '/check' => sub {
  my %check;

  my $source = body_parameters->get('Source');
  my $cmr_path = Monitor::Utils::script_path($dbh);
  # DEBUG $cmr_path;
  my $response;
  eval {
    $response = `$cmr_path --source=$source`;
  };
  if ($@) {
    DEBUG "Got error";
  }
  else {
    DEBUG $response;
  }
  $check{response} = $response;
  # DEBUG Dumper( %check );
  my $sql     = q{SELECT source,label FROM source WHERE status = 'ACTIVE'};
  my $sources = $dbh->selectall_hashref($sql, 'source');

  template 'check' => {
                       title   => 'Check a Source',
                       check   => \%check,
                       sources => $sources,
                      };
};

get '/about' => sub {

  template 'about' => {
                       title => 'About Monitor',
                      };
};

get '/contact' => sub {

  template 'contact' => {
                         title => 'Contact us',
                        };
};

true;
