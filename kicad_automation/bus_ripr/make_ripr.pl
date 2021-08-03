#!/usr/bin/perl
#
# write a KiCAD EESchema file with a set of buss rippers
# known to work only for "EESchema Schematic File Version 4" files
# (KiCAD 5.1.x)
#
# Usage: <signal> <start> <count> [<incr> {UP|DOWN}]
#    <signal> = signal name prefix
#    <start> = integer starting number
#    <count> = positive count
#    <incr>  = number increment (may be negative)
#    UP|DOWN = specify ripper direction.  Default = DOWN
#


use strict;

my $grid = 50;
my $step = 100;
my $x0 = 1500;
my $y0 = 1500;

my $wire_len = 5 * $step;
my $bus_len = 2 * $step;

my $incr_no = 1;

my $signal = "SIPM";

my $na = $#ARGV+1;

if( $na < 3) {
    print "usage: $0 <signal> <start> <count> [<incr> {UP|DOWN}]\n";
    print "          <signal>       signal name root\n";
    print "          <start>..<end> is number range (can be descending)\n";
    print "          <incr>         increment (can be negative)\n";
    print "          UP|DOWN is direction for rippers (default = DOWN)\n";
    exit;
}

my $signal = $ARGV[0];
my $start_no = $ARGV[1];
my $nrip = $ARGV[2];

my $rip_y = $step;

if( $na > 3) {
    for( my $i=3; $i<$na; $i++) {
	my $s = $ARGV[$i];
	if( $s =~ /^U/) {
	    $rip_y = -$step;
	} elsif( $s =~ /^-?\d/) {
	    ($incr_no) = $s =~ /^(-?\d+)/;
	}
    }
}

my $end_no = $start_no + ($nrip-1) * $incr_no;
my $range = sprintf "%s[%d..%d]", $signal, $start_no, $end_no;

if( $incr_no < 0) {
    $range = sprintf "%s[%d..%d]", $signal, $end_no, $start_no;
}


my $prefix = qq{EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
\$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
\$EndDescr
};


my $suffix = qq{\$EndSCHEMATC\n};

print $prefix;

for( my $i=0; $i<$nrip; $i++) {
    print "Entry Wire Line\n";
    printf "\t%d %d %d %d\n",
	$x0, $y0+$i*$step, $x0+$step, $y0+$i*$step+$rip_y;
}

for( my $i=0; $i<$nrip; $i++) {
    print "Wire Wire Line\n";
    printf "\t%d %d %d %d\n",
	$x0+$step, $y0+$i*$step+$rip_y, $x0+$step+$wire_len, $y0+$i*$step+$rip_y;

}

for( my $i=0; $i<$nrip; $i++) {
    my $sig = sprintf "%s%d", $signal, $start_no;
    $start_no += $incr_no;
    printf "Text Label %d %d 0    50   ~ 0\n",
	$x0+$step*2, $y0+$i*$step+$rip_y;
    print $sig . "\n";
}

my $y = $y0+$step*($nrip-1);

if( $rip_y < 0) {
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0, $y0, $x0, $y+$bus_len;
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0-$wire_len, $y+$bus_len, $x0, $y+$bus_len;
    printf "Text Label %d %d 0    50   ~ 0\n",
	$x0-$wire_len, $y+$bus_len;
} else {
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0, $y0-$bus_len, $x0, $y;
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0-$wire_len, $y0-$bus_len, $x0, $y0-$bus_len;
    printf "Text Label %d %d 0    50   ~ 0\n",
	$x0-$wire_len, $y0-$bus_len;
}
print "$range\n";


print $suffix;


