package MyApp::Schema::Result::Book;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

MyApp::Schema::Result::Book

=cut

__PACKAGE__->table("book");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 rating

  data_type: 'integer'
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "rating",
  { data_type => "integer", is_nullable => 1 },
  "created",
  { data_type => "timestamp", is_nullable => 1 },
  "updated",
  { data_type => "timestamp", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 book_authors

Type: has_many

Related object: L<MyApp::Schema::Result::BookAuthor>

=cut

__PACKAGE__->has_many(
  "book_authors",
  "MyApp::Schema::Result::BookAuthor",
  { "foreign.book_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-13 15:44:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DR9ZkgZM+O3RjzJa55ieVw


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->many_to_many(authors => 'book_authors', 'author');

__PACKAGE__->add_columns(
	"created",
	{ data_type=>'timestamp',set_on_create=>1 },
	"updated",
	{ data_type=>'timestamp',set_on_create=>1, set_on_update=>1 },
);

=head2 delete_allowed_by

Can the specified user delete the current book?

=cut

sub delete_allowed_by {
	my ($self, $user) = @_;

	return $user->has_role('admin');
}

=head2 author_count
    
Return the number of authors for the current book
    
=cut
	
sub author_count {
	my($self) = @_;
	return $self->authors->count;
}

=head2 author_list

Return a comma-separated list of authors for the current book
 
=cut

sub author_list {
        my ($self) = @_;
    
        # Loop through all authors for the current book, calling all the 'full_name' 
        # Result Class method for each
        my @names;
        foreach my $author ($self->authors) {
            push(@names, $author->full_name);
        }
    
        return join(', ', @names);
    }

1;
