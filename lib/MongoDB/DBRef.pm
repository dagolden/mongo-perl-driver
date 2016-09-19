#
#  Copyright 2009-2013 MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

package MongoDB::DBRef;

# ABSTRACT: A MongoDB database reference

use version;
our $VERSION = 'v1.5.1';

use Tie::IxHash;
use Moo;
use MongoDB::_Types qw(
    DBRefColl
    DBRefDB
);
use Types::Standard qw(
    HashRef
    Maybe
);
use namespace::clean -except => 'meta';

=attr id

Required. The C<_id> value of the referenced document. If the
C<_id> is an ObjectID, then you must use a L<MongoDB::OID> object.

This may also be specified in the constructor as C<'$id'>.

=cut

# no type constraint since an _id can be anything
has id => (
    is        => 'ro',
    required  => 1
);

=attr ref

Required. The collection in which the referenced document lives. Either a
L<MongoDB::Collection> object or a string containing the collection name. The
object will be coerced to string form.

This may also be specified in the constructor as C<'$ref'>.

=cut

has ref => (
    is        => 'ro',
    isa       => DBRefColl,
    required  => 1,
    coerce    => DBRefColl->coercion,
);

=attr db

Optional. The database in which the referenced document lives. Either a
L<MongoDB::Database> object or a string containing the database name. The
object will be coerced to string form.

Not all other language drivers support the C<$db> field, so using this
field is not recommended.

This may also be specified in the constructor as C<'$db'>.

=cut

has db => (
    is        => 'ro',
    isa       => Maybe[DBRefDB],
    coerce    => Maybe([DBRefDB])->coercion,
);

=attr extra

Optional.  A hash reference of additional fields in the DBRef document.
Not all MongoDB drivers support this feature and you B<should not> rely on
it.  This attribute exists solely to ensure DBRefs generated by drivers that
do allow extra fields will round-trip correctly.

B<USE OF THIS FIELD FOR NEW DBREFS IS NOT RECOMMENDED.>

=cut

has extra => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $hr    = $class->$orig(@_);
    return {
        id => (
              exists( $hr->{'$id'} ) ? delete $hr->{'$id'}
            : exists( $hr->{id} )    ? delete $hr->{id}
            :                          undef
        ),
        ref => (
              exists( $hr->{'$ref'} ) ? delete $hr->{'$ref'}
            : exists( $hr->{ref} )    ? delete $hr->{ref}
            :                           undef
        ),
        db => (
              exists( $hr->{'$db'} ) ? delete $hr->{'$db'}
            : exists( $hr->{db} )    ? delete $hr->{db}
            :                          undef
        ),
        extra => $hr,
    };
};

sub _ordered {
    my $self = shift;

    return Tie::IxHash->new(
        '$ref' => $self->ref,
        '$id'  => $self->id,
        ( defined($self->db) ? ( '$db' => $self->db ) : () ),
        %{ $self->extra },
    );
}


1;

__END__

=head1 SYNOPSIS

    my $dbref = MongoDB::DBRef->new(
        ref => 'my_collection',
        id => 123
    );

    $coll->insert( { foo => 'bar', other_doc => $dbref } );

=head1 DESCRIPTION

This module provides support for database references (DBRefs) in the Perl
MongoDB driver. A DBRef is a special embedded document which points to
another document in the database. DBRefs are not the same as foreign keys
and do not provide any referential integrity or constraint checking. For example,
a DBRef may point to a document that no longer exists (or never existed.)

Generally, these are not recommended and "manual references" are preferred.

See L<Database references|http://docs.mongodb.org/manual/reference/database-references/>
en the MongoDB manual for more information.

=cut

# vim: set ts=4 sts=4 sw=4 et tw=75:
