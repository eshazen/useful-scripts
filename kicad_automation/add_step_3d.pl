#!/usr/bin/perl
#
# read a Kicad 6 kicad_pcb file
# look for parts with wrl models and add step if available
#
# need to know the directory, usually /usr/share/kicad/3dmodels
#
#     (model "${KICAD6_3DMODEL_DIR}/Resistor_THT.3dshapes/R_Axial_DIN0617_L17.0mm_D6.0mm_P25.40mm_Horizontal.wrl"
#       (offset (xyz 0 0 0))
#       (scale (xyz 1 1 1))
#       (rotate (xyz 0 0 0))
#     )
#     (model "${KICAD6_3DMODEL_DIR}/Resistor_THT.3dshapes/R_Axial_DIN0617_L17.0mm_D6.0mm_P25.40mm_Horizontal.step"
#       (offset (xyz 0 0 0))
#       (scale (xyz 1 1 1))
#       (rotate (xyz 0 0 0))
#     )
#   )
#
# we depend on exactly this format, including the extra ) after the last 3d model
#

use strict;
use Data::Dumper;

my %fmods;

# my $envar = "KISYS3DMOD";
my $envar = "KICAD6_3DMODEL_DIR";

# set to value of environment variable
my $dir = "/usr/share/kicad/3dmodels/";

if( ! -d $dir) {
    die "Directory $dir doesn't exist!";
}

my $foot;

my $in_model = 0;		# flag: processing model
my $last_model = 0;		# flag: last model

my @model;

my $fname;


while( my $line = <>) {
    chomp $line;
    print "$line\n";

    # start a new model if needed
    if( $line =~ /\(model \"\$\{$envar\}/) {
	$in_model = 1;
	@model = ( );
	($fname) = $line =~ /\(model \"\$\{$envar\}\/([^"]+)/;
    }
    
    push @model, $line if( $in_model);

    if( $in_model && $line =~ /^\s*\)\s*$/) {
	# end of model
	if( $fname =~ /\.wrl$/) {
	    foreach my $t ( @model) {
		if( $t =~ /\(model \"\$\{$envar\}/) {		
		    $t =~ s/\.wrl/\.step/;
		}
		print "$t\n";
	    }
	}
	$in_model = 0;
    }
}


