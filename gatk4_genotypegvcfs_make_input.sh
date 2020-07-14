#! /bin/bash

# Create input file to run gatk4_genotypegvcfs_run_parallel.pbs
# Operates on per interval GenomicsDBImport database files
# Performs joint genotyping (output is uncalibrated jointly genotyped VCF)

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
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
