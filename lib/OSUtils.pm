package OSUtils {
  #########################################################
  # These are utility functions for OpenSearch
  #########################################################

  # Always use these
  use strict;
  use warnings;
  use utf8;
  use 5.010;

  use Carp;
  use Exporter;
  use XML::LibXML;
  use XML::LibXML::PrettyPrint;

  use Init qw{$verbose};
  use DBUtils qw{$dbh};
  use Utils;

=head2 get_osdd($url)

Retrieve the OSDD response from the remote source

=cut

  sub get_osdd {
    my $url    = shift;
    my $type   = 'osdd';
    my $status = process($type, $url);
    $status->{request_type} = $type;
    return $status;
  }

=head2 get_granules($url)

Retrieve the granule response from the remote source

=cut

  sub get_granules {
    my $url    = shift;
    my $type   = 'granule';
    my $status = process($type, $url);
    $status->{request_type} = $type;
    return $status;
  }

=head2 process($type, $url)

Retrieve the response from the URL and attempt to parse it. Return
the status hash.

=cut

  sub process {
    my $type = shift;
    my $url  = shift;
    my %status;

    my $response     = $browser->get( $url );
    $status{url}     = $url;
    $status{code}    = $response->code;
    $status{message} = $response->status_line;
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
          my $error = $@;
          $status{error} = $error->{code} . " " . $error->{message};
          say "Failed to parse XML: $status{error}" if $verbose;
        }
        else {
          $status{parsed} = "success";
          if ($type eq 'osdd') {
            my $osdd_response = check_osdd_response($document);
            $status{osdd_response} = $osdd_response;
          }
          elsif ($type eq 'granule') {
            my $granule_response = check_granule_response($document);
            $status{granule_response} = $granule_response;
          }

          if ($verbose) {
            my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
            $pp->pretty_print($document); # modified in-place
            say $document->toString;
          }
        }
      }
      else {
        $status{parsed} = "failed";
        $status{error}  = "HTTP GET " . $status{code};
      }
    }
    else {
      $status{parsed} = "failed";
      $status{error}  = "HTTP GET failed";
    }
    return \%status;
  }

=head2 check_osdd_response($document)

Look for necessary contents in the returned document

=cut

  sub check_osdd_response {
    my $dom = shift;
    my %response;

    my $urls = 0;
    my $queries = 0;
    foreach my $node ($dom->findnodes( q{//*} )) {
      my $node_name = $node->nodeName;
      next if $node_name eq 'OpenSearchDescription';
      if ($node_name eq 'Url') {
        my $url_type = $node->getAttribute('type');
        if ($node->hasAttribute('type')
            and $url_type eq 'application/atom+xml') {
#        say "Url: " . $node->getAttribute('type');
          $urls++;
        }
      }
      elsif ($node_name eq 'Query') {
        if ($node->hasAttribute('role')) {
#        say "Query: " . $node->getAttribute('role');
          $queries++;
        }
      }
      else {
        #      say qq{$node_name: } . $node->textContent;
      }
    }
    $response{Url} = "$urls" . q{ (type='application/atom+xml')};
    $response{Query} = $queries ;

    my $count = $dom->getElementsByTagName("ShortName");
    $response{ShortName} = $count->size();

    $count = $dom->getElementsByTagName("Description");
    $response{Description} = $count->size();

    $count = $dom->getElementsByTagName("Contact");
    $response{Contact} = $count->size();

    $count = $dom->getElementsByTagName("URL");
    $response{URL} = $count->size();

    $count = $dom->getElementsByTagName("Query");
    $response{Query} = $count->size();

    return \%response;
}

=head2 check_granule_response($document)

Look for necessary contents in the returned document

=cut

  sub check_granule_response {
    my $dom = shift;
    my %response;

    my $count = $dom->getElementsByTagName("feed");
    $response{feed} = $count->size();

    $count = $dom->getElementsByTagName("title");
    $response{title} = $count->size();

    $count = $dom->getElementsByTagName("opensearch:totalResults");
    $response{totalResults} = $count->size();

    $count = $dom->getElementsByTagName("opensearch:startIndex");
    $response{startIndex} = $count->size();

    $count = $dom->getElementsByTagName("opensearch:startPage");
    $response{startPage} = $count->size();

    $count = $dom->getElementsByTagName("opensearch:itemsPerPage");
    $response{itemsPerPage} = $count->size();

    return \%response;
}

=head2 fetch_head

Ping the source via a HEAD request

=cut

  sub fetch_head {
    my $source = shift;
    return undef unless $source;
    # say "fetch_head source: $source";

    my $host = DBUtils::get_base($source);
    return undef unless $host;
    # say "fetch_head host: $host";

    my $ret;
    my $url      = $host;
    my $response = $browser->head( $url );
    if (! $response) {
      say "fetch_head: set $source down" if $verbose;
      $ret = set_ping(uc $source, 'down');
      return $ret;
    }
    say "HTTP Status: " . $browser->status if $verbose;
    # say "Response: " . Dumper( $response );

    if ($response->is_success) {
      say "fetch_head: set $source up" if $verbose;
      $ret = set_ping(uc $source, 'up');
    }
    elsif ($response->is_redirect) {
      say "fetch_head: set $source redirected" if $verbose;
      my $location = $browser->response()->header('Location');
      if (defined $location) {
        say "Redirected to $location" if $verbose;
        my $redirect = $browser->head( $location );
        if ($redirect->is_success) {
          say "fetch_head: set $source up" if $verbose;
          $ret = set_ping(uc $source, 'up');
        }
        else {
          say "fetch_head: set $source down" if $verbose;
          $ret = set_ping(uc $source, 'down');
        }
      }
    }
    if ($browser->status < 500) {
      say "fetch_head: set $source up" if $verbose;
      $ret = set_ping(uc $source, 'up');
    }
    else {
      say "fetch_head: set $source down" if $verbose;
      $ret = set_ping(uc $source, 'down');
    }
    return $ret;
}

=head2 get_ping

Get the current value of ping from the source table

=cut

  sub get_ping {
    my $source = shift;
    return undef unless $source;

    my $sql  = q{SELECT ping
                   FROM source
                  WHERE source = ?};
    my $pingval;
    eval {
      $pingval = $dbh->selectrow_arrayref($sql, {}, $source);
    };
    if ($@) {
      return undef;
    }
    return $pingval->[0];
}

=head2 set_ping

Save the current value of ping from the source table

=cut

  sub set_ping {
    my $source  = shift;
    my $pingval = shift;
    # say "Setting source $source to $pingval";
    return undef unless $source;
    return undef unless ($pingval eq 'up' or $pingval eq 'down');

    my $sql = q{UPDATE source
                   SET ping = ?
                 WHERE source = ?};
    my $ret;
    eval {
      $ret = $dbh->do($sql, {}, $pingval, $source);
    };
    if ($@) {
      return undef;
    }
    return $ret;
  }

};

1;
