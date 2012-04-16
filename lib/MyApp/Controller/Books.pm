package MyApp::Controller::Books;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head1 NAME

MyApp::Controller::Books - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched MyApp::Controller::Books in Books.');
}



=head2 list

Fetch all book objects and pass to books/list.tt2 in stash to be displayed

=cut

sub list :Local{
	my ($sel, $c) =	@_;
	
$DB::single=1;

	$c->stash(books => [$c->model('DB::Book')->all]);
	$c->stash(template=>'books/list.tt2');
}

=head2 url_create

Create a book with the suplied title, rating and author

=cut

sub url_create :Chained('base') :PathPart('url_create') :Args(3) {
	my ($self, $c, $title, $rating, $author_id) = @_;
	if ($c->check_user_roles('admin')) {
	    my $book = $c->model('DB::Book')->create({
		    title   => $title,
		    rating  => $rating
		});
	    $book->add_to_book_authors({author_id => $author_id});
	    $c->stash(book     => $book,
		      template => 'books/create_done.tt2');
	} else {
	    $c->response->body('Unauthorized!');
	}
}

=head2 base

Can plance common logic to start chained dispatch here

=cut

sub base :Chained('/') :PathPart('books') :CaptureArgs(0){
	my ($self, $c) = @_;
	$c -> stash(resultset=>$c->model('DB::Book'));
	$c->log->debug('***INSIDE BASE METHOD***');
}

=head2 form_create

Display form to collect information for book to create 

=cut

#sub form_create :Chained('base') :PathPart('form_create') :Args(0){#
#	my ($self, $c) = @_;
#	$c->stash(template=>'books/form_create.tt2');
#}

=head2 form_create_do

Take information from form and add to database

=cut

sub form_create_do :Chained('base') :PathPart('form_create_do') :Args(0){
	my ($self, $c) = @_;
	my $title     = $c->request->params->{title} 	 || 'N/A';
	my $rating    = $c->request->params->{rating} 	 || 'N/A';
	my $author_id = $c->request->params->{author_id} || '1';
	my $book = $c->model ('DB::Book')->create({
		title => $title,
		rating => $rating,
	});
        $book->add_to_book_authors({author_id => $author_id});
        $c->stash(book     => $book,
                  template => 'books/create_done.tt2');
}
=head2 object
    
    Fetch the specified book object based on the book ID and store
    it in the stash
    
=cut
    
sub object :Chained('base') :PathPart('id') :CaptureArgs(1) {
	my ($self, $c, $id) = @_;
	$c->stash(object => $c->stash->{resultset}->find($id));
	#   $c->detach('/error_404') if !$c->stash->{object};
	die "Book $id not found!" if !$c->stash->{object};
	# Print a message to the debug log
	$c->log->debug("*** INSIDE OBJECT METHOD for obj id=$id ***");
}
=head2 delete

Delete a book

=cut

sub delete :Chained('object') :PathPart('delete') :Args(0) {
	my ($self, $c) = @_;
	$c->detach('/error_noperms')
		unless $c->stash->{object}->delete_allowed_by($c->user->get_object);
	$c->stash->{object}->delete;
	$c->flash->{status_msg} = "Book deleted.";
	$c->response->redirect($c->uri_for($self->action_for('list')));
}

=head2 list_recent
    
List recently created books
    
=cut
    
sub list_recent :Chained('base') :PathPart('list_recent') :Args(1) {
	my ($self, $c, $mins) = @_;
	$c->stash(books => [$c->model('DB::Book')
				 ->created_after(DateTime->now->subtract(minutes => $mins))]);
	$c->stash(template => 'books/list.tt2');
}

=head2 list_recent_tcp

List recently created books

=cut

sub list_recent_tcp :Chained('base') :PathPart('list_recent_tcp') :Args(1) {
	my ($self, $c, $mins) = @_;
	$c->stash(books => [$c->model('DB::Book')
		->created_after(DateTime->now->subtract(minutes => $mins))
		->title_like('TCP')
			]);
	$c->stash(template => 'books/list.tt2');
}

=head1 AUTHOR

Alexander Ibarra

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 form_create
    
Use HTML::form to create a new book

=cut

sub form_create :Chained('base') :PathPart('form_create') :Args(0) :FormConfig {
		my ($self, $c) = @_;

		my $form = $c->stash->{form};
		if ($form->submitted_and_valid) {
				my $book = $c->model('DB::Book')->new_result({});
				$form->model->update($book);
				$c->flash->{status_msg} = 'Book created';
				$c->response->redirect($c->uri_for($self->action_for('form_create_do')));
				$c->detach;
		} else {
				my @author_objs = $c->model("DB::Author")->all();
				my @authors;
				foreach (sort {$a->last_name cmp $b->last_name} @author_objs) {
						push(@authors, [$_->id, $_->last_name]);
				}
				my $select = $form->get_element({type => 'Select'});
				$select->options(\@authors);
		}
		$c->stash(template => 'books/form_create.tt2');
}

=head2 form_edit

Use HTML::form to update an existing book

=cut

sub form_edit :Chained('object') :PathPart('form_edit') :Args(0)
        :FormConfig('books/form_create.yml'){
	my ($self, $c) = @_;
	my $book = $c->stash->{object};
	unless($book){
		$c->flash->{error_msg} = "Invalid book -- Cannot edit";
		$c->response->redirect($c->uri_for($c->action_for('list')));
		$c->detach;
	}
	my $form = $c->stash->{form};
	if ($form->submitted_and_valid){
		 $form->model->update($book);
		 $c->flash->{status_msg} = 'Book edited';
		 $c->response->redirect($c->uri_for($self->action_for('list')));
		 $c->detach;
	} else {
		 my @author_objs = $c->model("DB::Author")->all();
		 my @authors;
		 foreach (sort {$a->last_name cmp $b->last_name} @author_objs) {
				 push(@authors, [$_->id, $_->last_name]);
		 }
		 my $select = $form->get_element({type => 'Select'});
		 $select->options(\@authors);
		 $form->model->default_values($book);
	}
	$c->stash(template => 'books/form_create.tt2');
}


__PACKAGE__->meta->make_immutable;
1;
