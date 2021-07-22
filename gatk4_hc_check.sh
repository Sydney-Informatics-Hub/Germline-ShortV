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

config=$1
cohort=$(basename $config | cut -d'.' -f1)
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
bamdir=../Final_bams
out=../GATK4_HC
logs=./Logs/GATK4_HC
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_hc_missing.inputs
errs=./Logs/GATK4_HC_error_capture

rm -rf ${inputfile}

# Number of intervals
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B)
while read -r sampleid labid seq_center library; do
        if [[ ! -z ${sampleid} && ! ${sampleid} =~ ^#.*$ && ! ${labid} =~ -T.*$ && ! ${labid} =~ -P.*$ && ! ${labid} =~ -M.*$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Checking GATK 4 HaplotypeCaller job for samples: ${#samples[@]}"
echo "$(date): Samples: ${samples[@]}"

# For each sample, check intervals with no .vcf and .vcf.idx files
for sample in "${samples[@]}"; do
        # Check if .vcf and .vcf.idx files exist and are not empty
        i=0
        for interval in $(seq -f "%04g" 0 $((${num_int}-1))); do
                logdir=${logs}/${sample}
		errdir=${errs}/${sample}
		logfile=${logdir}/${interval}.log
		errfile=${errdir}/${sample}.${index}.err
                outdir=${out}/${sample}
		vcf=${outdir}/${sample}.${interval}.vcf
                idx=${outdir}/${sample}.${interval}.vcf.idx
                bam=${bamdir}/${sample}.final.bam
		if ! [[ -s "${vcf}" &&  -s "${idx}" ]]; then
                        intfile=$(grep ${interval} ${scatterlist})
                        echo "${ref},${sample},${bam},${scatterdir}/${intfile},${outdir},${logdir},${errdir}" >> ${inputfile}
                elif [ -s "${err}" ]; then
			echo "$(date): Error detected. See $err and investigate. Writing task to input file"
			intfile=$(grep ${interval} ${scatterlist})
			echo "${ref},${sample},${bam},${scatterdir}/${intfile},${outdir},${logdir},${errdir}" >> ${inputfile}
		else
                        ((++i))
                fi
        done

        if [[ $i == ${num_int} ]]; then
                echo "$(date): ${sample} has all vcf and vcf.idx present. Ready for merging into GVCF."
        else
                num_missing=$((${num_int} - $i))
                echo "$(date): ${sample} has ${num_missing} missing vcf or vcf.idx files."
                total_missing=$((${total_missing}+${num_missing}))
fi
done

if [[ ${total_missing} ]]; then
        echo "$(date): There are $total_missing vcf files in $config. Please run gatk4_hc_missing_run_parallel.pbs"
else
        echo "$(date): Found all vcf and idx files for samples in $config."
fi
