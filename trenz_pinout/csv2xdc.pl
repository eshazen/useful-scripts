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
print "Looking for port name in column $port\n";

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
# keep track of the longest
my $extra_len = 0;
foreach my $col ( @cols) {
    if( $col ne "PACKAGE_PIN" && $col ne $port && $col ne "IOSTANDARD") {
	push @extras, $col;
	$extra_len = length($col) if( length($col) > $extra_len);
    }
}
# create a printf format
my $extra_fmt = sprintf "%%-%ds", $extra_len;
print "# format = \"$extra_fmt\"\n";


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
    # print comments with the extra columns
    print CF "\n";
    foreach $extra ( @extras ) {
	printf CF "# " . $extra_fmt . "  %s\n", 
	    $extra, $row->{$extra};
    };

    my $nport = $row->{$port};	               # port name
    my $gport = " [get_ports " . $nport . "]"; # [get_ports xxx]

    # emit the PACKAGE_PIN statement
    print CF "set_property PACKAGE_PIN ", $row->{"PACKAGE_PIN"}, $gport, "\n";
    # emit the optional IOSTANDARD statement
    print CF "set_property IOSTANDARD ", $row->{"IOSTANDARD"}, $gport, "\n"
	if( $row->{"IOSTANDARD"});

    # for VHDL, figure out the direction
    $dir = $row->{"Dir"} eq "in" || $row->{"Dir"} eq "IN" ? "in" : "out";

    print CF "set_property PULLUP true $gport\n" if( $dir eq "in");

    # see if there's a comment column as "Notes"
    my $comment = "";
    $comment = $row->{"Notes"} if( $row->{"Notes"});

    # check for subscripted name (containing "[")
    if( $nport =~ /\[/) {
	# yes, get base name and subscript
	my ($base, $subs) = $nport =~ /^(\w+)\[(\d+)\]$/;
	# keep track of low and high subscripts and direction in vectors
	if( !$vectors{$base}) {	# first time we've seen this name?
	    $vectors{$base}{low} = $subs;
	    $vectors{$base}{high} = $subs;
	    $vectors{$base}{dir} = "??";
	    $vectors{$base}{note} = $comment;
	} else {
	    $vectors{$base}{low} = $subs   if( $subs < $vectors{$base}{low});
	    $vectors{$base}{high} = $subs  if( $subs > $vectors{$base}{high});
	    $vectors{$base}{dir} = $dir;
	}
    } else {
	# simple name with no subscript, just record direction
	$scalars{$nport}{dir} = $dir;
	$scalars{$nport}{note} = $comment;
    }
}

# get total port count so we can recognized the last one
# (for that pesky VHDL last-item ';' issue)
#
my $nports = scalar(keys %vectors) + scalar(keys %scalars);
my $np = 0;

# loop over the vector ports
foreach my $nam ( sort keys %vectors) {
    my $low = $vectors{$nam}{low};
    my $high = $vectors{$nam}{high};
    my $dir = $vectors{$nam}{dir};
    my $note = $vectors{$nam}{note};
    print VF "    $nam : ", $dir, " std_logic_vector(",
	$high, " downto ", $low, ")",
	( $np == $nports-1) ? "" : ";",
	( $note eq "") ? "\n" : "  --  ", $note, "\n";
    $np++;
}

# loop over the scalar ports
foreach my $nam ( sort keys %scalars ) {
    my $note = $scalars{$nam}{note};
    print VF "    $nam : ", $scalars{$nam}{dir}, " std_logic",
	( $np == $nports-1) ? "" : ";",
	( $note eq "") ? "\n" : "  --  ", $note, "\n";
    $np++;
}

print VF qq{
)
end entity test;
};

