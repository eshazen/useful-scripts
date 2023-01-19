#!/usr/bin/perl
#
# cross-check symbol library use in schematic
# in KiCAD 6 designs
#
use strict;
use open qw< :encoding(UTF-8) >;
use Data::Dumper;
# look in directory of the script for libraries
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
require 'load_lib_table.pl';


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
my ($global_syms_fn, $global_syms) = load_lib_table( $global_syms_fn);
my ($global_fps_tn, $global_fps) = load_lib_table( $global_fps_fn);

print "All tables found\n";

# look for missing files in the tables
print "checking...\n";
my $rc;
my $miss = 0;
$rc = check_files_in_table( $local_syms);    print "Local symbols missing: $rc\n";
$rc = check_files_in_table( $local_fps);    print "Local footprints missing: $rc\n";
$rc = check_files_in_table( $global_syms);  print "Global symbols missing: $rc\n";
$rc = check_files_in_table( $global_syms);  print "Global footprints missing: $rc\n";

print "$rc total missing files\n";

## print "Checking sym-lib-table:\n";
## while( my $line = <$sl>) {
##     if( $line =~ /\(lib/) {
## 	chomp $line;
## 	my $name = getsval( $line, "name");
## 	my $type = getsval( $line, "type");
## 	my $uri = getsval( $line, "uri");
## 	$uri =~ s/\$\{KIPRJMOD\}/\./;
## 	if( ! -f $uri) {
## 	    print "MISSING: name=$name type=$type uri=$uri\n";
## 	    $simlib{$name} = [ $type, $uri, "MISSING" ];
## 	} else {
## 	    print "  FOUND: name=$name type=$type uri=$uri\n";
## 	    $simlib{$name} = [ $type, $uri, "FOUND" ];
## 	}
##     }
## }
## print "\n";

## # now check all schematic files for symbol libraries
## #
## print "Checking schematics for symbols\n";
## opendir( my $dh, ".");
## 
## my %design_libs;
## my @global_syms;
## 
## while( readdir $dh) {
##     my $fn = $_;
##     if( $fn =~ /kicad_sch$/) {
## 	print "Processing ./$_\n";
## 	my $sch;
## 	open( $sch, "<", $fn) or die "opening $fn";
## 
## 	while( my $line = <$sch>) {
## 	    chomp $line;
## 	    if( $line =~ /lib_id/) {
## 		my $sname = getsval( $line, "lib_id");
## 		my @d = split ":", $sname;
## 		my $lib = $d[0];
## 		my $sym = $d[1];
## 		if( $simlib{$lib}) {
## 		    $design_libs{$lib}++;
## 		} else {
## 		    push @global_syms, $sname;
## 		}
## 	    }
## 	}
## 	close $sch;
##     }
## }
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

