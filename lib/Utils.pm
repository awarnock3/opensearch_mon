package Utils {
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
  use Term::ReadKey;
  use LWP;
  use LWP::UserAgent ();
  use LWP::Protocol::https;
  use WWW::Mechanize::Timed;
  use Net::SMTP 3.0;
  use Email::Sender::Transport::SMTP;
  use Email::Stuffer;
  use MIME::Types;
  use Authen::SASL qw(Perl);

  use Init qw{$config};

  our (@EXPORT, @ISA);     # Global variables

  @ISA = qw(Exporter);      # Take advantage of Exporter's capabilities
  @EXPORT = qw{$ua $browser};

  my $ua  = LWP::UserAgent->new(
                                protocols_allowed => ['http', 'https'],
                                timeout           => 10,
                               );
  $ua->requests_redirectable(['GET', 'HEAD',]);
  $ua->max_redirect( 7 );
  our $browser = WWW::Mechanize::Timed->new(
      agent             => $ua,
      protocols_allowed => ['http', 'https'],
      ssl_opts          => { verify_hostname => 1 }
                                           );

=head2 pause()

Wait for a keypress to continue

=cut

  sub pause() {
    print "Press any key to continue...";

    ReadMode 'cbreak';
    ReadKey(0);
    ReadMode 'normal';
    return 0;
}

=pod

=head2 mail_alert($fromname, $response)

Emails an alert to someone

=cut

  sub mail_alert {
    my $subject = shift;
    my $profile = shift;

    my $sender     = $config->{mail}->{sender};
    my $user       = $config->{mail}->{login};
    my $password   = $config->{mail}->{password};
    my $recipients = $config->{mail}->{recipients};
    my @receivers  = split ",",$recipients;

    #print "Sending to $receivers";
    my $transport = Email::Sender::Transport::SMTP->new(
                   {
                     host          => 'mail.runbox.com',
                     ssl           => 1,
                     sasl_username => $user,
                     sasl_password => $password
                    }
                                                       );

    # print "Got MimeType $mime_type for $saved_file";
    my $msg = Email::Stuffer
      ->from     ($sender   )
      ->to       (@receivers)
      ->text_body($profile  )
      ->subject  ($subject  )
      ->transport($transport)
      ;

    $msg->send;
  }

};

1;
