package DBUtils {
  #########################################################
  # These are general utility functions
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
  use Init qw{$config};

  our (@EXPORT, @ISA);     # Global variables

  @ISA = qw(Exporter);      # Take advantage of Exporter's capabilities
  @EXPORT = qw{$dbh};

  # Database config
  my $dbname = $config->{database}->{dbname};
  my $dbuser = $config->{database}->{dbuser};
  my $dbpass = $config->{database}->{dbpass};
  my $dsn    = qq{dbi:mysql:$dbname};

  our $dbh = DBI->connect($dsn,$dbuser,$dbpass)
    or die "Couldn't connect to database: " . DBI->errstr;


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
    return 0;
}

=head2 get_links_all

Grab the OSDD and Granule request links from the database

=cut

  sub get_links_all {
    my $sql       = q{SELECT fk_source, osdd, granule
                        FROM links};
    my $all_links = $dbh->selectall_hashref($sql, 'fk_source');
    return $all_links;
}

=head2 is_active

Return 1 if the source is active

=cut

  sub is_active {
    my $source = shift;
    my $sql    = q{SELECT status
                     FROM source
                    WHERE source = ?};
    my $active = $dbh->selectrow_arrayref($sql, {}, $source);
    return ($active and $active->[0] eq 'ACTIVE') ? 1 : 0;
}

=head2 get_base

Return hostname if the source is active

=cut

  sub get_base {
    my $source = shift;
    my $sql    = q{SELECT base_url
                     FROM links
                    WHERE fk_source = ?};
    my $host   = $dbh->selectrow_arrayref($sql, {}, $source);
    return $host->[0] if $host;
    return undef;
  }

=head2 get_active_sources()

Return list of all active sources and labels from Source table

=cut

  sub get_active_sources {
    my $sql     = q{SELECT source, label
                      FROM source
                     WHERE status = 'ACTIVE'};
    my $sources = $dbh->selectall_hashref($sql, 'source');
    return $sources;
  }

};

1;
