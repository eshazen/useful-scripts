#!/usr/bin/perl
#
# convert Trenz text pinout to Vivado constraint file
#
# input:  CSV (spreadsheet) with columns
#   PACKAGE_PIN - FPGA pin number (e.g. "P12" or "144")
#   PORT        - HDL port name "sclk" or "b(3)"
#   IOSTANDARD  - e.g. "LVCMOS18"
#
# output:
#   Xilinx constraint file
#   VHDL prototype entity
#
# usage:  csv2xdc.pl <csv> <portname> <constr> <vhdl>
#   <csv>      is CSV input file name
#   <portname> is name of column specifying the VHDL port name to use
#   <constr>   is the output file name for the Xilinx constraints
#   <vhdl>     is the output file name for the VHDL entity
#

use Text::CSV qw( csv );
use Data::Dumper;

die "Usage:  $0 <csv_file> <port_column> <constraint_file> <vhdl_file>\n" if( $#ARGV != 3);

my $port = $ARGV[1];  # get VHDL port column name

# open the output files
open CF, "> $ARGV[2]" or die "opening $ARGV[2] for output";
open VF, "> $ARGV[3]" or die "opening $ARGV[3] for output";

# read entire CSV file and return an array of hashes
my $aoh = csv ( in => $ARGV[0], headers => "auto");

# get the list of columns from the first row
my $header = $aoh->[0];		# first row as a hash
my @cols = keys %{$header};	# extract the keys (column names)

# be sure required columns exist
if( !$header->{"PACKAGE_PIN"} || !$header->{$port}) {
    print "Missing PACKAGE_PIN or PORT colum\n";
    exit;
}

my @extras;  # array to store "extra" column names

# make a list of "extra" column names
foreach my $col ( @cols) {
    push @extras, $col 
	if( $col ne "PACKAGE_PIN" && $col ne $port && $col ne "IOSTANDARD");
}

# start the VHDL entity
print VF qq{entity test is

  port (
};

# hashes to store information about ports.  Both have "dir" for direction in/out
# vectors have in addition (low,high) for subscript range
my %scalars;			# scalar ports
my %vectors;			# vector ports

# loop over each row in the file
foreach my $row ( @{$aoh}) {
    # print a comment with the extra columns
    print CF "\n# ";
    foreach $extra ( @extras ) {
	print CF $extra, "=", $row->{$extra}," ";
    };
    print CF "\n";

    my $nport = $row->{$port};	               # port name
    my $gport = " [get_ports " . $gport . "]"; # [get_ports xxx]

    # emit the PACKAGE_PIN statement
    print CF "set_property PACKAGE_PIN ", $row->{"PACKAGE_PIN"}, $gport, "\n";
    # emit the optional IOSTANDARD statement
    print CF "set_property IOSTANDARD ", $row->{"IOSTANDARD"}, $gport, "\n"
	if( $row->{"IOSTANDARD"});

    # for VHDL, figure out the direction
    $dir = $row->{"Dir"} eq "in" || $row->{"Dir"} eq "IN" ? "in" : "out";

    # check for subscripted name (containing "[")
    if( $nport =~ /\[/) {
	# yes, get base name and subscript
	my ($base, $subs) = $nport =~ /^(\w+)\[(\d+)\]$/;
	# keep track of low and high subscripts and direction in vectors
	if( !$vectors{$base}) {	# first time we've seen this name?
	    $vectors{$base}{low} = $subs;
	    $vectors{$base}{high} = $subs;
	    $vectors{$base}{dir} = "??";
	} else {
	    $vectors{$base}{low} = $subs   if( $subs < $vectors{$base}{low});
	    $vectors{$base}{high} = $subs  if( $subs > $vectors{$base}{high});
	    $vectors{$base}{dir} = $dir;
	}
    } else {
	# simple name with no subscript, just record direction
	$scalars{$nport}{dir} = $dir;
    }
}

# get total port count so we can recognized the last one
# (for that pesky VHDL last-item ';' issue)
#
my $nports = scalar(keys %vectors) + scalar(keys %scalars);
my $np = 0;

# loop over the scalar ports
foreach my $nam ( keys %scalars ) {
    print VF "    $nam : ", $scalars{$nam}{dir}, " std_logic",
	( $np == $nports-1) ? "\n" : ";\n";   # handle last-item ;
    $np++;
}

# loop over the vector ports
foreach my $nam ( keys %vectors) {
    my $low = $vectors{$nam}{low};
    my $high = $vectors{$nam}{high};
    my $dir = $vectors{$nam}{dir};
    print VF "    $nam : ", $dir, " std_logic_vector(",
	$high, " downto ", $low, ")",
	( $np == $nports-1) ? "\n" : ";\n"; # last-item ;
    $np++;
}

print VF qq{

end entity test;
};

