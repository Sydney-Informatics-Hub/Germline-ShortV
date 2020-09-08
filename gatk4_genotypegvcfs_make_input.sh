#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_genotypegvcfs_run_parallel.pbs
# Performs joint-genotyping, operating on GenomicsDBImport database
# files per genomic interval. The output is a multi-sample, unrecalibrated VCF.
# Usage: sh gatk4_genotypegvcfs_make_input.sh <cohort>
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
	echo "Please run this script with the base name of ../<cohort>.config e.g. sh gatk4_genotypegvcfs_make_input.sh <cohort>"
fi

cohort=$1
config=../$cohort.config
INPUTS=./Inputs
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
vcfdir=../Final_Germline-ShortV_GVCFs
sample_map=${INPUTS}/${cohort}.sample_map
gendbdir=./$cohort\_GenomicsDBImport
outdir=./$cohort\_GenotypeGVCFs
logs=./Logs/gatk4_genotypegvcfs
nt=8

INPUTS=./Inputs

mkdir -p ${INPUTS}
mkdir -p ${logs}

rm -rf ${INPUTS}/gatk4_genotypegvcfs.inputs

while IFS= read -r intfile; do
	interval="${scatterdir}/${intfile}"
	echo "${ref},${cohort},${interval},${gendbdir},${outdir},${logs},${nt}" >> ${INPUTS}/gatk4_genotypegvcfs.inputs
done < "${scatterlist}"
