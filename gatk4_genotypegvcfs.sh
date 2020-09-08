#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Jointly genotype samples with GenotypeGVCFs
# Used by gatk4_genotypegvcfs_run_parallel.pbs script and 
# operates on one genomic interval per task
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


# -all-sites option does not work and give any output 
# GATK4 uses gnomAD variants, not dbSNP variants
# No threading option

module load gatk/4.1.2.0

ref=`echo $1 | cut -d ',' -f 1`
cohort=`echo $1 | cut -d ',' -f 2`
interval=`echo $1 | cut -d ',' -f 3`
gendbdir=`echo $1 | cut -d ',' -f 4`
outdir=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`
nt=`echo $1 | cut -d ',' -f 7`

filename=${interval##*/}
index=${filename%-scattered.interval_list}

out=${outdir}/${cohort}.${index}.vcf.gz
tmp=${outdir}/tmp/${index}

mkdir -p ${outdir}
mkdir -p ${tmp}

echo "$(date) : Start GATK 4 GenotypeGVCFs. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}; GenomicsDBImport: ${gendbdir}; Out: ${out}; Logs: ${logdir}; Threads: ${nt}" >${logdir}/${index}.oe 2>&1


gatk --java-options "-Xmx28g -Xms28g" \
	GenotypeGVCFs \
	-R ${ref} \
	-V gendb://${gendbdir}/${index} \
	--tmp-dir ${tmp} \
	-O ${out} >>${logdir}/${index}.oe 2>&1

echo "$(date) : Finished GATK 4 joing genotyping with GenotypeGVCFs for: ${out}" >>${logdir}/${index}.oe 2>&1


## Options to explore
# --sample-ploidy,-ploidy:Integer : for different sex chromosomes, Mt
# --include-non-variant-sites : up to the researcher
# --dbsnp
