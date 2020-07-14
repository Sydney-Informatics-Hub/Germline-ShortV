#! /bin/bash

# After running gatk4_hc_run_parallel.pbs, check that all .vcf and .vcf.idx files
# have been created for each interval for each sample
# If not, this script creates gatk4_hc_missing.inputs
# Then run gatk4_hc_missing_run_parallel.pbs to re-run these in parallel, with a single node
# to avoid MoM errors

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
bamdir=../Final_bams
outdir=./Interval_VCFs
finaldir=../Final_Germline-ShortV_GVCFs
logs=./Logs
	
# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

mkdir -p ${finaldir}

# For each sample, check intervals with no .vcf and .vcf.idx files

num_samples=${#samples[@]}

echo "$(date): Number of samples in ${cohort} is ${num_samples}"

if [[ $num_samples == $(ls ${logs}/gatk4_hc/*errors.txt | wc -l) ]]
then
	echo "$(date): Scanning $num_samples error files"
	if ! [ `cat ${logs}/gatk4_hc/*errors.txt` ]
	then
		echo "$(date): No errors found in HaplotypeCaller job for ${cohort} for ${num_samples}"
		if ! [ `cat ${logs}/gatk4_gathervcfs.e` ]
		then
			echo "$(date): No errors found in GatherGVCFs step for ${cohort}. Tidying up..."
			
			for sample in "${samples[@]}"; do
				cp ${outdir}/${sample}/${sample}.g.vcf* ${finaldir}

			done
		else
			echo "$(date): There was an error in the GatherGVCFs step for ${cohort}. Please investigate"
		fi
		
	else
		echo "$(date):Please investigate errors for ${cohort}"
	fi
else
	echo "$(date): $num_samples does not equal the number of error files found. Please run checklogs script"

fi

echo "$(date): Moved ${cohort} sample GVCFs and index files to ${finaldir}."
echo "$(date): Please check ${final_dir} and clean interval VCF directory for ${cohort}."
