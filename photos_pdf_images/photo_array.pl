#!/usr/bin/perl
#
# create an array of photos, all scaled to the same height
# inputs must be jpg files (for now)
#
# puts output in photo_array.jpg
# 
# options:
#   -height=nnn     rescale each image to specified height (def: 250)
#   -border=nnn     add white border to each image with width (def: 5)
#   -columns=nnn    pack nnn images per row
#   -rows=nnn       create nnn rows of images
#
#   if neither rows nor columns are specified, create the smallest square array
#   if both are specified, columns is ignored
#

use File::Temp qw/ tempfile tempdir mktemp /;
use File::Basename;

my $hgt = 250;			# default height for each photo
my $bdr = 5;			# default white border added to each
my $rows = 0;			# default rows
my $cols = 0;			# default columns

my $na = $#ARGV+1;

if( $na < 1) {
    print "usage: photo_array [options] <jpeg-files>\n";
    print qq{
   -height=nnn     rescale each image to specified height (def: 250)
   -border=nnn     add white border to each image with width (def: 5)
   -columns=nnn    pack nnn images per row
   -rows=nnn       create nnn rows of images

   if neither rows nor columns are specified, create the smallest square array
   if both are specified, columns is ignored
};
    exit;
}

my @OPTS;
my @FILEZ;

# get files off the command line
foreach my $arg ( @ARGV) {
    push @OPTS, $arg if( $arg =~ /^-/);
    push @FILEZ, $arg if( $arg !~ /^-/);
}

my $nf = $#FILEZ + 1;
my $sq = sqrt( $nf);
$sq = int($sq)+1 if( $sq != int($sq)) ;
    
if( !$rows && !$cols) {
    print "Making default $sq x $sq array\n";
}

if( $#OPTS >= 0) {
    foreach my $opt ( @OPTS) {
	print "Process options $opt\n";
	if( $opt =~ /^-height=/) {
	    ($hgt) = $opt =~ /^-height=(\d+)/;
	}
	if( $opt =~ /^-border=/) {
	    ($bdr) = $opt =~ /^-border=(\d+)/;
	}
	if( $opt =~ /^-rows=/) {
	    ($rows) = $opt =~ /^-rows=(\d+)/;
	}
	if( $opt =~ /^-columns=/) {
	    ($cols) = $opt =~ /^-columns=(\d+)/;
	}
    }
}

print "Photo height $hgt\n";
print "Border width $bdr\n";

my @TEMPS;

foreach my $fp ( @FILEZ) {
    my( $fn, $pa, $sfx) = fileparse( $fp, qr/\.[^.]*/);
    print "name = $fn type=$sfx...";
    if( $sfx =~ m/jpg|jpeg|JPEG|JPG/) {
	print "Processing JPEG\n";
	my $tfn = mktemp( "photo_array_XXXXX");
	push @TEMPS, $tfn;
	my $cmd = "djpeg $fp | pnmscale -height=$hgt | pnmmargin -white $bdr | pnmtojpeg > $tfn";
	print "# $cmd\n";
	system $cmd;
    } else {
	print "Skipping\n";
    }
}

my $geo = $sq . "x" . $sq;
$geo = "${cols}x" if( $cols);
$geo = "x${rows}" if( $rows);

my $cmd = "montage -mode Concatenate -tile $geo photo_array_* photo_array.jpg";
print "# $cmd\n";
system $cmd;

$cmd = "rm photo_array_*";
print "# $cmd\n";
system $cmd;

