#!/usr/bin/env perl

# 気象庁の管理するポジション情報を取得する

use common::sense;
use Data::Dumper;
use LWP::UserAgent;
use HTML::TreeBuilder;

my $ua  = LWP::UserAgent->new;
my $dir = './tsv';
my @precs;

`rm ./tsv/*`;

# 県のデータを取得

my $prec_url = "http://www.data.jma.go.jp/obd/stats/etrn/select/prefecture00.php?prec_no=&block_no=&year=&month=&day=&view=";

my $prec_res = $ua->get($prec_url);
my $prec_con = $prec_res->content;

for (split('\n',$prec_con)){
	next unless $_ =~ /<area shape="rect" alt="(.+)" coords="(.+)" href="prefecture\.php\?prec_no=(.+)&block_no=&year=&month=&day=&view=">/;
	my ($name,$coords,$prec_no) = ($1,$2,$3);
	
	open my $fh, '>>', "$dir/prec" or die $!;
	say $fh join(',', $name,$prec_no);
	close $fh;

	push @precs, $prec_no;
}


# 市のデータを取得

for my $p (@precs){

	my $url = "http://www.data.jma.go.jp/obd/stats/etrn/select/prefecture.php?prec_no=$p&block_no=&year=&month=&day=&view=";

	my $res = $ua->get($url);
	my $content = $res->content;

	for (split('\n',$content)){
		next unless $_ =~ /<area shape="rect" alt="(.+)" coords="(.+)" href="\.\.\/index\.php\?prec_no=(.+)&block_no=(.+)&year=&month=&day=&view="/;
		my ($name,$coords,$prec_no,$block_no) = ($1,$2,$3,$4);
		open my $fh, '>>', "$dir/block" or die $!;
		say $fh join(',', $name,$prec_no,$block_no);
		close $fh;
	}
}


# 竜巻のデータを取得
my $url = 'http://www.data.jma.go.jp/obd/stats/data/bosai/tornado';

# 年代別の事例(url1)を取得

my @years = qw /1961 1971 1981 1991 2001 2011/;
open my $fh, '>>', "$dir/tornado" or die $!;
for my $y (@years){ 
    my $url1 = "$url/list/${y}.html";
    my $res = $ua->get($url1);
    my $con = $res->decoded_content;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($con);

    for my $tr ($tree->look_down( _tag => 'tr')) {
	my $line = [ map { $_->as_text !~ /詳細/ ? $_->as_text : ()} $tr->find('td') ];
	next if ($#$line != 10);
	say $fh join(',', @$line);
    }
}
close $fh;

# 最近の事例(url2)を取得
my $url2 = "$url/new/list_new.html";

my $res2 = $ua->get($url2);
my $con2 = $res2->decoded_content;
my $tree2 = HTML::TreeBuilder->new;
$tree2->parse($con2);
open my $fh, '>>', "$dir/tornado2" or die $!;
for my $tr ($tree2->look_down('class','data2_s')->find('tr')) {
    my $line;
    push @$line, $_->as_text for ($tr->find('td'));
    next if ($#$line != 13);
    say $fh join(',', @$line);
}
close $fh;

