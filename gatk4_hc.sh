#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Runs gatk4 HaplotypeCaller with
# gatk4_hc_run_parallel.pbs
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 17/08/2020
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#
#########################################################

# Run GATK HC using scatter-gather method

module load gatk/4.1.2.0
module load samtools/1.10

ref=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
bam=`echo $1 | cut -d ',' -f 3`
interval=`echo $1 | cut -d ',' -f 4`
out=`echo $1 | cut -d ',' -f 5`
nt=`echo $1 | cut -d ',' -f 6`
logdir=`echo $1 | cut -d ',' -f 7`

mkdir -p ${out}
mkdir -p ${logdir}

filename=${interval##*/}
index=${filename%-scattered.interval_list}

gvcf=${out}/${sample}.${index}.vcf

echo "$(date) : Start GATK 4 HaplotypeCaller. Reference: ${ref}; Sample: ${sample}; Bam: ${bam}; Interval: ${filename}; Threads: ${nt}; Logs: ${logdir}" >> ${logdir}/${index}.oe

gatk --java-options "-Xmx8g -Xms8g" \
	HaplotypeCaller \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	-O ${gvcf} \
	-G StandardAnnotation \
	-G AS_StandardAnnotation \
	-G StandardHCAnnotation \
	--native-pair-hmm-threads ${nt} \
	-ERC GVCF 2>>${logdir}/${index}.oe 

echo "$(date) : Finished GATK 4 Haplotype Caller for: ${gvcf}" >> ${logdir}/${index}.oe
