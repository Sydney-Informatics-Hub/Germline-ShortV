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

#PBS -P <project>
#PBS -N vqsr
#PBS -l walltime=00:00:00,ncpus=,mem=GB,wd
#PBS -q normal
#PBS -W umask=022
#PBS -l storage=
#PBS -o ./Logs/gatk4_vqsr.o
#PBS -e ./Logs/gatk4_vqsr.e

set -e

module load gatk/4.1.8.1
module load R/3.6.1

config=/path/to/cohort.config
cohort=$(basename $config | cut -d'.' -f1)
INPUTS=./Inputs
vcfdir=../${cohort}_GenotypeGVCFs
vqsrdir=../$cohort\_VQSR_VCFs
logdir=./Logs/GATK4_VQSR
errdir=./Logs/GATK4_VQSR_error_capture
mergedvcf=${vcfdir}/${cohort}.sorted.vcf.gz

# Outputs
excesshet=${vqsrdir}/${cohort}_noexcesshet.vcf.gz
sitesonly=${vqsrdir}/${cohort}_noexcesshet_sitesonly.vcf.gz
indelRecal=${vqsrdir}/${cohort}\_indels.recal
indelTranches=${vqsrdir}/${cohort}\_indels.tranches
indelR=${vqsrdir}/${cohort}_indels.R
snpRecal=${vqsrdir}/${cohort}\_snps.recal
snpTranches=${vqsrdir}/${cohort}\_snps.tranches
snpR=${vqsrdir}/${cohort}_snps.R
indelvqsr=${vqsrdir}/${cohort}\.indelsonly.recalibrated.vcf.gz
finalvqsr=${vqsrdir}/${cohort}\.final.recalibrated.vcf.gz
metrics=${vqsrdir}/${cohort}\.final.recalibrated.metrics

# logfiles
logvarfilt=${logdir}/${cohort}_variant_filtration.log
logsitesonly=${logdir}/${cohort}_makesitesonly.log
logindel=${logdir}/${cohort}_indel_variantrecalibrator.log 
logsnp=${logdir}/${cohort}_snp_variantrecalibrator.log
logapplyindel=${logdir}/${cohort}_applyvqsr_indels.log 
logapplysnp=${logdir}/${cohort}_applyvqsr_indels_snps.log
logmetrics=${logdir}/${cohort}_variantmetrics.log
err=${errdir}/${cohort}.err

# Reference
dict=../Reference/hs38DH.dict
refdir=../Reference/broad-references/v0
mills=${refdir}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
axiomPoly=${refdir}/Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz
dbsnp=${refdir}/Homo_sapiens_assembly38.dbsnp138.vcf
hapmap=${refdir}/hapmap_3.3.hg38.vcf.gz
omni=${refdir}/1000G_omni2.5.hg38.vcf.gz
thousandg=${refdir}/1000G_phase1.snps.high_confidence.hg38.vcf.gz

mkdir -p ${vqsrdir} ${logdir} ${errdir}

# Filter sites with excess heterozygous genotypes
# ~0.81min/1000 intervals
gatk --java-options "-Xmx42g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" VariantFiltration \
	-V ${mergedvcf} \
	--filter-expression "ExcessHet > 54.69" \
	--filter-name ExcessHet \
	-O ${excesshet} >${logvarfilt} 2>&1

# Retain only variant sites
# ~0.95 min/1000 intervals
gatk MakeSitesOnlyVcf \
	-I ${excesshet} \
	-O ${sitesonly} >${logsitesonly} 2>&1

# Calculate VQSLOD tranches for indels using VariantRecalibrator. 
# ~6.40 minutes for 6 samples
gatk --java-options "-Xmx42g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" VariantRecalibrator \
	-V ${sitesonly} \
	--trust-all-polymorphic \
	-tranche 100.0 -tranche 99.95 -tranche 99.9 -tranche 99.5 -tranche 99.0 -tranche 97.0 -tranche 96.0 -tranche 95.0 -tranche 94.0 -tranche 93.5 -tranche 93.0 -tranche 92.0 -tranche 91.0 -tranche 90.0 \
	-an FS -an ReadPosRankSum -an MQRankSum -an QD -an SOR -an DP \
	-mode INDEL \
	--max-gaussians 4 \
	--rscript-file ${indelR} \
	-resource:mills,known=false,training=true,truth=true,prior=12 ${mills} \
	-resource:axiomPoly,known=false,training=true,truth=false,prior=10 ${axiomPoly} \
	-resource:dbsnp,known=true,training=false,truth=false,prior=2 ${dbsnp} \
	-O ${indelRecal} \
	--tranches-file ${indelTranches} >${logindel} 2>&1
	
# Calculate VQSLOD tranches for SNPs using VariantRecalibrator
gatk --java-options "-Xmx42g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" VariantRecalibrator \
	-V ${sitesonly} \
	--trust-all-polymorphic \
	-tranche 100.0 -tranche 99.95 -tranche 99.9 -tranche 99.8 -tranche 99.6 -tranche 99.5 -tranche 99.4 -tranche 99.3 -tranche 99.0 -tranche 98.0 -tranche 97.0 -tranche 90.0 \
	-an QD -an MQRankSum -an ReadPosRankSum -an FS -an MQ -an SOR -an DP \
	-mode SNP \
	--max-gaussians 6 \
	--rscript-file ${snpR} \
	-resource:hapmap,known=false,training=true,truth=true,prior=15 ${hapmap} \
	-resource:omni,known=false,training=true,truth=true,prior=12 ${omni} \
	-resource:1000G,known=false,training=true,truth=false,prior=10 ${thousandg} \
	-resource:dbsnp,known=true,training=false,truth=false,prior=7 ${dbsnp} \
	-O ${snpRecal} \
	--tranches-file ${snpTranches} >${logsnp} 2>&1

# Indels: Calculate VQSLOD using ApplyVQSR
gatk --java-options "-Xmx42g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" \
	ApplyVQSR \
	-V ${excesshet} \
	--recal-file ${indelRecal} \
	--tranches-file ${indelTranches} \
	--truth-sensitivity-filter-level 99.7 \
	--create-output-variant-index true \
	-mode INDEL \
	-O ${indelvqsr} >${logapplyindel} 2>&1

# SNPs: Calculate VQSLOD using ApplyVQSR
gatk --java-options "-Xmx42g -XX:ParallelGCThreads=${NCPUS} -Djava.io.tmpdir=${PBS_JOBFS}" \
	ApplyVQSR \
	-V ${indelvqsr} \
	--recal-file ${snpRecal} \
	--tranches-file ${snpTranches} \
	--truth-sensitivity-filter-level 99.7 \
	--create-output-variant-index true \
	-mode SNP \
	--create-output-variant-md5 \
	-O ${finalvqsr} >${logapplysnp} 2>&1

# Evaluate the filtered callset, compare with known population callset
gatk CollectVariantCallingMetrics \
	-I ${finalvqsr} \
	--DBSNP ${dbsnp} \
	-SD ${dict} \
	-O ${metrics} >${logmetrics} 2>&1

# Perform error checking for each step
# Check logs for GATK errors
if grep -q -i error ${logdir}/*.log
then
        printf "Error in GATK logs:\n"  >> $err
	grep -l -i "error" ${logdir}/*log >> $err
fi

if grep -q Exception ${logdir}/*log
then
        printf "Exception in GATK log" >> $err
	grep -l -i Exception ${logdir}/*log >> $err
fi
