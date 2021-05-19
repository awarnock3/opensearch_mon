#########################################################
# These are packages to generate the menus. There are
# two of them - Menu and Menu::Item. Keep them together
# here in case we send the program to someone to use
#########################################################

#########################################################
# Item.pm
#########################################################
package Menu::Item {

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

#########################################################
# Menu.pm
# From https://stackoverflow.com/questions/25438475/how-can-i-build-a-simple-menu-in-perl
#########################################################
package Menu {

  # Always use these
  use strict;
  use warnings;

  # Other use statements
  use Carp;
  use Exporter;

#  use Menu::Item;
  import Menu::Item;

  # Menu constructor
  sub new {

    # Unpack input arguments
    my ($class, $title) = @_;

    # Define a default title
    if (!defined $title) {
        $title = 'MENU';
    }

    # Bless the Menu object
    my $self = bless {
        _title => $title,
        _items => [],
        _exit  => 0,
    }, $class;

    return $self;
  }

  # Title accessor method
  sub title {
    my ($self, $title) = @_;
    $self->{_title} = $title if defined $title;
    return $self->{_title};
  }

  # Items accessor method
  sub items {
    my ($self, $items) = @_;
    $self->{_items} = $items if defined $items;
    return $self->{_items};
  }

  # Exit accessor method
  sub exit {
    my ($self, $exit) = @_;
    $self->{_exit} = $exit if defined $exit;
    return $self->{_exit};
  }

  # Add item(s) to the menu
  sub add {

    # Unpack input arguments
    my ($self, @add) = @_;
    croak 'add() requires name-action pairs' unless @add % 2 == 0;

    # Add new items
    while (@add) {
        my ($name, $action) = splice @add, 0, 2;

        # If the item already exists, remove it
        for my $index(0 .. $#{$self->{_items}}) {
            if ($name eq $self->{_items}->[$index]->name()) {
                splice @{$self->{_items}}, $index, 1;
            }
        }

        # Add the item to the end of the menu
        my $item = Menu::Item->new($name, $action);
        push @{$self->{_items}}, $item;
    }

    return 0;
}

  # Remove item(s) from the menu
  sub remove {

    # Unpack input arguments
    my ($self, @remove) = @_;

    # Remove items
    for my $name(@remove) {

        # If the item exists, remove it
        for my $index(0 .. $#{$self->{_items}}) {
            if ($name eq $self->{_items}->[$index]->name()) {
                splice @{$self->{_items}}, $index, 1;
            }
        }
    }

    return 0;
  }

  # Disable item(s)
  sub disable {

    # Unpack input arguments
    my ($self, @disable) = @_;

    # Disable items
    for my $name(@disable) {

        # If the item exists, disable it
        for my $index(0 .. $#{$self->{_items}}) {
            if ($name eq $self->{_items}->[$index]->name()) {
                $self->{_items}->[$index]->active(0);
            }
        }
    }

    return 0;
  }

  # Enable item(s)
  sub enable {

    # Unpack input arguments
    my ($self, @enable) = @_;

    # Disable items
    for my $name(@enable) {

        # If the item exists, enable it
        for my $index(0 .. $#{$self->{_items}}) {
            if ($name eq $self->{_items}->[$index]->name()) {
                $self->{_items}->[$index]->active(1);
            }
        }
    }
  }

  # Print the menu
  sub print {

    # Unpack input arguments
    my ($self) = @_;

    # Print the menu
    for (;;) {
        system 'clear';

        # Print the title
        print "========================================\n";
        print "    $self->{_title}\n";
        print "========================================\n";

        # Print menu items
        for my $index(0 .. $#{$self->{_items}}) {
            my $name   = $self->{_items}->[$index]->name();
            my $active = $self->{_items}->[$index]->active();
            if ($active) {
                printf "%2d. %s\n", $index + 1, $name;
            } else {
                print "\n";
            }
        }
        printf "%2d. %s\n", 0, 'Exit' if $self->{_exit};

        # Get user input
#        print "\n?: ";
        print "\nEnter selection: ";
        chomp (my $input = <STDIN>);
        return 0 if $input =~ /^$/;

        # Process user input
        if ($input =~ m/^\d+$/ && $input > 0 && $input <= scalar @{$self->{_items}}) {
            my $action = $self->{_items}->[$input - 1]->action();
            my $active = $self->{_items}->[$input - 1]->active();
            if ($active) {
                print "\n";
                return $action->();
            }
        } elsif ($input =~ m/^\d+$/ && $input == 0 && $self->{_exit}) {
          CORE::exit 0;
        }

        # Deal with invalid input
        print "\nInvalid input.\n\n";
        system 'pause';
    }
  }
}

1;
