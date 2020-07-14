#! /bin/bash

# After running gatk4_hc_run_parallel.pbs, check that all .vcf and .vcf.idx files
# have been created for each interval for each sample
# If not, this script creates gatk4_hc_missing.inputs
# Then run gatk4_hc_missing_run_parallel.pbs to re-run these in parallel, with a single node

if [ -z "$1" ]
then
        echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc__missing_make_input.sh samples_batch1"
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
	# Write a list of existing log files to later check for errors in parallel
	# find ${logs}/${sample} -name *.oe -type f >> ${inputlogs}
done

echo "$(date): There are $total_missing vcf files in $cohort. Please run gatk4_hc_missing_run_parallel.pbs"
