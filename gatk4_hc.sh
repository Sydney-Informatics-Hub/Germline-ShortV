#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Runs GATK4 HaplotypeCaller with
# gatk4_hc_run_parallel.pbs
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 24/02/2021
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested citation:
# Sydney Informatics Hub, Core Research Facilities, University of Sydney,
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>,
# https://github.com/Sydney-Informatics-Hub/Bioinformatics
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#
#########################################################

ref=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
bam=`echo $1 | cut -d ',' -f 3`
interval=`echo $1 | cut -d ',' -f 4`
out=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`

mkdir -p ${out}
mkdir -p ${logdir}

filename=${interval##*/}
index=${filename%-scattered.interval_list}

gvcf=${out}/${sample}.${index}.vcf

echo "$(date) : Start GATK 4 HaplotypeCaller. Reference: ${ref}; Sample: ${sample}; Bam: ${bam}; Interval: ${filename}; Threads: ${NCPUS}; Logs: ${logdir}" >> ${logdir}/${index}.oe

# For PCR-free libraries it is recommended to include -pcr_indel_model NONE
# The next version will automatically set this option for you through ../<cohort>.config file 

gatk --java-options "-Xmx8g -Xms8g" \
	HaplotypeCaller \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	-O ${gvcf} \
	-G StandardAnnotation \
	-G AS_StandardAnnotation \
	-G StandardHCAnnotation \
	--native-pair-hmm-threads ${NCPUS} \
	-ERC GVCF 2>>${logdir}/${index}.oe 

echo "$(date) : Finished GATK 4 Haplotype Caller for: ${gvcf}" >> ${logdir}/${index}.oe
