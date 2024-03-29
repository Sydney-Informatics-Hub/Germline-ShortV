#!/bin/bash

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

ref=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
bam=`echo $1 | cut -d ',' -f 3`
interval=`echo $1 | cut -d ',' -f 4`
outdir=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`
errdir=`echo $1 | cut -d ',' -f 7`
filename=${interval##*/}
index=${filename%-scattered.interval_list}
vcf=${outdir}/${sample}.${index}.vcf
err=${errdir}/${sample}.${index}.err
log=${logdir}/${index}.log
rm -rf $err

# For PCR-free libraries it is recommended to include -pcr_indel_model NONE
# GATK can output zipped files but there is a but that doesn't index zipped files
# XX:ParallelGCThreads=${NCPUS} tested, comparing with -XX:+UseSerialGC 
gatk --java-options "-Xmx8g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" \
	HaplotypeCaller \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	-O ${vcf} \
	--pcr-indel-model NONE \
	-G StandardAnnotation \
	-G AS_StandardAnnotation \
	-G StandardHCAnnotation \
	--native-pair-hmm-threads ${NCPUS} \
	-ERC GVCF 2>${logdir}/${index}.log

# Check logs for GATK errors
if grep -q -i error $log
then
        printf "Error in GATK log ${log}\n" >> $err
fi

if grep -q Exception $log
then
        printf "Exception in GATK log ${log}\n" >> $err
fi

