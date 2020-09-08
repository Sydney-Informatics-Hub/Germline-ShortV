
#!/usr/bin/perl

#########################################################
#
# Platform: NCI Gadi HPC
# Description: This script is run by gatk4_genotypegvcfs_missing_make_input.sh
# Check gatk4_genotypegvcfs_rurn_parallel.pbs log files for errors
# For each interval, duration and memory will be printed. If an error is detected,
# "NA" will be printed and gatk4_genomicsdbimport_missing_make_input.sh will 
# write this interval to gatk4_genotypegvcfs_missing.inputs to be re-run
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

use strict;
use warnings;

my $logdir="./Logs/gatk4_genotypegvcfs";
my $out="$logdir/interval_duration_memory.txt";

`rm -rf $out`;

open(OUT,'>',"$out") or die "Could not write to $out: $!\n";

print OUT "#Interval\tDuration\tMemory_Gb\n";

for(my $i=0000; $i <3200; $i++){
	my $interval=sprintf("%04d",$i);
	my $file="$logdir\/$interval\.oe";
	if(-s $file){
		# Check for errors first, because errors will still print done and mem
		my $errors =`grep -i ERROR $file`;
		if($errors){
			#print "Errors found in $file! You may want to check these\n";
			print OUT "$interval\tNA\tNA\n";
		}
		else{
			my $timelog=`grep "GenotypeGVCFs done. Elapsed time:" $file`;
			$timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
			my $duration=$1;
			my $memory=`grep "Runtime.totalMemory" $file`;
			$memory=~ m/([0-9]+)\n$/;
			my $bytes=$1;
			if($memory && $bytes){
				my $gigabytes=$bytes/1000000000;
				print OUT "$interval\t$duration\t$gigabytes\n";
			}
			else{
				print OUT "$interval\tNA\tNA\n";
			}
		}
	}
	else{
		print OUT "$interval\tNA\tNA\n";
	}
}
close OUT;
exit;
