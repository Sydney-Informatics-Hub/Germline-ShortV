
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
# Date last modified: 24/02/2021
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested citation:
# Sydney Informatics Hub, Core Research Facilities, University of Sydney, 
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>, 
# https://github.com/Sydney-Informatics-Hub/Bioinformatics
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

# Can include run_num to manage input and log files for benchmarking
# Otherwise, hash out
run_num=_0

cohort=$1
config=../$cohort.config
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
bamdir=../Final_bams
outdir=./Interval_VCFs
logs=../Logs/gatk4_hc$run_num
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_hc$run_num.inputs

mkdir -p ${INPUTS}
mkdir -p ${logs}

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ! ${labid} =~ -T.*$ && ! ${labid} =~ -P.*$ && ! ${labid} =~ -M.*$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Writing inputs for gatk4_hc_run_parallel.pbs for ${#samples[@]} samples and 3200 tasks per sample to ${INPUTS}/gatk4_hc.inputs"
echo "$(date): Normal samples found include ${samples[@]}"

rm -rf ${inputfile}

# Write gatk4_hc.inputs file, using nt=1 
while IFS= read -r intfile; do
	for sample in "${samples[@]}"; do
		out=${outdir}/${sample}
		bam=${bamdir}/${sample}.final.bam
		logdir=${logs}/${sample}
		interval="${scatterdir}/${intfile}"
		echo "${ref},${sample},${bam},${interval},${out},${logdir}" >> ${inputfile}
	done
done < "${scatterlist}"

ncpus=$(( ${#samples[@]}*2*48 ))
mem=$(( ${#samples[@]}*2*190 ))
num_tasks=`wc -l $inputfile | cut -d' ' -f 1`

echo "$(date): Number of samples: ${#samples[@]}"
echo "$(date): Number of tasks in $inputfile: $num_tasks"
echo "$(date): Recommended compute to request in gatk4_hc_run_parallel.pbs: walltime=02:00:00,ncpus=${ncpus},mem=${mem}GB,wd"
