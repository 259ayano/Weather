#! -*- mode: perl; coding: utf-8; -*-
package Weather::Web::Controller::Map;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Weather::Web::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    warn Dumper "aaaaaa";
    $c->stash->{template} = 'map.tt';
}



=encoding utf8

=head1 AUTHOR

HIRAYAMA Ayano

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
