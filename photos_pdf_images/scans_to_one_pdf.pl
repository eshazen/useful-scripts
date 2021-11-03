#!/usr/bin/perl
#
# convert a bunch of jpgs to individual PDFs at specified resolution
# concatenate the PDFs
#
use strict;

my $na = $#ARGV+1;
if( $na == 0) {
    print "usage:  scans_to_one_pdf.pl [-p <pixels>] [-r <angle>] <list_of_pngs>\n";
    print "  <pixels> is ultimate resolution, e.g. 1000000 for 1M\n";
    exit;
}
my $fa = 0;
my $npix = 1000000;
my $rot = 0;

# arguments the hard way
for( my $i=0; $i<$na; $i++) {
    if( $ARGV[$i] =~ /^-([a-zA-Z])/) {
	my ($opt) = $ARGV[$i] =~ /^-([a-zA-Z])/;
	if( $i > $na-1) {
	    die "Missing argument after $ARGV[$i]";
	    exit;
	}
	if( uc($opt) eq "P") {
	    $npix = $ARGV[$i+1];
	    $fa = $i+2;
	    print "Resolution set to $npix pixels\n";
	}
	if( uc($opt) eq "R") {
	    $rot = $ARGV[$i+1];
	    $fa = $i+2;
	    print "Rotation angle set to $rot degrees\n";
	}
	$i++;
    }
}

my $cat = "";
for( my $i=$fa; $i<$na; $i++) {
    my $fscan = $ARGV[$i];
    my $fsave = $fscan;
    $cat .= " $fscan.pdf";
    print "Processing $fscan\n";
    if( $fscan =~ /.jpg/) {
	my $fjpg = $fscan;
	$fscan =~ s/.jpg/.png/;
	print "Converting $fjpg to $fscan\n";
	my $cmd = "/usr/bin/djpeg $fjpg | pnmrotate $rot | pnmtopng > $fscan";
	print $cmd . "\n";
	system $cmd;
    }
    print "/usr/bin/pngtopnm $fscan | pnmscale -pixels $npix > temp.pnm\n";
    system "/usr/bin/pngtopnm $fscan | pnmscale -pixels $npix > temp.pnm";
    print "/usr/bin/convert temp.pnm $fsave.pdf\n";
    system "/usr/bin/convert temp.pnm $fsave.pdf";
}
print "/usr/bin/pdftk $cat cat output one_pdf.pdf\n";
system "/usr/bin/pdftk $cat cat output one_pdf.pdf";
