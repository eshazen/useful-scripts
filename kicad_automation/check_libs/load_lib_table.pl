#!/usr/bin/perl
#
# load_lib_table.pl:  Functions to manipulate KiCAD 6 library/footprint tables
#
# ($table_name, $list) = load_lib_table( file-name)
#
# load a KiCAD symbol or footprint library table list from a file
# return a two-item list:
#    item 1:  table name (typ "sym-lib-table" or "fp-lib-table"
#    item 2:  list of hash refs, one hash per table
#             typically the keys are "name", "type", "uri", "options" and "descr"
# not much error checking, die on errors noticed
#
# $nmiss = check_files_in_table( $table)
#
# check symbol or footprint table to be sure the library files/directories exist
# return the number of missing ones and print messages
# NOTE:  KIPRJMOD, KICAD_6_SYMBOL_DIR and KICAD6_FOOTPRINT_DIR are hard-wired here
#
# $n = find_name_in_table( $name, $table)
#
# look up a library name in a table
# return the index in table if found, -1 if not found
#


use strict;
use Data::Dumper;
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
require 'sexp.pl';

my $debug = 0;

sub load_lib_table {
    my $fn = shift @_;
    my $sexp;

    my @libs;			# list of libraries, one hash ref per library

    my $fh;
    open( $fh, "<", $fn) or die "opening $fn $!";

    print "Reading $fn\n" if($debug);

    while( my $line = <$fh>) {
	chomp $line;
	$sexp .= $line;
    }
    close( $fh);
    my $s = sexpr( $sexp);

    # get the table name
    my $tbl = $s->[0]->[1];
#    print "Table name: $tbl\n";

    my $alen = scalar @{$s};
#    print "Array length = $alen\n";

    # start from 1 because the first has the table name
    for( my $i=1; $i<$alen; $i++) {
	my $ilen = scalar @{$s->[$i]};
#	print "Array item $i length: $ilen\n";

	# get array element
	my $ae = $s->[$i];
	my $alen = scalar @{$ae};
#	print "Array element $i with length $alen\n";

	# first element should be (lib
	die "malformed file" if( $ae->[0]->[1] ne "lib");

	# make a hash for this library
	my %h;
 	for( my $k=1; $k<$alen; $k++) {
	    my $sym = $ae->[$k];
	    my $name = $sym->[0]->[1];
	    my $valu = $sym->[1]->[1];
#	    print "   $name = $valu\n";
	    die "duplicate library $name" if( $h{$name});
	    $h{$name} = $valu;
	}

	printf( "LOAD:  %20s: %s\n", $h{"name"}, $h{"uri"}) if( $debug);
	push @libs, \%h;

	
    }

    # dump the list
    #    print Dumper( @libs);
    return ($tbl, \@libs);

}


#
# read a library table and check that symbol/footprints exist
#
sub check_files_in_table {
    my $tbl = shift @_;
    
    my $miss = 0;
    foreach my $lib ( @{$tbl}) {
	my $name = $lib->{"name"};
	my $uri = $lib->{"uri"};

	$uri =~ s/\$\{KIPRJMOD\}/\./;
	$uri =~ s{\$\{KICAD6_SYMBOL_DIR\}}{/usr/share/kicad/symbols};
	$uri =~ s{\$\{KICAD6_FOOTPRINT_DIR\}}{/usr/share/kicad/footprints};

	if( ! -e $uri) {
	    printf "MISSING:  %20s %s\n", $name, $uri;
	    $miss++;
	} else {
	    printf( "  FOUND:  %20s %s\n", $name, $uri) if($debug);
	}
    }
    return $miss;
}

#
# lookup a name in a library table
# return -1 if not found, index in table if found
#
sub find_name_in_table {
    my $name = shift @_;
    my $tbl = shift @_;
    my $rc = -1;

    for( my $i=0; $i < scalar @{$tbl}; $i++) {
	my $lib = $tbl->[$i];
	$rc = $i if( $lib->{"name"} eq $name);
    }

    return $rc;
}

1;
