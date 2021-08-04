#!/usr/bin/perl
#
# write a KiCAD EESchema file with a set of buss rippers
# known to work only for "EESchema Schematic File Version 4" files
# (KiCAD 5.1.x)
#
# Usage: <signal> <start> <count> [<incr> {UP|DOWN} {GAP n}]
#    <signal> = signal name prefix
#    <start> = integer starting number
#    <count> = positive count
#    <incr>  = number increment (may be negative)
#    UP|DOWN = specify ripper direction.  Default = DOWN
#    GAP n   = skip one wire every n
#    MIRROR  = flip left/right
#    STEP n  = space between rippers in 50 mil units (default = 2)

use strict;

#------------------------------------------------------------
# calculate Y position based on y0, iteration, step, gap
#------------------------------------------------------------
sub set_y {
    my ($y0, $i, $skip, $gap) = @_;
    if( $gap) {
	if( $i >= $gap) {
	    $i += int($i / $gap);
	}
    }
    my $y = $y0 + $i * $skip;
    return $y;
}
    
#------------------------------------------------------------
# calculate total length based on step, nrip, gap
#------------------------------------------------------------
sub total_len {
    my ($step, $nrip, $gap) = @_;
    my $l = $step*($nrip-1);
    if( $gap) {
	$l += $step * (int($nrip/$gap)-1);
    }
    return $l;
}

my $grid = 50;
my $step = 100;
my $skip = 100;
my $x0 = 2500;
my $y0 = 1500;

my $wire_len = 10 * $grid;
my $bus_len = 2 * $step;

my $incr_no = 1;

my $na = $#ARGV+1;

# multiply all X offsets by $mirror
my $mirror = 1;

if( $na < 3) {
    print "usage: $0 <signal> <start> <count> [<incr> {UP|DOWN}] [GAP n]\n";
    print "          <signal>       signal name root\n";
    print "          <start>..<end> is number range (can be descending)\n";
    print "          <incr>         increment (can be negative)\n";
    print "          UP|DOWN is direction for rippers (default = DOWN)\n";
    print "          GAP n          skips a wire every n";
    print "          STEP n         space between rippers (default=2)\n";
    print "          WIRE n         wire length in grids (default=10)\n";
    exit;
}

my $signal = $ARGV[0];
my $start_no = $ARGV[1];
my $nrip = $ARGV[2];

my $rip_y = $step;

my $i = 3;

my $gap = 0;				 # default: no gap

if( $na > 3) {
    while( $i < $na) {
	my $s = $ARGV[$i];
	if( $s =~ /^-?\d/) {	         # signed number?
	    ($incr_no) = $s =~ /^(-?\d+)/;   # it's an increment
	} elsif( $s =~ /^[Uu]/) {		 # UP flips rippers
	    $rip_y = -$step;
	} elsif( $s =~ /^[Dd]/) {		 # DOWN doesn't
	    $rip_y = $step;
	} elsif( $s =~ /^[Mm]/) {
	    $mirror = -1;
	} elsif( $s =~ /^[Gg]/) {		 # GAP sets the gap
	    if( $i == $na-1) {
		print STDERR "Expecting a number after GAP\n";
		exit;
	    }
	    $s = $ARGV[++$i];
	    ($gap) = $s =~ /^(\d+)/;		 # set the gap
	} elsif( $s =~ /^[Ss]/) {		 # STEP sets the step
	    if( $i == $na-1) {
		print STDERR "Expecting a number after STEP\n";
		exit;
	    }
	    $s = $ARGV[++$i];
	    ($skip) = $s =~ /^(\d+)/;	 # set the gap
	    $skip *= $grid;
	} elsif( $s =~ /^[Ww]/) {		 # WIRE sets length
	    if( $i == $na-1) {
		print STDERR "Expecting a number after WIRE\n";
		exit;
	    }
	    $s = $ARGV[++$i];
	    ($wire_len) = $s =~ /^(\d+)/;	 # set the wire length
	    $wire_len *= $grid;
	}
	$i++;
    }
}

print STDERR "Gap: $gap\n";


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
    my $y = set_y( $y0, $i, $skip, $gap);
    print "Entry Wire Line\n";
    printf "\t%d %d %d %d\n",
	$x0, $y, $x0+$step*$mirror, $y+$rip_y;
}

for( my $i=0; $i<$nrip; $i++) {
    my $y = set_y( $y0, $i, $skip, $gap);
    print "Wire Wire Line\n";
    printf "\t%d %d %d %d\n",
	$x0+$step*$mirror, $y+$rip_y, $x0+($step+$wire_len)*$mirror, $y+$rip_y;

}

for( my $i=0; $i<$nrip; $i++) {
    my $y = set_y( $y0, $i, $skip, $gap);
    my $sig = sprintf "%s%d", $signal, $start_no;
    $start_no += $incr_no;
    printf "Text Label %d %d 0    50   ~ 0\n",
	($mirror < 0) ? $x0-$wire_len : $x0+$step*2, $y+$rip_y;
    print $sig . "\n";
}

my $y = $y0+total_len( $skip, $nrip, $gap);

if( $rip_y < 0) {
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0, $y0, $x0, $y+$bus_len;
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0-$wire_len*$mirror, $y+$bus_len, $x0, $y+$bus_len;
    printf "Text Label %d %d 0    50   ~ 0\n",
	$x0-$wire_len*$mirror, $y+$bus_len;
} else {
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0, $y0-$bus_len, $x0, $y;
    printf "Wire Bus Line\n\t%d %d %d %d\n",
	$x0-$wire_len*$mirror, $y0-$bus_len, $x0, $y0-$bus_len;
    printf "Text Label %d %d 0    50   ~ 0\n",
	$x0-$wire_len*$mirror, $y0-$bus_len;
}
print "$range\n";


print $suffix;


