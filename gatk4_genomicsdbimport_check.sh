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

# run_num=_1

if [ -z "$1" ]
then
	echo "Please run this script with the path to your <cohort>.config e.g. sh gatk4_genomicsdbimport_check.sh <cohort>.config"
fi

config=$1
cohort=$(basename $config | cut -d'.' -f1)
INPUTS=./Inputs
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
sample_map=${INPUTS}/${cohort}.sample_map
vcfdir=../GATK4_GVCFs
outdir=../${cohort}_GenomicsDBImport$run_num
logdir=./Logs/GATK4_GenomicsDBImport$run_num
errdir=./Logs/GATK4_GenomicsDBImport_error_capture$run_num
perlreport=${logdir}/GATK_duration_memory.txt
inputfile=${INPUTS}/gatk4_genomicsdbimport_missing.inputs 

mkdir -p ${INPUTS} ${logdir} ${errdir} ${outdir}
rm -rf ${inputfile} ${perlreport}

# Run perl script to get duration
echo "$(date): Checking log files for errors, obtaining duration and memory usage per task..."
`perl gatk4_duration_mem.pl $logdir`

num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

for interval in $(seq -f "%04g" 0 $((${num_int}-1)))
do
	duration=$(grep ${interval}.log $perlreport | awk '{print $2}')
	memory=$(grep ${interval}.log $perlreport |  awk '{print $3}')
	if [ ! -d ${outdir}/$interval ]
	then
		redo+=("$interval")
	elif [[ $duration =~ NA || $memory =~ NA ]]
	then
		redo+=("$interval")
	elif [ -s "${err}" ]
	then
		redo+=("$interval")
	elif [ ! "${duration}" ]
	then
		echo "No duration reported in log, indicating error: ${interval}.log. Writing to ${inputfile}"
		redo+=("$interval")
	fi
done < "$perlreport"

if [[ ${#redo[@]}>1 ]]
then
	echo "$(date): There are ${#redo[@]} intervals that need to be re-run."
	echo "$(date): Writing inputs to ${INPUTS}/gatk4_genomicsdbimport_missing.inputs"

	for redo_interval in ${redo[@]};do
        interval="${scatterdir}/${redo_interval}-scattered.interval_list"
        echo "${ref},${cohort},${interval},${sample_map},${outdir},${logdir},${errdir}" >> ${inputfile}
done
else
	echo "$(date): GenomicsDBImport completed successfully"
fi
