## Copyright (C) Graham Barr
## vim: ts=8:sw=2:expandtab:shiftround

package MooseX::DBIC::Scaffold::Relationship;

use Moose;

has name            => (is => 'rw');
has type            => (is => 'rw');
has accessor        => (is => 'rw');
has table           => (is => 'rw', weak_ref => 1);
has foreign_table   => (is => 'rw', weak_ref => 1);
has columns         => (is => 'rw', isa => 'ArrayRef', auto_deref => 1, default => sub { [] });
has foreign_columns => (is => 'rw', isa => 'ArrayRef', auto_deref => 1, default => sub { [] });
has attrs => (
  traits  => ['Hash'],
  is      => 'ro',
  isa     => 'HashRef[Str]',
  default => sub { {} },
  handles => {
    add_attr     => 'set',
    delete_attr  => 'delete',
    has_no_attrs => 'is_empty',
  },
);

sub BUILD {
  my ($self) = @_;
  return if $self->type;

  my @f_col    = $self->foreign_columns;
  my $f_col    = join " ", sort { $a cmp $b } map { $_->name } @f_col;
  my $f_unique = '';

  foreach my $i ($self->foreign_table->get_indices) {
    my @i_col = $i->get_columns;
    next unless @i_col == @f_col;
    next unless $f_col eq join " ", sort { $a cmp $b } map { $_->name } @i_col;
    $f_unique = 'PRIMARY', last if $i->type =~ /PRIMARY/;
    $f_unique ||= 'UNIQUE' if $i->type =~ /UNIQUE/;
  }

  if ($f_unique eq 'PRIMARY') {
    $self->type('belongs_to');
    $self->add_attr(join_type => 'left') if grep { $_->is_nullable } $self->columns;
  }
  elsif ($f_unique eq 'UNIQUE') {

    # could be has_one, but cannot know if the record *will* be there
    $self->type('might_have');
  }
  else {
    $self->type('has_many');
  }
}

1;
