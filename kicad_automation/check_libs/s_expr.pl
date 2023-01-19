#!/usr/bin/perl

use strict;
use Data::SExpression;

use Data::Dumper;

my $ds = Data::SExpression->new({fold_alists => 1});

while( my $line = <>) {
    chomp $line;

    my ($sexp, $text) = $ds->read( $line);
    my ($sexp) = $ds->read( $line);

    print "---- sexp ----\n";
    print Dumper( $sexp);
    print "---- text ----\n";
    print Dumper( $text);

}
