#!/usr/bin/perl
#
# convert Trenz text pinout
#
# input:  CSV (spreadsheet) with columns
#   PACKAGE_PIN - FPGA pin number (e.g. "P12" or "144")
#   PORT        - HDL port name "sclk" or "b(3)"
#   IOSTANDARD  - e.g. "LVCMOS18" (optional)
#
#   (other columns are ignored but added as comments)
#
use Text::CSV qw( csv );
use Data::Dumper;

my $narg = $#ARGV+1;

if( $#ARGV != 0) {
    print "Usage:  $0 <csv_file>\n";
    exit;
}

my $aoh = csv ( in => $ARGV[0], headers => "auto");

my $header = $aoh->[0];
my @cols = keys %{$header};

if( !$header->{"PACKAGE_PIN"} || !$header->{"PORT"}) {
    print "Missing PACKAGE_PIN or PORT colum\n";
    exit;
}

my @extras;

foreach my $col ( @{$cols}) {
    push @extras, $col
	if( $col ne "PACKAGE_PIN" && $col ne "PORT" && $col ne "IOSTANDARD");
}


foreach my $row ( @{$aoh}) {
    my $port = " [get_ports " .	$row->{"PORT"} . "]";
    print "set_property PACKAGE_PIN ", $row->{"PACKAGE_PIN"}, $port, "\n";
    print "IOSTANDARD ", $row->{"IOSTANDARD"}, $port, "\n"
	if( $row->{"IOSTANDARD"});
    print "#";
    foreach $extra ( @extras ) {
	print $extra, "=", $row->{$extra}, " ";
    }
    print "\n";
}

