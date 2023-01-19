#!/usr/bin/perl
use strict;
use Data::Dumper;
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;

require 'sexp.pl';

my $sexp;

while( my $line = <>) {
    chomp $line;
    $sexp .= $line;
}

my $s = sexpr( $sexp);

print Dumper( $s);
