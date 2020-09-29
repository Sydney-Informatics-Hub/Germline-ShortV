
#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_hc_run_parallel.pbs
# Usage: sh gatk4_hc_make_input.sh <cohort>
# where <cohort> is the base name of ../<cohort>.config
# Resource requirements:
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
	echo "Please run this script with the base name of ../<cohort>.config e.g. sh gatk4_hc_make_input.sh <cohort>"
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

mkdir -p ${INPUTS}
mkdir -p ${logs}

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Writing inputs for gatk4_hc_run_parallel.pbs for ${#samples[@]} samples and 3200 tasks per sample to ${INPUTS}/gatk4_hc.inputs"
echo "$(date): Normal samples found include ${samples[@]}"

rm -rf ${INPUTS}/gatk4_hc.inputs

# Write gatk4_hc.inputs file, using nt=1 
while IFS= read -r intfile; do
	for sample in "${samples[@]}"; do
		out=${outdir}/${sample}
		bam=${bamdir}/${sample}.final.bam
		logdir=${logs}/${sample}
		interval="${scatterdir}/${intfile}"
		echo "${ref},${sample},${bam},${interval},${out},${logdir}" >> ${INPUTS}/gatk4_hc.inputs
	done
done < "${scatterlist}"

ncpus=$(( ${#samples[@]}*2*48 ))
mem=$(( ${#samples[@]}*2*190 ))
echo "$(date): Number of samples: ${#samples[@]}"
echo "$(date): Recommended compute to request in gatk4_hc_run_parallel.pbs: walltime=02:00:00,ncpus=${ncpus},mem=${mem}GB,wd"
