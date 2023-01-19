#!/usr/bin/perl
#
# cross-check symbol library use in schematic
# in KiCAD 6 designs
#
# checks for:
#   project library names duplicating (and obscuring) global names
#   library name referenced in pcb/schematic not in any library
#   multiple PCB files
#

use strict;
use open qw< :encoding(UTF-8) >;
use Data::Dumper;
# look in directory of the script for libraries
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
require 'load_lib_table.pl';

my $debug = 0;

#-------------------- subroutines --------------------
# get a value from a simple s-expression
# e.g.  (.... (name "hello") (uri "....")...)
#    getsval( expr, "name") returns "hello" (without the quotes)
sub getsval {
    my ($expr, $name) = @_;
    my ($val) = $expr =~ /\($name "([^"]+)"/;
    return $val;
}

#-------------------- code --------------------
die "HOME is not set!" if( ! $ENV{"HOME"});
my $home = $ENV{"HOME"};

# look for required files
my $local_syms_fn = "./sym-lib-table";
my $local_fps_fn = "./fp-lib-table";

my $global_syms_fn = "$home/.config/kicad/6.0/sym-lib-table";
my $global_fps_fn = "$home/.config/kicad/6.0/fp-lib-table";

my $sl;

# check for all files
die "missing $local_syms_fn" if( ! -e $local_syms_fn);
die "missing $local_fps_fn" if( ! -e $local_fps_fn);

die "missing $global_syms_fn" if( ! -e qq{$global_syms_fn});
die "missing $global_fps_fn" if( ! -e qq{$global_fps_fn});

# load the tables
my ($local_syms_tn, $local_syms) = load_lib_table( $local_syms_fn);
my ($local_fps_tn, $local_fps) = load_lib_table( $local_fps_fn);

my ($global_syms_tn, $global_syms) = load_lib_table( $global_syms_fn);
my ($global_fps_tn, $global_fps) = load_lib_table( $global_fps_fn);

print "All tables found\n";

# look for missing files in the tables
my $rc;
my $miss = 0;
$rc = check_files_in_table( $local_syms);    print "Local symbols missing: $rc\n" if($rc);
$miss += $rc;
$rc = check_files_in_table( $local_fps);    print "Local footprints missing: $rc\n" if($rc);
$miss += $rc;
$rc = check_files_in_table( $global_syms);  print "Global symbols missing: $rc\n" if($rc);
$miss += $rc;
$rc = check_files_in_table( $global_fps);  print "Global footprints missing: $rc\n" if($rc);
$miss += $rc;

if( $miss) {
    print "$miss total missing symbols/footprints\n";
} else {
    print "All symbols and footprints referenced in libraries found\n";
}

# check local library with name conflicts with global libraries
# symbols
foreach my $slib ( @{$local_syms}) {
    my $sname = $slib->{"name"};
    print "Check local $sname\n" if($debug);
    foreach my $glib ( @{$global_syms}) {
	if( $slib->{"name"} eq $glib->{"name"}) {
	    print "WARNING: symbol lib $sname also in global libraries\n";
	}
    }
}

# footprints
foreach my $slib ( @{$local_fps}) {
    my $sname = $slib->{"name"};
    print "Check local $sname\n" if($debug);
    foreach my $glib ( @{$global_fps}) {
	if( $slib->{"name"} eq $glib->{"name"}) {
	    print "WARNING: footprint lib $sname also in global libraries\n";
	}
    }
}



# now check all schematic files for symbol libraries
#
print "---> Checking schematics for symbols\n";
opendir( my $dh, ".");

my %schem_libs;
my %fp_libs;

my %pcb_names;

# read schematics, make a list of unique library names
# also read PCB design(s) and make a list of footprint library names
while( readdir $dh) {
    my $fn = $_;

    if( $fn =~ /kicad_pcb$/) {
	print "Processing ./$_\n";
	print "WARNING!  more than one PCB file\n" if( $pcb_names{$fn});
	$pcb_names{$fn}++;
	
	my $pcb;
	open( $pcb, "<", $fn) or die "opening $pcb";

 	while( my $line = <$pcb>) {
 	    chomp $line;
 	    if( $line =~ /\(footprint/) {
 		my $sname = getsval( $line, "footprint");
 		my @d = split ":", $sname;
 		my $lib = $d[0];
 		my $sym = $d[1];
		$fp_libs{$lib}++;
 	    }
 	}
	close $pcb;
    }

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

		$schem_libs{$lib}++;
 	    }
 	}
	close $sch;
    }
}

# look through unique library names and check them
foreach my $lib ( sort keys %schem_libs) {
    my $rcl = find_name_in_table( $lib, $local_syms);
    my $rcg = find_name_in_table( $lib, $global_syms);
    if( $rcl >= 0 && $rcg >= 0) { # both?
	print "WARNING:  symbol library $lib is found in both local and global library lists\n";
    }
    if( $rcl < 0 && $rcg < 0) {
	print "WARNING:  symbol library $lib is not found in either local or global library lists\n";
    }
}

print "---> Checking PCB for footprints\n";
foreach my $lib ( sort keys %fp_libs) {
    my $rcl = find_name_in_table( $lib, $local_fps);
    my $rcg = find_name_in_table( $lib, $global_fps);
    if( $rcl >= 0 && $rcg >= 0) { # both?
	print "WARNING:  footprint library $lib is found in both local and global library lists\n";
    }
    if( $rcl < 0 && $rcg < 0) {
	print "WARNING:  footprint library $lib is not found in either local or global library lists\n";
    }
}



## 
## print "\nunused local libraries:\n";
## foreach my $slib ( sort keys %simlib) {
##     if( ! $design_libs{$slib}) {
## 	print "$slib\n";
##     }
## }
## 
## print "\nGlobal? symbols.  (not in project libs):\n";
## foreach my $sym ( sort @global_syms) {
##     print "   $sym\n";
## }

