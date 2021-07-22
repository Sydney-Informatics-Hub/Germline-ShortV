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
cohort=`echo $1 | cut -d ',' -f 2`
interval=`echo $1 | cut -d ',' -f 3`
sample_map=`echo $1 | cut -d ',' -f 4`
outdir=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`
errdir=`echo $1 | cut -d ',' -f 7`

filename=${interval##*/}
index=${filename%-scattered.interval_list}

# out must be an empty of non-existant directory
# --overwrite-existing-genomicsdb-workspace doesn't work so has to be done this way
out=${outdir}/${index}
tmp=${PBS_JOBFS}/tmp/${index}
err=${errdir}/${index}.err
logfile=${logdir}/${index}.log

rm -rf ${out} ${tmp}
mkdir -p ${outdir} ${tmp} ${logdir}

echo "$(date) : Start GATK 4 GenomicsDBImport. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}; Sample map: ${sample_map}; Out: ${out}; Logs: ${logdir}; Threads: ${NCPUS}" >${logfile} 2>&1 

gatk --java-options "-Xmx58g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" \
	GenomicsDBImport \
	--sample-name-map ${sample_map} \
	--overwrite-existing-genomicsdb-workspace \
	--genomicsdb-workspace-path ${out} \
	--tmp-dir ${tmp} \
	--reader-threads ${NCPUS} \
	--intervals ${interval} >>${logfile} 2>&1 

# Check logs for GATK errors
if grep -q -i error $logfile
then
        printf "Error in GATK log ${logfile}\n" >> $err
fi

if grep -q Exception $logfile
then
        printf "Exception in GATK log ${logfile}\n" >> $err
fi

#Caveats
#IMPORTANT: The -Xmx value the tool is run with should be less than the total amount of physical memory available by at least a few GB, as the native TileDB library #requires additional memory on top of the Java memory. Failure to leave enough memory for the native code can result in confusing error messages!
#At least one interval must be provided
#Input GVCFs cannot contain multiple entries for a single genomic position
#The --genomicsdb-workspace-path must point to a non-existent or empty directory.
#GenomicsDBImport uses temporary disk storage during import. The amount of temporary disk storage required can exceed the space available, especially when specifying a #large number of intervals. The command line argument `--tmp-dir` can be used to specify an alternate temporary storage location with sufficient space..
