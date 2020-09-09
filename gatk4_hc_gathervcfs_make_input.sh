#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: 
# Creates input file for gatk4_hc_gathervcfs_run_parallel.pbs
# Usage:
# sh gatk4_hc_gathervcfs_make_input.sh <cohort> 
# to create inputs for ../<cohort>.config
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

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of ../<cohort>.config e.g. sh gatk4_hc_gathervcfs_make_input.sh <cohort>"
	exit
fi

cohort=$1
config=../$cohort.config
vcfdir=./Interval_VCFs
logdir=./Logs/gatk4_hc_gathervcfs
INPUTS=./Inputs

# Collect sample IDs from config file
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

mkdir -p ${logdir}
mkdir -p ${INPUTS}

rm -rf ${INPUTS}/gatk4_hc_gathervcfs.inputs

# Make arguments file for each sample, then add to inputs file
for sample in "${samples[@]}"; do
	
	args=${INPUTS}/gatk4_hc_gathervcfs_${sample}\.args
	out=../Final_Germline-ShortV_GVCFs/${sample}.g.vcf.gz

	rm -rf ${args}
	
	for interval in $(seq -f "%04g" 0 3199);do
		echo "--I " ${vcfdir}/${sample}/${sample}.${interval}.vcf >> ${args}
	done
	echo "${sample},${args},${logdir},${out}" >> ${INPUTS}/gatk4_hc_gathervcfs.inputs
done
