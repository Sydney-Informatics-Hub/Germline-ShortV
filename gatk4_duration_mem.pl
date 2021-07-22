
#!/usr/bin/perl

#########################################################
#
# Platform: NCI Gadi HPC
# Description: This script is run by gatk4_genomicsdbimport_missing_make_input.sh
# to check 3200 interval log files from gatk4_genomicsdbimport_run_parallel.pbs job
# It checks if the log file exists and greps for "error"
# For each interval, duration and memory will be printed. If an error is detected,
# "NA" will be printed and gatk4_genomicsdbimport_missing_make_input.sh will 
# write this interval to gatk4_genomicsdbimport.inputs to be re-run
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

# Collect: interval duration, check Runtime.totalMemory()

my $logdir=$ARGV[0];
my $out="$logdir/GATK_duration_memory.txt";

`rm -rf $out`;

open(OUT,'>',"$out") or die "Could not write to $out: $!\n";

print OUT "#File\tDuration\tMemory_Gb\n";

my @logs=`find $logdir -type f | sort -V`;

foreach my $file (@logs){
	chomp($file);
	# Only check GATK logs, ignore all other files
	my $check_gatk_log=`tail $file | grep GATK`;
	if($check_gatk_log){
	# Check for errors first, because errors will still print done and mem
        	my $errors =`tail $file | grep -i ERROR`;
		if($errors){
                	print OUT "$file\tNA\tNA\n";
         	}
		else{
			my $timelog=`tail $file | grep " done. Elapsed time:"`;
			$timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
			my $duration=$1;
			my $memory=`tail $file | grep "Runtime.totalMemory"`;
			$memory=~ m/([0-9]+)\n$/;
			my $bytes=$1;
			if($memory && $bytes){
				my $gigabytes=$bytes/1000000000;
			print OUT "$file\t$duration\t$gigabytes\n";
			}
		}
	}
}	
close OUT;
exit;
