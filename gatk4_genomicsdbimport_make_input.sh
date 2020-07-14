#! /bin/bash

# Create input file run gatk4 GenomicsDBImport in parallel
# Consolidates VCFs across multiple samples for each interval
# Run after mergining interval VCFs into GVCF per sample (operates on GVCFs)

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


