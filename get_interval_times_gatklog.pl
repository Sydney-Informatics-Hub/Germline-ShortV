#!/usr/bin/perl

use strict;
use warnings;

#########################################################
# 
# Platform: NCI Gadi HPC 
# Usage: 
# Version: 2.0 
# 
# For more details see: https://github.com/Sydney-Informatics-Hub/Germline-ShortV 
# 
# If you use this script towards a publication, support us by citing: 
# 
# Suggest citation: 
# Sydney Informatics Hub, Core Research Facilities, University of Sydney, 
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>, 
# https://github.com/Sydney-Informatics-Hub/Germline-ShortV 
# 
# Please acknowledge the Sydney Informatics Hub and the facilities: 
# 
# Suggested acknowledgement: 
# The authors acknowledge the technical assistance provided by the Sydney 
# Informatics Hub, a Core Research Facility of the University of Sydney 
# and the Australian BioCommons which is enabled by NCRIS via Bioplatforms 
# Australia. The authors acknowledge the use of the National Computational 
# Infrastructure (NCI) supported by the Australian Government. 
# 
#########################################################

my $logdir=$ARGV[0];

my @files = <$logdir/*.log>;

print "#Interval\tDuration\n";

foreach my $file (@files){
	$file =~ m/(\d+).oe/;
	my $interval = $1;
	my $timelog=`grep "HaplotypeCaller done. Elapsed time:" $file`;
	$timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
	my $duration=$1;
	print "$interval\t$duration\n";
}
