#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: 
# Checks all .vcf and .vcf.idx files exist and are not empty
# after running gatk4_hc_run_parallel.pbs. 
# If not, this script creates gatk4_hc_missing.inputs
# Usage: 
# sh gatk4_hc_missing_make_input <cohort> 
# To check missing .vcf and .vcf.idx for <cohort>.config
# Run when gatk4_hc_run_parallel.pbs is complete. 
# Creates gatk4_hc_missing.inputs if there are missing files
# Then run gatk4_hc_missing_run_parallel.pbs 
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
        echo "Please run this script with the base name of your <cohort>.config file, e.g. sh gatk4_hc_missing_make_input.sh <cohort>"
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
inputfile=${INPUTS}/gatk4_hc_missing.inputs
nt=1

rm -rf ${inputfile}
rm -rf ${inputlogs}

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

# For each sample, check intervals with no .vcf and .vcf.idx files

for sample in "${samples[@]}"; do
	# Check if .vcf and .vcf.idx files exist and are not empty
	i=0
	for interval in $(seq -f "%04g" 0 3199); do
		logfile=${logs}/${sample}/${interval}.oe
		vcf=${outdir}/${sample}/${sample}.${interval}.vcf
		idx=${outdir}/${sample}/${sample}.${interval}.vcf.idx
		bam=${bamdir}/${sample}.final.bam
		out=${outdir}/${sample}
		logdir=${logs}/${sample}
		if ! [[ -s "${vcf}" &&  -s "${idx}" ]]
		then
			intfile=$(grep ${interval} ${scatterlist})
			echo "${ref},${sample},${bam},${scatterdir}/${intfile},${out},${nt},${logdir}" >> ${inputfile}
		else
			((++i))
		fi
	done
	
	if [[ $i == 3200 ]]
	then
		echo "$(date): ${sample} has all vcf and vcf.idx present. Ready for merging into GVCF."
	else
		num_missing=$((3200 - $i))
		echo "$(date): ${sample} has ${num_missing} missing vcf or vcf.idx files."
		total_missing=$(($total_missing+$num_missing))
	fi
done

echo "$(date): There are $total_missing vcf files in $cohort. Please run gatk4_hc_missing_run_parallel.pbs"
