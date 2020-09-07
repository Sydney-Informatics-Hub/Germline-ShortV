#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: 
# Checks gatk_hc logs for a sample
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

module load parallel/20191022

echo "Checking sample: ${sample}, input: ${input}. Writing to ${logs}"

rm -rf ${logs}/${sample}_errors.txt
rm -rf ${logs}/${sample}_task_duration.txt

# Check for errors in parallel
parallel -j ${NCPUS} --col-sep ',' "grep -i '"error"' {3}" :::: ${input} >> ${logs}/${sample}_errors.txt

# Get elapsed time
perl ${perl} ${logs}/${sample} >> ${logs}/${sample}_task_duration.txt
#parallel -j 1 grep -oP '"Elapsed time: [0-9]+\.[0-9]+"' :::: ${logs}
#parallel -j ${NCPUS}  --colsep ',' "printf "{1}," && printf "{2}," && grep -oP '"Elapsed time: [0-9]+\.[0-9]+"' {3}" :::: ${input} >> ${logs}/${sample}_task_duration.txt

# Tar log directory if no errors were found
if ! [[ -s "${logs}/${sample}_errors.txt" ]]
then
	cd ${logs}
	#mv ${sample}_errors.txt ${sample}
	tar -czvf ${sample}_logs.tar.gz ${sample}
	# no --remove-files. I wish to remove logs manully.
fi

