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
use Text::CSV qw( csv );
use Data::Dumper;

die "Usage:  $0 <csv_file> <port_column> <constraint_file> <vhdl_file>\n" if( $#ARGV != 3);

my $port = $ARGV[1];

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

# array to store "extra" column names
my @extras;

# make a list of "extra" column names
foreach my $col ( @cols) {
    push @extras, $col 
	if( $col ne "PACKAGE_PIN" && $col ne $port && $col ne "IOSTANDARD");
}

# start the VHDL entity
print VF qq{entity test is

  port (
};

my @names;
my %range;
my %dirs;

# loop over each row in the file
print "Processing $nrows rows\n";
foreach my $row ( @{$aoh}) {
    # print a comment with the extra columns
    print CF "\n# ";
    foreach $extra ( @extras ) {
	print CF $extra, "=", $row->{$extra}," ";
    };
    print CF "\n";

    # create the [get_ports xxx] clause
    my $nport = $row->{$port};
    my $gport = " [get_ports " . $gport . "]";

    # emit the PACKAGE_PIN statement
    print CF "set_property PACKAGE_PIN ", $row->{"PACKAGE_PIN"}, $gport, "\n";
    # emit the optional IOSTANDARD statement
    print CF "set_property IOSTANDARD ", $row->{"IOSTANDARD"}, $gport, "\n"
	if( $row->{"IOSTANDARD"});

    $dir = $row->{"Dir"} eq "in" || $row->{"Dir"} eq "IN" ? "in" : "out";

    # collect the ports for later output
    # check for a subscript
    if( $nport =~ /\[/) {
	# yes, get base name and subscript
	my ($base, $subs) = $nport =~ /^(\w+)\[(\d+)\]$/;
	# keep track of low and high subscripts and direction in range
	if( !$range{$base}) {	# first time we've seen this name?
	    $range{$base}{low} = $subs;
	    $range{$base}{high} = $subs;
	    $range{$base}{dir} = "??";
	} else {
	    $range{$base}{low} = $subs
		if( $subs < $range{$base}{low});
	    $range{$base}{high} = $subs
		if( $subs > $range{$base}{high});
	    $range{$base}{dir} = $dir;
	}
    } else {
	# simple name with no subscript, keep in a separate list
	push @names, $nport;
	$dirs{$nport} = $dir;
    }
}

# get total port count so we can recognized the last one
# (for that pesky VHDL last-item ';' issue)
my $nports = scalar(keys %range) + $#names + 1;
my $np = 0;

foreach my $nam ( @names ) {
    print VF "    $nam : ", $dirs{$nam}, " std_logic",
	( $np == $nports-1) ? "\n" : ";\n";   # handle last-item ;
    $np++;
}

foreach my $nam ( keys %range) {
    my $low = $range{$nam}{low};
    my $high = $range{$nam}{high};
    my $dir = $range{$nam}{dir};
    print VF "    $nam : ", $dir, " std_logic_vector(",
	$high, " downto ", $low, ")",
	( $np == $nports-1) ? "\n" : ";\n"; # last-item ;
    $np++;
}

print VF qq{

end entity test;
};

