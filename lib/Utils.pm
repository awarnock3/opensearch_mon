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
  use File::Basename;
  use Net::SMTP 3.0;
  use Email::Sender::Transport::SMTP;
  use Email::Stuffer;
  use MIME::Types;
  use Authen::SASL qw(Perl);

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
    my $config  = shift;

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
