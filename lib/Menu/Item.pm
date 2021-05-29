package Menu::Item {
#########################################################
# Item.pm
#########################################################

  # Always use these
  use strict;
  use warnings;
  use Exporter;

  # Menu::Item constructor
  sub new {

    # Unpack input arguments
    my ($class, $name, $action) = @_;

    # Bless the Menu::Item object
    my $self = bless {
        _name   => $name,
        _action => $action,
        _active => 1,
    }, $class;

    return $self;
  }

  # Name accessor method
  sub name {
    my ($self, $name) = @_;
    $self->{_name} = $name if defined $name;
    return $self->{_name};
  }

  # Action accessor method
  sub action {
    my ($self, $action) = @_;
    $self->{_action} = $action if defined $action;
    return $self->{_action};
  }

# Active accessor method
  sub active {
    my ($self, $active) = @_;
    $self->{_active} = $active if defined $active;
    return $self->{_active};
  }
}

1;
