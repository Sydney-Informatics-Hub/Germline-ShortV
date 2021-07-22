#! /bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC 
# Usage: 
# Version: 2.0 
# 
# For more details see: https://github.com/Sydney-Informatics-Hub/Germline-ShortV 
# 
# If you use this script towards a publication, support us by citing: 
# 
# Suggest citation: 
# Sydney Informatics Hub, Core Research Facilities, University of Sydney, 
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>, 
# https://github.com/Sydney-Informatics-Hub/Germline-ShortV 
# 
# Please acknowledge the Sydney Informatics Hub and the facilities: 
# 
# Suggested acknowledgement: 
# The authors acknowledge the technical assistance provided by the Sydney 
# Informatics Hub, a Core Research Facility of the University of Sydney 
# and the Australian BioCommons which is enabled by NCRIS via Bioplatforms 
# Australia. The authors acknowledge the use of the National Computational 
# Infrastructure (NCI) supported by the Australian Government. 
# 
#########################################################

config=''

if [ -z "${config}" ]
then
        if [ -z "$1" ]
        then
                echo "Please run this script with the path to your <cohort>.config e.g. sh gatk4_hc_make_input.sh ../cohort.config"
                exit
        else
                config=$1
        fi
fi
cohort=$(basename $config | cut -d'.' -f1)
vcfdir=../GATK4_HC
outdir=../GATK4_GVCFs$run_num
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
logdir=./Logs/GATK4_GatherVCFs$run_num
errdir=./Logs/GATK4_GatherVCFs_error_capture$run_num
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_gathervcfs_missing${run_num}.inputs

rm -rf ${inputfile}

num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

# Collect sample IDs from config file
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ! ${labid} =~ -T.*$ && ! ${labid} =~ -P.*$ && ! ${labid} =~ -M.*$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Checking GATK 4 GatherVcfs job for samples: ${#samples[@]}"
echo "$(date): Samples: ${samples[@]}"

# For each sample, check intervals with no .vcf and .vcf.idx files
i=0
for sample in "${samples[@]}"; do
	vcf=${outdir}/${sample}.g.vcf.gz
	tbi=${outdir}/${sample}.g.vcf.gz.tbi
        args=${INPUTS}/gatk4_gathervcfs_${sample}\.args
	err=${errdir}/${sample}.err
	if ! [[ -s "${vcf}" &&  -s "${tbi}" ]]; then
		echo "$(date): ${sample} ${vcf} or ${tbi} is missing or empty. Writing task to input file."
		for interval in $(seq -f "%04g" 0 $((${num_int}-1))); do
                	echo "--I " ${vcfdir}/${sample}/${sample}.${interval}.vcf >> ${args}
        	done
        	echo "${sample},${args},${logdir},${vcf},${errdir}" >> ${inputfile}
		((++i))
	elif [ -s "${err}" ]; then
		echo "$(date): Error detected. See $err and investigate. Writing task to input file."
		for interval in $(seq -f "%04g" 0 $((${num_int}-1))); do
                        echo "--I " ${vcfdir}/${sample}/${sample}.${interval}.vcf >> ${args}
                done
                echo "${sample},${args},${logdir},${vcf},${errdir}" >> ${inputfile}
		((++i))
	fi
done

if [ $i ]
then
	echo "$(date): All GVCF and index files present for samples in $config"
else
	echo "$(date): $i samples had errors. Please investigate errors and run gatk4_gathervcfs_missing_run_parallel.pbs"
fi
