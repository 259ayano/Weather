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
    my $map = [
	['北海道', 5],
	['青森', 12],
	['岩手', 15],
	['宮城', 8],
	['秋田', 3],
	['山形', 18],
	['福島', 22],
	['茨城', 67],
	['栃木', 32],
	['群馬', 17],
	['埼玉', 67],
	['千葉', 56],
	['東京', 50],
	['神奈川', 49],
	['新潟', 89],
	['富山', 92],
	['石川', 93],
	['福井', 90],
	['山梨', 95],
	['長野', 70],
	['岐阜', 73],
	['静岡', 50],
	['愛知', 78],
	['三重', 74],
	['滋賀', 76],
	['京都', 59],
	['大阪', 60],
	['兵庫', 49],
	['奈良', 99],
	['和歌山', 90],
	['鳥取', 63],
	['島根', 62],
	['岡山', 61],
	['広島', 79],
	['山口', 60],
	['徳島', 64],
	['香川', 64],
	['愛媛', 64],
	['高知', 62],
	['福岡', 71],
	['佐賀', 63],
	['長崎', 63],
	['熊本', 53],
	['大分', 53],
	['宮崎', 53],
	['鹿児島', 54],
	['沖縄', 53]
	];
    $c->stash->{map} = $map;
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
