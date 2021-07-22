
#!/usr/bin/perl

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
