#!/usr/bin/perl

use strict;
use warnings;

# We want to see how long each interval in HC took to compute
# to identify regions that are difficult to call and take longer walltime
# if these are "predicatable" regions, e.g. unplaced/unlocalized contigs
# this script gets duration per task using GATK logs
# will tell us time for all intervals in 1 sample, but not task + duration 

#my $logdir="/scratch/gq19/Batch1/Germline-ShortV-batch1-1/Logs/gatk4_hc/10651-B";

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
	#print "$interval\t$duration\n";
	
}
