#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Runs gatk4 GenomicsDBImport with
# gatk4_genomicsdbimport_missing_run_parallel.pbs
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

module load gatk/4.1.2.0

ref=`echo $1 | cut -d ',' -f 1`
cohort=`echo $1 | cut -d ',' -f 2`
interval=`echo $1 | cut -d ',' -f 3`
sample_map=`echo $1 | cut -d ',' -f 4`
outdir=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`
nt=`echo $1 | cut -d ',' -f 7`

filename=${interval##*/}
index=${filename%-scattered.interval_list}

# out must be an empty of non-existant directory
# --overwrite-existing-genomicsdb-workspace doesn't work so has to be done this way
out=${outdir}/${index}
tmp=${outdir}/tmp/${index}

rm -rf ${out}
rm -rf ${tmp}

mkdir -p ${outdir}
mkdir -p ${tmp}
mkdir -p ${logdir}

echo "$(date) : Start GATK 4 GenomicsDBImport. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}; Sample map: ${sample_map}; Out: ${out}; Logs: ${logdir}; Threads: ${nt}" 2>${logdir}/${index}.e

# Doesn't work when working in different directories...
#mkdir -p ${out}
#cd ${out}

gatk --java-options "-Xmx360g -Xms360g" \
	GenomicsDBImport \
	--sample-name-map ${sample_map} \
	--overwrite-existing-genomicsdb-workspace \
	--genomicsdb-workspace-path ${out} \
	--tmp-dir ${tmp} \
	--reader-threads ${nt} \
	--intervals ${interval} 2>>${logdir}/${index}.e

echo "$(date) : Finished GATK 4 consolidate VCFs with GenomicsDBImport for: ${out}"
