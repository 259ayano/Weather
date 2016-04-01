#! -*- mode: perl; coding: utf-8; -*-
package Weather::Web::Controller::Tornado;
use Moose;
use namespace::autoclean;
use CGI::Expand qw/expand_hash/;
use Data::Dumper;
use Weather::CSV;
use Encode;
use utf8;
use HTML::TreeBuilder;
use List::MoreUtils;

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
	  $d ? ('date' => { like => "%$d%"  }) : ()},
	{ $h ? ('position' => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "%$d%" }) : ()},
	{ $h ? ('fscale'  => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "%$d%" }) : ()},
	);
	my $order = [ +{ -asc => [qw/date/] } ];
    my @tornado = $csv->tornado(\@where,$order);

    my $mapd;
    for (@tornado){
		my ($p,$b) = split(" ",$_->{position});
		if ($p =~ /北海道.*/){
			$p = "北海道";
		} elsif($p =~ /東京都.*/) {
			$p = "東京";
		} elsif($p =~ /京都府.*/) {
			$p = "京都";
		} elsif($p =~ /大阪府.*/) {
			$p = "大阪";
		} else {
			$p =~ s/(^.+)県$/$1/g;
		}
		push( @{$mapd->{$p}}, $_ ); 
    }
    my $map;
    for  (keys %$mapd){
		my $where = [ { name => { like => "%$_%" }} ];
		my @prec = $csv->prec($where,$order);
		my $fday = $mapd->{$_}[0]{date} =~ /.+\s.+/ ? (split(" ", $mapd->{$_}[0]{date}))[0] : $mapd->{$_}[0]{date};
		my $lday = $mapd->{$_}[-1]{date} =~ /.+\s.+/ ? (split(" ", $mapd->{$_}[-1]{date}))[0] : $mapd->{$_}[-1]{date};		
		my @type   = List::MoreUtils::uniq map { $_->{type} } @{$mapd->{$_}};
		my @fscale = List::MoreUtils::uniq map { $_->{fscale} } @{$mapd->{$_}};
		
		my $code = $_ eq "北海道" ? 0 : $prec[0]{code} ? $prec[0]{code} : 100;
		my $date   = "$fday~$lday";
		my $type   = join(",", @type);
		my $fscale = join(",", @fscale);
		my $count = $#{$mapd->{$_}} + 1;
		push (@$map, [ $code, $_, $date, $type, $fscale, $count  ]);
    } 
    $c->stash->{map} = [ sort { $a->[0] <=> $b->[0]} @$map ];
    $c->stash->{search} = $params->{search};
    $c->stash->{list} = \@tornado;
    $c->stash->{template} = 'tornado.tt';
}



sub condition :Local {
    my ( $self, $c ) = @_;
    my $csv = Weather::CSV->connect;
    my $params = expand_hash($c->req->params);
    my $search = $params->{search};
    my $h = $search->{hint};
    my $d = $search->{date} || '';

    my @where = (
	{ $h ? ('type' => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "%$d%"  }) : ()},
	{ $h ? ('position' => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "%$d%" }) : ()},
	{ $h ? ('fscale'  => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "%$d%" }) : ()},
	{ $h ? ('dead'    => $h) : (),
	  $d ? ('date' => { like => "%$d%" }) : ()},
	{ $h ? ('detail'  => { like => "%$h%" }) : (),
	  $d ? ('date' => { like => "%$d%" }) : ()},
	);
	my $order = [ +{ -desc => [qw/date/] } ];
    my @tornado = $csv->tornado(\@where,$order);

    $c->stash->{search} = $params->{search};
    $c->stash->{list} = \@tornado;
    $c->stash->{template} = 'condition.tt';
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
	warn Dumper $show;
    $c->stash->{template} = 'condition-d.tt';
}


sub info :Local {
    my ( $self, $c ) = @_;
    my $param = expand_hash($c->req->params);
    my $search = $param->{search};
    my $p = $search->{prec}  || '静岡'; 
    my $b = $search->{block}; 
    my $y = $search->{year} || '2016';
    my $m = $search->{month} || '';
    my $d = $search->{day} || '';
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

    if($param->{csv}){
	my $file = 'tenki.csv';
	my $data = &list2csv($list,$key);
	$c->stash(data => $data, current_view => 'CSV', filename => $file);
	return;
    }
    
    my $year_list  = ['',1872..2016];
    my $month_list = ['',1..12];
    my $day_list   = ['',1..31];
    $c->stash->{year_list}  = $year_list;
    $c->stash->{month_list} = $month_list;
    $c->stash->{day_list}   = $day_list;
    $c->stash->{th} = $key;
    $c->stash->{show} = $show;
    $c->stash->{search} = $search;
    $c->stash->{template} = 'info.tt';
}

sub list2csv {
    my $list = $_[0];
    my $title = $_[1];
    my $csv = [
	[ map { $_ } @$title ],
	map { my $x = $_; [ map { $x->{$_} } @$title ]; } @$list
	];
#	Data::Recursive::Encode->encode('utf-8', $csv);
    $csv;
}

__PACKAGE__->meta->make_immutable;

1;
