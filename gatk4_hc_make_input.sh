
#! /bin/bash

# Create input file run gatk4 HaplotypeCaller in parallel
# Run before gatk4_hc_run_parallel.pbs

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
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

mkdir -p ${INPUTS}
mkdir -p ${logs}

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

rm -rf ${INPUTS}/gatk4_hc.inputs

# Write gatk4_hc.inputs file, using nt=1 
while IFS= read -r intfile; do
	for sample in "${samples[@]}"; do
		out=${outdir}/${sample}
		bam=${bamdir}/${sample}.final.bam
		logdir=${logs}/${sample}
		interval="${scatterdir}/${intfile}"
		echo "${ref},${sample},${bam},${interval},${out},${nt},${logdir}" >> ${INPUTS}/gatk4_hc.inputs
	done
done < "${scatterlist}"

