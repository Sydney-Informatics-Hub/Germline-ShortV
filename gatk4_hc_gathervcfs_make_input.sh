#! /bin/bash
# Create input for: gatk4_hc_gathervcfs_run_parallel.pbs

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
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
	out=${vcfdir}/${sample}/${sample}.g.vcf.gz

	rm -rf ${args}
	
	for interval in $(seq -f "%04g" 0 3199);do
		echo "--I " ${vcfdir}/${sample}/${sample}.${interval}.vcf >> ${args}
	done
	echo "${sample},${args},${logdir},${out}" >> ${INPUTS}/gatk4_hc_gathervcfs.inputs
done
