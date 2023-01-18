#!/usr/bin/perl
#
# cross-check symbol library use in schematic
# in KiCAD 6 designs
#
use strict;
use open qw< :encoding(UTF-8) >;
my $sl;

open( $sl, "<", "sym-lib-table") or die "opening sym_lib_table", ;

sub getsval {
    my ($expr, $name) = @_;
    my ($val) = $expr =~ /\($name "([^"]+)"/;
    return $val;
}

# check for symbol libraries in sym-lib-table existing
# and make a list
my %simlib;

print "Checking sym-lib-table:\n";
while( my $line = <$sl>) {
    if( $line =~ /\(lib/) {
	chomp $line;
	my $name = getsval( $line, "name");
	my $type = getsval( $line, "type");
	my $uri = getsval( $line, "uri");
	$uri =~ s/\$\{KIPRJMOD\}/\./;
	if( ! -f $uri) {
	    print "MISSING: name=$name type=$type uri=$uri\n";
	    $simlib{$name} = [ $type, $uri, "MISSING" ];
	} else {
	    print "  FOUND: name=$name type=$type uri=$uri\n";
	    $simlib{$name} = [ $type, $uri, "FOUND" ];
	}
    }
}
close $sl;
print "\n";

# now check all schematic files for symbol libraries
#
print "Checking schematics for symbols\n";
opendir( my $dh, ".");

my %design_libs;
my @global_syms;

while( readdir $dh) {
    my $fn = $_;
    if( $fn =~ /kicad_sch$/) {
	print "Processing ./$_\n";
	my $sch;
	open( $sch, "<", $fn) or die "opening $fn";

	while( my $line = <$sch>) {
	    chomp $line;
	    if( $line =~ /lib_id/) {
		my $sname = getsval( $line, "lib_id");
		my @d = split ":", $sname;
		my $lib = $d[0];
		my $sym = $d[1];
		if( $simlib{$lib}) {
		    $design_libs{$lib}++;
		} else {
		    push @global_syms, $sname;
		}
	    }
	}
	close $sch;
    }
}

print "\nunused local libraries:\n";
foreach my $slib ( sort keys %simlib) {
    if( ! $design_libs{$slib}) {
	print "$slib\n";
    }
}

print "\nGlobal? symbols.  (not in project libs):\n";
foreach my $sym ( sort @global_syms) {
    print "   $sym\n";
}

