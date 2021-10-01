#!/usr/bin/perl
#
# convert Trenz text pinout to Vivado constraint file
#
# input:  CSV (spreadsheet) with columns
#   PACKAGE_PIN - FPGA pin number (e.g. "P12" or "144")
#   PORT        - HDL port name "sclk" or "b(3)"
#   IOSTANDARD  - e.g. "LVCMOS18"
#
#   (other columns are ignored but added as comments)
#
use Text::CSV qw( csv );
use Data::Dumper;

die "Usage:  $0 <csv_file>\n" if( $#ARGV != 0);

# read entire CSV file and return an array of hashes
my $aoh = csv ( in => $ARGV[0], headers => "auto");

# get the list of columns from the first row
my $header = $aoh->[0];		# first row as a hash
my @cols = keys %{$header};	# extract the keys (column names)

# be sure required columns exist
if( !$header->{"PACKAGE_PIN"} || !$header->{"PORT"}) {
    print "Missing PACKAGE_PIN or PORT colum\n";
    exit;
}

# array to store "extra" column names
my @extras;

# make a list of "extra" column names
foreach my $col ( @cols) {
    push @extras, $col 
	if( $col ne "PACKAGE_PIN" && $col ne "PORT" && $col ne "IOSTANDARD");
}


# loop over each row in the file
foreach my $row ( @{$aoh}) {
    # print a comment with the extra columns
    print "\n# ";
    foreach $extra ( @extras ) {
	print $extra, "=", $row->{$extra}," ";
    };
    print "\n";

    # create the [get_ports xxx] clause
    my $port = " [get_ports " .	$row->{"PORT"} . "]";
    # emit the PACKAGE_PIN statement
    print "set_property PACKAGE_PIN ", $row->{"PACKAGE_PIN"}, $port, "\n";
    # emit the optional IOSTANDARD statement
    print "set_property IOSTANDARD ", $row->{"IOSTANDARD"}, $port, "\n"
	if( $row->{"IOSTANDARD"});
}

