package Web::Starch::Plugin::Bundle;

=head1 NAME

Web::Starch::Plugin::Bundle - Base role for Web::Starch plugin bundles.

=head1 SYNOPSIS

    # Create a bundle.
    package MyDevPlugins;
    use Moo;
    with 'Web::Starch::Plugin::Bundle';
    sub bundled_plugins {
        return ['::Trace', 'MyApp::Starch::CustomPLugin'];
    }

    # Use the bundle.
    my $starch = Web::Starch->new_with_plugins(
        ['MyDevPlugin'],
        store => { ... },
        ...,
    );

=head1 DESCRIPTION

Plugin bundles package together any number of other plugins and plugin
bundles.  To create a plugin bundle just make a new class that consumes
this role and defines the C<bundled_plugins> method.  This method
should return an array ref of plugin names (absolute or relative).

See L<Web::Starch::Manual::Extending/PLUGINS> for more information
on writing plugins.

=cut

use Types::Standard -types;
use Types::Common::String -types;
use Web::Starch::Util qw( load_prefixed_module );

use Moo::Role;
use strictures 2;
use namespace::clean;

requires( 'bundled_plugins' );

sub _roles_for {
    my ($self, $prefix) = @_;

    my $for_role = "Web::Starch::Plugin::For$prefix";

    my @roles;
    foreach my $role (@{ $self->roles() }) {
        next if !Moo::Role::does_role( $role, $for_role );
        push @roles, $role;
    }

    return \@roles;
}

=head1 ATTRIBUTES

=head2 plugins

This returns the array ref of plugins provided by the
C<bundled_plugins> method.

=cut

has plugins => (
    is       => 'lazy',
    isa      => ArrayRef[ Str ],
    init_arg => undef,
    builder  => 'bundled_plugins',
);

=head2 resolved_plugins

This returns L</plugins> with all relative plugin names made
absolute.

=cut

has resolved_plugins => (
    is       => 'lazy',
    isa      => ArrayRef[ NonEmptySimpleStr ],
    init_arg => undef,
);
sub _build_resolved_plugins {
    my ($self) = @_;

    my @plugins;
    foreach my $plugin (@{ $self->plugins() }) {
        push @plugins, load_prefixed_module(
            'Web::Starch::Plugin',
            $plugin,
        );
    }

    return \@plugins;
}

=head2 roles

Returns L</resolved_plugins> with all plugin bundles expanded to
their roles.

=cut

has roles => (
    is       => 'lazy',
    isa      => ArrayRef[ NonEmptySimpleStr ],
    init_arg => undef,
);
sub _build_roles {
    my ($self) = @_;

    my @roles;

    foreach my $plugin (@{ $self->resolved_plugins() }) {
        if (Moo::Role::does_role( $plugin, 'Web::Starch::Plugin::Bundle')) {
            die "Plugin bundle $plugin is not a class"
                if !$plugin->can('new');

            my $bundle = $plugin->new();
            push @roles, @{ $bundle->roles() };
        }
        else {
            die "Plugin $plugin does not look like a role"
                if $plugin->can('new');

            push @roles, $plugin;
        }
    }

    return \@roles;
}

=head2 manager_roles

Of the L</roles> this returns the ones that consume the
L<Web::Starch::Plugin::ForManager> role.

=cut

has manager_roles => (
    is       => 'lazy',
    isa      => ArrayRef[ NonEmptySimpleStr ],
    init_arg => undef,
);
sub _build_manager_roles {
    my ($self) = @_;

    return $self->_roles_for('Manager');
}

=head2 session_roles

Of the L</roles> this returns the ones that consume the
L<Web::Starch::Plugin::ForSession> role.

=cut

has session_roles => (
    is       => 'lazy',
    isa      => ArrayRef[ NonEmptySimpleStr ],
    init_arg => undef,
);
sub _build_session_roles {
    my ($self) = @_;

    return $self->_roles_for('Session');
}

=head2 store_roles

Of the L</roles> this returns the ones that consume the
L<Web::Starch::Plugin::ForStore> role.

=cut

has store_roles => (
    is       => 'lazy',
    isa      => ArrayRef[ NonEmptySimpleStr ],
    init_arg => undef,
);
sub _build_store_roles {
    my ($self) = @_;

    return $self->_roles_for('Store');
}

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

