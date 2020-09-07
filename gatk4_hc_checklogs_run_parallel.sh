#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: 
# Run gatk4_hc_checklogs.sh for ../<cohort>.config
# One job will be submitted for each sample in <cohort>.config
# Usage: Adjust <project> 
# sh gatk4_hc_checklogs_run_parallel.sh <cohort>
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
        echo "Please run this script with the base name of your ../<cohort>.config file, e.g. sh gatk4_hc_checklogs_run_parallel.sh <cohort>"
        exit
fi


cohort=$1
config=../$cohort.config
INPUTS=./Inputs
SCRIPT=./gatk4_hc_checklogs.sh
PERL_SCRIPT=./get_interval_times_gatklog.pl
logs=./Logs/gatk4_hc

while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

num_samples="${#samples[@]}"

echo "$(date): There are $num_samples of normal samples in $cohort. Running $num_samples jobs to check errors. Tarring log directories once complete"

for sample in "${samples[@]}"; do
	qsub \
	-v sample="${sample}",logs="${logs}",input="${INPUTS}/gatk4_hc_checklogs_${sample}.inputs",perl="${PERL_SCRIPT}" \
	-N ${sample}_checklogs \
	-P <project> \
	-l wd,ncpus=4,mem=16GB,walltime=00:20:00 \
	-W umask=022 \
	-l storage=scratch/gq19 \
	-q express \
	-e ${logs}/${sample}_checklogs.e \
	-o ${logs}/${sample}_checklogs.o \
	${SCRIPT}
done
