#!/usr/bin/perl
#
# cross-check symbol library use in schematic
# in KiCAD 6 designs
#
use strict;
use open qw< :encoding(UTF-8) >;
my $sl;

open( $sl, "<", "sym-lib-table") or die "opening sym_lib_table", ;

sub getsval {
    my ($expr, $name) = @_;
    my ($val) = $expr =~ /\($name "([^"]+)"/;
    return $val;
}

print "Checking sym-lib-table:\n";
while( my $line = <$sl>) {
    if( $line =~ /\(lib/) {
	chomp $line;
	my $name = getsval( $line, "name");
	my $type = getsval( $line, "type");
	my $uri = getsval( $line, "uri");
	$uri =~ s/\$\{KIPRJMOD\}/\./;
	if( ! -f $uri) {
	    print "MISSING: name=$name type=$type uri=$uri\n";
	} else {
	    print "  FOUND: name=$name type=$type uri=$uri\n";
	}
    }
}
print "\n";

