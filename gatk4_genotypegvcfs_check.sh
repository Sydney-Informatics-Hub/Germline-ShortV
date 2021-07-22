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
run_num=_1

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
inputfile=${INPUTS}/gatk4_genotypegvcfs_missing$run_num.inputs
perlreport=${logdir}/GATK_duration_memory.txt
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

sample_map=${INPUTS}/${cohort}.sample_map

mkdir -p ${INPUTS} ${outdir} ${logdir} ${errdir}

rm -rf ${INPUTS}/gatk4_genotypegvcfs_missing.inputs
rm -rf ${perlfile}

# Run perl script to get duration
echo "$(date): Checking log files for errors, obtaining duration and memory usage per task..."
`perl gatk4_duration_mem.pl ${logdir}`

for interval in $(seq -f "%04g" 0 $((${num_int}-1)))
do
        duration=$(grep ${interval}.log $perlreport | awk '{print $2}')
        memory=$(grep ${interval}.log $perlreport |  awk '{print $3}')
        if [[ ! -s ${outdir}/${cohort}.${interval}.vcf.gz || ! -s ${outdir}/${cohort}.${interval}.vcf.gz.tbi ]] 
	then
		echo "Output ${outdir}/${cohort}.${interval}.vcf.gz ${outdir}/${cohort}.${interval}.vcf.gz.tbi empty or non-existant. Writing to ${inputfile}"
		redo+=("$interval")
	elif [[ $duration =~ NA || $memory =~ NA ]]
        then
                redo+=("$interval")
        elif [ -s "${err}" ]
        then
		echo "Error found, please investigate ${errdir}. Writing to ${inputfile}"
                redo+=("$interval")
        elif [ ! "${duration}" ]
        then
                echo "No log file found: ${interval}.log. Writing to ${inputfile}"
                redo+=("$interval")
        fi
done < "$perlreport"

if [[ ${#redo[@]}>1 ]]
then
	echo "$(date): There are ${#redo[@]} intervals that need to be re-run."
	echo "$(date): Writing inputs to ${inputfile}"
	for redo_interval in ${redo[@]};do
		interval="${scatterdir}/${redo_interval}-scattered.interval_list"
		echo "${ref},${cohort},${interval},${gendbdir},${outdir},${logdir},${errdir}" >> ${inputfile}
	done
else
	echo "$(date): There are no intervals that need to be re-run."
	#cd ${logs}
	#tar --remove-files \
	#	-czvf genotypegvcfs_logs.tar.gz \
	#	*.oe
fi
