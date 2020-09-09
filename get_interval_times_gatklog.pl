#!/usr/bin/perl

use strict;
use warnings;

#########################################################
#
# Platform: NCI Gadi HPC
# Description: 
# Supplementary script for gatk4_hc_checklogs_run_parallel.sh
# Checks duration for each gatk4_hc.sh task (1 sample, 1 interval)
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 17/08/2020
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#
#########################################################

my $logdir=$ARGV[0];

my @files = <$logdir/*.oe>;

print "#Interval\tDuration\n";

foreach my $file (@files){
	$file =~ m/(\d+).oe/;
	my $interval = $1;
	my $timelog=`grep "HaplotypeCaller done. Elapsed time:" $file`;
	$timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
	my $duration=$1;
	print "$interval\t$duration\n";
}
