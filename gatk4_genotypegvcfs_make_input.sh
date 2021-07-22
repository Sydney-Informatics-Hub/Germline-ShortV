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
        echo "Please run this script with the path to your <cohort>.config e.g. sh gatk4_genotypegvcfs_make_input.sh ../cohort.config"
        exit
fi

# Can include run_num to manage input and log files for benchmarking
# Otherwise, hash out
# run_num=_4

config=$1
cohort=$(basename $config | cut -d'.' -f1)
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
gendbdir=../$cohort\_GenomicsDBImport
outdir=../$cohort\_GenotypeGVCFs$run_num
logdir=./Logs/GATK4_GenotypeGVCFs$run_num
errdir=./Logs/GATK4_GenotypeGVCFs_error_capture$run_num
sample_map=${INPUTS}/${cohort}.sample_map
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_genotypegvcfs$run_num.inputs
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

mkdir -p ${INPUTS} ${outdir} ${logdir} ${errdir}
rm -rf ${inputfile}

echo "$(date): Creating inputs for ${num_int} genomic intervals."
echo "$(date): GenotypeGVCF output will be written to ${outdir}"

while IFS= read -r intfile; do
	interval="${scatterdir}/${intfile}"
	echo "${ref},${cohort},${interval},${gendbdir},${outdir},${logdir},${errdir}" >> ${inputfile}
done < "${scatterlist}"
