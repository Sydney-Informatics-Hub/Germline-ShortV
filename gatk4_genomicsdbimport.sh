#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Consolidate interval VCFs across multiple 
# samples for GenotypeGVCFs (joint-calling)
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

echo "$(date) : Start GATK 4 GenomicsDBImport. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}; Sample map: ${sample_map}; Out: ${out}; Logs: ${logdir}; Threads: ${nt}" >${logdir}/${index}.oe 2>&1 

# Doesn't work when working in different directories...
#mkdir -p ${out}
#cd ${out}

gatk --java-options "-Xmx40g -Xms40g" \
	GenomicsDBImport \
	--sample-name-map ${sample_map} \
	--overwrite-existing-genomicsdb-workspace \
	--genomicsdb-workspace-path ${out} \
	--tmp-dir ${tmp} \
	--reader-threads ${nt} \
	--intervals ${interval} >>${logdir}/${index}.oe 2>&1 

echo "$(date) : Finished GATK 4 consolidate VCFs with GenomicsDBImport for: ${out}" >>${logdir}/${index}.oe 2>&1

#Caveats
#IMPORTANT: The -Xmx value the tool is run with should be less than the total amount of physical memory available by at least a few GB, as the native TileDB library #requires additional memory on top of the Java memory. Failure to leave enough memory for the native code can result in confusing error messages!
#At least one interval must be provided
#Input GVCFs cannot contain multiple entries for a single genomic position
#The --genomicsdb-workspace-path must point to a non-existent or empty directory.
#GenomicsDBImport uses temporary disk storage during import. The amount of temporary disk storage required can exceed the space available, especially when specifying a #large number of intervals. The command line argument `--tmp-dir` can be used to specify an alternate temporary storage location with sufficient space..
