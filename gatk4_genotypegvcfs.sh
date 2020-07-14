#!/bin/bash

# -all-sites option does not work and give any output 
# GATK4 uses gnomAD variants, not dbSNP variants
# No threading option

module load gatk/4.1.2.0
module load samtools/1.10

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
# --interval-padding - but genomicsdbimport needs to include padded sites
# --include-non-variant-sites : up to the researcher
# --dbsnp
