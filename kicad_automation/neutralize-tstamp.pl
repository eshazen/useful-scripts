#!/usr/bin/perl
#
# for diff compare, replace matching (tstamp long-hex-value) with literally "(tstamp xxxxxx)"
#
while( $line = <>) {
    chomp $line;
    if( $line =~ /\(tstamp\s[^\)]*\)/) {
	$line =~ s/\(tstamp\s[^\)]*\)/(tstamp xxxxx)/g;
    }
    print "$line\n";
}
