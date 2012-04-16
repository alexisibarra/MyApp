package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

MyApp::Controller::Root - Root Controller for MyApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head2 auto

Check if there is a user and, if not, forward to login page
=cut

=head2 auto
    Check if there is a user and, if not, forward to login page
=cut

    # Note that 'auto' runs after 'begin' but before your actions and that
    # 'auto's "chain" (all from application path to most specific class are run)
    # See the 'Actions' section of 'Catalyst::Manual::Intro' for more info.

sub auto :Private {
	my ($self, $c) = @_;
	if ($c->controller eq $c->controller('Login')) {
	    return 1;
	}
	if (!$c->user_exists) {
	    $c->log->debug('***Root::auto User not found, forwarding to /login');
	    $c->response->redirect($c->uri_for('/login'));
	    return 0;
	}
	return 1;
}

sub error_noperms :Chained('/') :PathPart('error_noperms') :Args(0){
	my ($self, $c) = @_;

	$c -> stash(template => 'error_noperms.tt2');
}
=head1 AUTHOR

Alexander Ibarra

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
