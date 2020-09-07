#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_genomicsdbimport_run_parallel.pbs
# Consolidates VCFs across multiple samples for each interval
# Run after mergining interval VCFs into GVCF per sample (operates on GVCFs)
# using gatk4_hc_gathervcfs_run_parallel.pbs
# Usage: sh gatk4_genomicsdbimport_make_input.sh <cohort>
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
	echo "Please run this script with the base name of ../<cohort>.config e.g. sh gatk4_genomicsdbimport_make_input.sh <cohort>"
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
nt=12

mkdir -p ${INPUTS}
mkdir -p ${logs}

rm -rf ${INPUTS}/gatk4_genomicsdbimport.inputs
rm -rf ${sample_map}

# Collect sample IDs from config file
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

for sample in "${samples[@]}"; do
	echo -e "${sample}	${vcfdir}/${sample}.g.vcf.gz" >> ${sample_map}
done

# Loop through intervals in scatterlist file
# Print to ${INPUTS}
while IFS= read -r intfile; do
	interval="${scatterdir}/${intfile}"
	echo "${ref},${cohort},${interval},${sample_map},${outdir},${logs},${nt}" >> ${INPUTS}/gatk4_genomicsdbimport.inputs
done < "${scatterlist}"


