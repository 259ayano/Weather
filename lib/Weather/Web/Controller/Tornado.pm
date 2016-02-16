#! -*- mode: perl; coding: utf-8; -*-
package Weather::Web::Controller::Tornado;
use Moose;
use namespace::autoclean;
use CGI::Expand qw/expand_hash/;
use Data::Dumper;
use Weather::CSV;
use Encode;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $csv = Weather::CSV->connect;
    my $params = expand_hash($c->req->params);
    my $search = $params->{search};
    my $h = $search->{hint};
    my $d = $search->{date} || '';

    my @where = (
	{ $h ? ('type' => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "$d%"  }) : ()},
	{ $h ? ('position' => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('fscale'  => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('damage1' => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('damage2' => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('dead'    => $h) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('hurt1'   => $h) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('alldestroy' => $h) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('halfdestroy' => $h) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	{ $h ? ('detail'  => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "$d%" }) : ()},
	);

    my @tornado = $csv->tornado(\@where);

#    my $mapdata;
 #   for (@tornado){
#	my ($p,$b) = split(" ",$_->{position});
#	$p =~ s/(^.+)県$/$1/g;
#	push( @{$mapdata->{$p}}, $_ ); 
 #   }
  #  my $map;
   # for (keys %$mapdata){
#	push (@$map, [ $_, $#{$mapdata->{$_}} + 1 ]);
 #   } 
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
    my $year_list  = ['',1950..2016];
    my $month_list = ['',1..12];
    my $day_list   = ['',1..31];
    $c->stash->{map} = $map;
    $c->stash->{year_list}  = $year_list;
    $c->stash->{month_list} = $month_list;
    $c->stash->{day_list}   = $day_list;
    $c->stash->{search} = $params->{search};
    $c->stash->{list} = \@tornado;
    $c->stash->{template} = 'tornado.tt';
}


sub detail :Local {
    my ( $self, $c ) = @_;
    my $params  = $c->req->params;
    my @date = split(' ',$params->{date});
    my ($y,$m,$d) = split('/',$date[0]);
    
    $date[1] =~ s/(^.+)時頃$/$1/g;
    $date[1] =~ s/(^.+)頃$/$1/g;
    my $hour = $date[1] =~ /^(%d{2})$/ ? $1 : (split(":",$date[1]))[0];
    my $min  = $date[1] =~ /^(%d{2})$/ ? '' : (split(":",$date[1]))[1];

    my ($p,$b) = split(" ",$params->{position});
    $p =~ s/(^.+)県$/$1/g;
    $b =~ s/(^.+)市$/$1/g;
    my ($type,$key) = $c->gettype($y,$m,$d);

    my ($show,$list);
    my @prec   = $c->pdata($p);
	for (@prec) {
		chomp;
		my ($p_name, $p_code) = ($_->{name}, $_->{code});
		my @block = $c->bdata($p_code,$b);

		for (@block) {
			chomp;
			my ($b_name, $p_code, $b_code) = ($_->{name},$_->{pcode},$_->{code});

			# 気象庁のサイトにアクセスしてコンテンツを取得

			my $con = $c->getjma($p_code,$b_code,$y,$m,$d,$type);
			
			# HTML::TreeBuilderで解析する

			my $tree = HTML::TreeBuilder->new;
			$tree->parse($con);

			# データの部分を抽出する

			my $title;
			my @h3 = $tree->find('h3');
			next unless @h3;
			push @$title, $_->as_text for @h3;

			for my $tr ($tree->look_down('id','tablefix1')->find('tr')) {
				my $line;
				my $count = 0;
				$line->{prec}  = $p_code;
				$line->{block} = $b_code;
				for ($tr->find('td')){
					$line->{$key->[$count]} = $_->as_text;
					$count++;
				}
				push @$list, $line;
				push @{$show->{"$p_code:$p_name"}->{"$b_code:$b_name"}}, $line;
			}
		}

	}

	my $ontime = [grep { $_->{hour} == $hour if $_->{hour}} @$list];
    $c->stash->{ontime} = $ontime->[0]->{hour};
    $c->stash->{th} = $key;
    $c->stash->{show} = $show;
    $c->stash->{template} = 'tornado-detail.tt';
}

__PACKAGE__->meta->make_immutable;

1;
