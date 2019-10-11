#!/usr/bin/perl

use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);

sub is_comment {
    my $line = shift;
    if ($line =~ /^#/) {
	return 1;
    }
    return 0;
}

# List of research ids that will not be put in the study.
my %laureates_out;
sub load_laureates_out {
    open(IN, "laureates_out.dat");
    while(<IN>) {
	chomp;
	if (is_comment($_)) {
	    next;
	}
	$laureates_out{$_} = 1;
    }
    close(IN);
}

&load_laureates_out();
open(IN, "authors.idx");
open(OUT, ">md5.idx");
open(IDS, ">ids.idx");
while(<IN>) {
    chomp;
    if (is_comment($_)) {
	next;
    }
    my @fields = split /\;/;
    my $researchid = $fields[0];

    if (exists $laureates_out{$researchid}) {
	next;
    }

    my $id = $fields[0].";".$fields[1];
    my $rest = $fields[3].";".$fields[4].";".$fields[5];
    my $md5 = md5_hex($id);
    print OUT $md5.";".$id.";".$fields[2]."\n";
    print IDS $md5.";".$rest."\n";

    `cp -v data.0/$researchid.tsv data/$md5.tsv`;
}
close(IN);
