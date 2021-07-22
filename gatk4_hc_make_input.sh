
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

# Can include run_num to manage input and log files for benchmarking
# Otherwise, hash out
# run_num=_15

cohort=$(basename $config | cut -d'.' -f1)
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
	echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
	exit
fi
bamdir=../Final_bams
out=../GATK4_HC$run_num
logs=./Logs/GATK4_HC$run_num
errs=./Logs/GATK4_HC_error_capture$run_num
logdir=''
errdir=''
outdir=''
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_hc$run_num.inputs

rm -rf ${inputfile}

mkdir -p ${INPUTS}

# Collect sample IDs from samples.config
# Ignore tumour samples identified by -T, -P or -M appended to labid
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ! ${labid} =~ -T.*$ && ! ${labid} =~ -P.*$ && ! ${labid} =~ -M.*$ ]]; then
		samples+=("${labid}")
		logdir="${logs}/${labid}"
		errdir="${errs}/${labid}"
		outdir="${out}/${labid}"
		mkdir -p ${logdir} ${errdir} ${outdir}
	fi
done < "${config}"

echo "$(date): Writing inputs for gatk4_hc_run_parallel.pbs for ${#samples[@]} samples to ${INPUTS}/gatk4_hc.inputs"
echo "$(date): Ignoring "LabSampleID" suffixed with "-T", "-P", "-M""
echo "$(date): Samples found include ${samples[@]}"

# Write gatk4_hc.inputs file
# Write using order of intervals listed in list file
while IFS= read -r intfile; do
	#printf "%s\n" "${samples[@]}" | xargs -i -n 1 -P 48 echo $ref,{},${bamdir}/{}.final.bam,${scatterdir}/${intfile},${outdir}/{},${logs}/{},${errdir} >> ${inputfile}
        for sample in "${samples[@]}"; do
                bam=${bamdir}/${sample}.final.bam
		logdir="${logs}/${sample}"
		errdir="${errs}/${sample}"
		outdir="${out}/${sample}"
                interval="${scatterdir}/${intfile}"
                echo "${ref},${sample},${bam},${interval},${outdir},${logdir},${errdir}" >> ${inputfile}
        done
done < "${scatterlist}"

#ncpus=$(( ${#samples[@]}*2*48 ))
#mem=$(( ${#samples[@]}*2*190 ))
num_tasks=`wc -l $inputfile | cut -d' ' -f 1`

echo "$(date): Number of samples: ${#samples[@]}"
echo "$(date): Number of tasks in $inputfile: $num_tasks"
# echo "$(date): Recommended compute to request in gatk4_hc_run_parallel.pbs: walltime=02:00:00,ncpus=${ncpus},mem=${mem}GB,wd"
