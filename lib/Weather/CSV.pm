#! -*- mode: perl; coding: utf-8; -*-
package Weather::CSV;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
use Data::Dumper;
use FindBin;
use base qw/DBIx::Simple/;
use utf8;

sub connect {
    my $class = shift;
    my %opts = (
	f_dir => "$FindBin::Bin/../",
	f_ext => ".csv",
	f_encoding => "cp932",
	csv_eol => "\n",
	csv_sep_char => ",",
	csv_quote_char => '"',
	csv_escape_char => '"',
	csv_class => "Text::CSV_XS",
	RaiseError => 1,
	);
    my $self = $class->SUPER::connect('dbi:CSV:', undef, undef, \%opts) or carp $class->SUPER::error;
    $self;
}

sub tornado {
    my ($self, $where) = @_;
    my @hashes = $self->select('tornado','*',$where)->hashes;
    my @result = map { my $row = $_; $row } @hashes;
    wantarray ? @result : \@result;
}

sub prec {
    my ($self, $where) = @_;
    my @hashes = $self->select('prec','*',$where)->hashes;
    my @result = map { my $row = $_; $row } @hashes;
    wantarray ? @result : \@result;
}

sub block {
    my ($self, $where) = @_;
    my @hashes = $self->select('block','*',$where)->hashes;
    my @result = map { my $row = $_; $row } @hashes;
    wantarray ? @result : \@result;
}

1;
