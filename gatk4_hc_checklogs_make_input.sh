#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: 
# Create input file to check gatk_hc log files in parallel
# For each sample, record minutes taken per interval
# Flag any intervals with error messages
# If there are no error messages, archive log files in a per sample tarball
# Usage: 
# sh gatk4_hc_checklogs_make_input.sh <cohort> 
# to run for samples in <cohort>.config
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


if [ -z "$1" ]
then
        echo "Please run this script with the base name of your ../<cohort>.config file, e.g. sh gatk4_hc_checklogs_make_input.sh <cohort>"
        exit
fi

cohort=$1
config=../$cohort.config
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
bamdir=../Final_bams
outdir=./Interval_VCFs
logs=./Logs/gatk4_hc
INPUTS=./Inputs
nt=1

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"


# For each sample, check which tasks have failed

for sample in "${samples[@]}"; do
	rm -rf ${INPUTS}/gatk4_hc_checklogs_${sample}.inputs
	for interval in $(seq -f "%04g" 0 3199); do
		logfile=${logs}/${sample}/${interval}.oe
		echo "${sample},${interval},${logfile},${logs}" >> ${INPUTS}/gatk4_hc_checklogs_${sample}.inputs
	done
done

