#!/usr/bin/perl
#
# read a KiCAD netlist
# extract nets connected to a specified ref and make a CSV list

my $conn = "J17";		# Trenz connector
my $c1 = "U9";			# CITIROC 1
my $c2 = "U17";			# CITIROC 2

while( $line = <>) {
    chomp $line;
#    print "LINE: \"$line\"\n";
    if( $line =~ /^\s*\(\w/) {
	my ($keyword,$rest) = $line =~ /^\s*\((\w+)\s(.*)$/;
	print "Keyword:  \"$keyword\" Rest: \"$rest\"\n";

    }
}
