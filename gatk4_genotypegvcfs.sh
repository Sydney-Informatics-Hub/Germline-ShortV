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


# -all-sites option does not work and give any output 
# GATK4 uses gnomAD variants, not dbSNP variants
# No threading option

ref=`echo $1 | cut -d ',' -f 1`
cohort=`echo $1 | cut -d ',' -f 2`
interval=`echo $1 | cut -d ',' -f 3`
gendbdir=`echo $1 | cut -d ',' -f 4`
outdir=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`
errdir=`echo $1 | cut -d ',' -f 7`

filename=${interval##*/}
index=${filename%-scattered.interval_list}

out=${outdir}/${cohort}.${index}.vcf.gz
tmp=${PBS_JOBFS}/tmp/${index}
err=${errdir}/${index}.err

mkdir -p ${tmp}
rm -rf ${err}
cp -r ${gendbdir}/${index}/ $tmp/

echo "$(date) : Start GATK 4 GenotypeGVCFs. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}; GenomicsDBImport: ${gendbdir}; Out: ${out}; Logs: ${logdir}; Threads: ${NCPUS}" >${logdir}/${index}.log 2>&1

gatk --java-options "-Xmx28g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" \
	GenotypeGVCFs \
	-R ${ref} \
	-V gendb://${tmp}/${index} \
	--tmp-dir ${tmp} \
	-O ${out} >>${logdir}/${index}.log 2>&1

# Check logs for GATK errors
if grep -q -i error $log
then
        printf "Error in GATK log ${log}\n" >> $err
fi

if grep -q Exception $log
then
        printf "Exception in GATK log ${log}\n" >> $err
fi


## Options to explore
# --sample-ploidy,-ploidy:Integer : for different sex chromosomes, Mt
# --include-non-variant-sites : up to the researcher
# --dbsnp
