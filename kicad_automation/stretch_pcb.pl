#!/usr/bin/perl
#
# find all placements / vertices which fit in a range and apply a translation
#
my $debug = 0;

my $x_trans = 350;
my $y_trans = 0;

my $x_min = 63;
my $x_max = 110;
my $y_min = 50;
my $y_max = 100;

my $line;

#
# my_add( a, b)
#   add b (integer) to a (float)
#   return a string result
#
sub my_add {
    my $a = $_[0];
    my $b = $_[1];
    my $res;
    
    return $a if( $b == 0);
    
    # integer-only add
    print "Add ($a,$b)\n" if($debug);
    if( $a =~ /./) {
	my @p = split /\./, $a;
	my $int = $p[0];
	my $frac = $p[1];
	print "int=$int frac=$frac\n" if($debug);
	$int += $b;
	$res = $int . "." . $frac;
    } else {
	print "int=$a\n";
	$res = $a + $b;
    }
    print "  res = $res\n" if($debug);
    return $res;
}

my @keywords = ( "start", "end", "at", "xy");

while( $line = <>) {
    chomp $line;
    foreach $keyword ( @keywords) {
	my $match = "\\(" . $keyword . "\\s+([0-9. ]*)\\)";
#	print "Match= [$match]\n" if($debug);
	if( $line =~ /$match/) {
#	    print "Matched!  $line\n" if($debug);
	    my ($coord) = $line =~ /$match/;
	    my ($x,$y) = $coord =~ /(\S+)\s(\S+)/;
	    # split coord so we can keep extra stuff
	    my @sc = split ' ', $coord;
	    print "  key=$keyword coord=\"$coord\" ($x,$y)\n" if($debug);
	    if( $x > $x_min && $x < $x_max && $y > $y_min && $y < $y_max) {
		print "$keyword: \"$coord\" ($x,$y)\n" if($debug);
		my $x1 = my_add($x, $x_trans);
		my $y1 = my_add($y, $y_trans);
		my $newcoord = "$x1 $y1";
		$newcoord .= " " . $sc[2] if( $#sc > 1);
		print "  new = $newcoord\n" if($debug);
		print "B-LINE: $line\n" if($debug);
		$line =~ s/$coord/$newcoord/;
		print "A-LINE: $line\n" if($debug);
		$subs++;
	    }
	}
    }
    print "$line\n" if( !$debug);
}
