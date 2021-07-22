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

# Unhash and use to manage inputs/outputs for benchmarking
run_num=_4

set -e

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
inputfile=${INPUTS}/gatk4_gathervcfs${run_num}.inputs

num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

# Collect sample IDs from config file
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ! ${labid} =~ -T.*$ && ! ${labid} =~ -P.*$ && ! ${labid} =~ -M.*$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Number of samples: ${#samples[@]}. Creating arguments for each sample for ${num_int} genomic intervals"

mkdir -p ${outdir} ${logdir} ${errdir} ${INPUTS}
rm -rf ${inputfile}

# Make arguments file for each sample, then add to inputs file
for sample in "${samples[@]}"; do
	
	args=${INPUTS}/gatk4_gathervcfs_${sample}\.args
	out=${outdir}/${sample}.g.vcf.gz

	rm -rf ${args}
	
	for interval in $(seq -f "%04g" 0 $((${num_int}-1))); do
		echo "--I " ${vcfdir}/${sample}/${sample}.${interval}.vcf >> ${args}
	done
	echo "${sample},${args},${logdir},${out},${errdir}" >> ${inputfile}
done

num_tasks=`wc -l $inputfile | cut -d' ' -f 1`

echo "$(date): GatherGVCFs will gather interval VCFs and write sample.g.vcf.gz to ${outdir}"
echo "$(date): Number of tasks in $inputfile: $num_tasks"


