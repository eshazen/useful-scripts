#!/usr/bin/perl

use strict;
use Data::Dumper;
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
require 'load_lib_table.pl';

my ($table, $libs) = load_lib_table( $ARGV[0]);

print "Table: $table\n";

