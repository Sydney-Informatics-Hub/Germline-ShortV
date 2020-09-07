#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_genomicsdbimport_missing_run_parallel.pbs
# Consolidates VCFs across multiple samples for missing intervals
# If there are no missing intervals, tidys up logs by tarballing them
# Run after gatk4_genomicsdbimport_run_parallel.pbs
# Usage: sh gatk4_genomicsdbimport_missing_make_input.sh <cohort>
# where <cohort> is the base name of ../<cohort>.config
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
	echo "Please run this script with the base name of ../<cohort>.config e.g. sh gatk4_genomicsdbimport_missing_make_input.sh <cohort>"
fi

cohort=$1
config=../$cohort.config
INPUTS=./Inputs
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
vcfdir=../Final_Germline-ShortV_GVCFs
sample_map=${INPUTS}/${cohort}.sample_map
outdir=./$cohort\_GenomicsDBImport
logs=./Logs/gatk4_genomicsdbimport
perlfile=$logs/interval_duration_memory.txt
nt=12
# Use double memory - ie 12CPU, 375Gb mem on hugemem node per task

mkdir -p ${INPUTS}
mkdir -p ${logs}

rm -rf ${INPUTS}/gatk4_genomicsdbimport_missing.inputs
rm -rf ${perlfile}

# Run perl script to get duration
echo "$(date): Checking log files for errors, obtaining duration and memory usage per task..."
`perl gatk4_genomicsdbimport_checklogs.pl`

# Check output file 
while read -r interval duration memory; do
	if [[ $duration =~ NA || $memory =~ NA ]]
	then
		redo+=("$interval")
	fi
done < "$perlfile"

if [[ ${#redo[@]}>1 ]]
then
	echo "$(date): There are ${#redo[@]} intervals that need to be re-run."
	echo "$(date): Writing inputs to ${INPUTS}/gatk4_genomicsdbimport_missing.inputs"

	for redo_interval in ${redo[@]};do
        interval="${scatterdir}/${redo_interval}-scattered.interval_list"
        echo "${ref},${cohort},${interval},${sample_map},${outdir},${logs},${nt}" >> ${INPUTS}/gatk4_genomicsdbimport_missing.inputs
done
else
	echo "$(date): There are no intervals that need to be re-run. Tidying up..."
	cd ${logs}
	tar --remove-files \
		-czvf genomicsdbimport_logs.tar.gz \
		*.oe

fi
