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

if [ -z "$1" ]
then
	echo "Please run this script with the path to your <cohort>.config e.g. sh gatk4_genomicsdbimport_make_input.sh ../<cohort>.config"
fi

# Can include run_num to manage input and log files for benchmarking
# Otherwise, hash out
# run_num=_7

config=$1
cohort=$(basename $config | cut -d'.' -f1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_genomicsdbimport$run_num.inputs
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
sample_map=${INPUTS}/${cohort}.sample_map
vcfdir=../GATK4_GVCFs
outdir=../$cohort\_GenomicsDBImport$run_num
logdir=./Logs/GATK4_GenomicsDBImport$run_num
errdir=./Logs/GATK4_GenomicsDBImport_error_capture$run_num

num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

mkdir -p ${INPUTS} ${logdir} ${errdir} ${outdir}

rm -rf ${inputfile}
rm -rf ${sample_map}

# Collect sample IDs from config file
# Only collect IDs for germline variant calling (labids not ending in -T, -P or -M)
while read -r sampleid labid seq_center library; do
	if [[ ! -z ${sampleid} && ! ${sampleid} =~ ^#.*$ && ! ${labid} =~ -T.*$ && ! ${labid} =~ -P.*$ && ! ${labid} =~ -M.*$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Number of samples: ${#samples[@]}. Creating arguments for each sample for ${num_int} genomic intervals"
echo "$(date): GenomicsDBImport interval databases will be written to $outdir"

for sample in "${samples[@]}"; do
	echo -e "${sample}	${vcfdir}/${sample}.g.vcf.gz" >> ${sample_map}
done

# Loop through intervals in scatterlist file
# Print to ${INPUTS}
while IFS= read -r intfile; do
	interval="${scatterdir}/${intfile}"
	echo "${ref},${cohort},${interval},${sample_map},${outdir},${logdir},${errdir}" >> ${inputfile}
done < "${scatterlist}"
