# Germline-ShortV
<img src="https://user-images.githubusercontent.com/49257820/87390949-2b253080-c5ed-11ea-83a2-b559c0c4df2e.png" width="50%" height="50%">

# Quickstart

This quickstart is not for first timers. :)

The following will perform germline short variant calling for all samples present in `../<cohort>.config`. Once you're set up (see the guide below), change into the `Germline-ShortV` directory after cloning this repository. The scripts use relative paths and the `Germline-ShortV` is your working directory. Adjust compute resources requested in the `.pbs` files using the guide provided in each of the parallel scripts. This will often be according to the number of samples in `../<cohort>.config`.

1. Run HaplotypeCaller by:
  * `sh gatk4_hc_make_input.sh <cohort>`
  * `qsub gatk4_hc_run_parallel.pbs`
2. Check all interval .vcf and .vcf.idx files are present, check per sample task duration, check for errors in log files and archive logs by:
  * `sh gatk4_hc_missing_make_input.sh <cohort>`. Re-run this script, check cause of errors until there are 0 missing vcf files.
  * `qsub gatk4_hc_missing_run_parallel.pbs`. Run this if there were missing vcf files.
  * `sh gatk4_hc_checklogs_make_input.sh <cohort>`
  * `sh gatk4_hc_checklogs_run_parallel.sh`
3. Merge haplotype caller per interval vcfs by:
  * `sh gatk4_hc_gathervcfs_make_input.sh <cohort>`
  * `qsub gatk4_hc_gathervcfs_run_parallel.pbs`
4. Backup GVCFs
5. Consolidate interval VCFs using GATK’s GenomicsDBImport by:
  * `sh gatk4_genomicsdbimport_make_input.sh <cohort>`
  * `qsub gatk4_genomicsdbimport_run_parallel.pbs`
6. Check interval GenomicsDBImport databases are present, check log files, check interval duration, check Runtime.totalMemory(), re-run tasks that failed
  * `sh gatk4_genomicsdbimport_missing_make_input.sh <cohort>`. Re-run this script until there are 0 intervals that need to be re-run. 
  * `qsub gatk4_genomicsdbimport_missing_run_parallel.pbs`. Run this if there are intervals that need to be run.
7. Perform joint calling using GATK's GenotypeGVCFs by:
  * `sh gatk4_genotypegvcfs_make_input.sh <cohort>`
  * `qsub gatk4_genotypegvcfs_run_parallel.pbs`
8. Check interval VCFs made by GenotypeGVCFs. Check for errors in logs, print duration, Runtime.totalMemory() per interval, re-run tasks that failed
  * `sh gatk4_genotypegvcfs_missing_make_input.sh <cohort>`
  * `qsub gatk4_genotypegvcfs_missing_run_parallel.pbs`
9. Gather joint-genotyped interval VCFs into a multisample GVCF. 
  * `qsub gatk4_gather_sort_vcfs.pbs`
10. Run Variant Quality Score Recalibration (VQSR) by:
  *   * Change cohort=<cohort>
  * `qsub gatk4_vqsr.pbs`
  * Check `<cohort>.recalibrated.metrics.variant_calling_detail_metrics`
11. Back up cohort, genotyped, recalibrated GVCFs and varaint calling metrics 

# Description

The Germline-ShortV workflow implements GATK 4’s Best Practices for Germline short variant discovery (SNPs + indels) in a scatter-gather fashion on NCI Gadi. This workflow requires sample BAM files, which can be obtained from the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. Optimisations for scalability and parallelization have been performed on the human reference genome GRCh38/hg38 + ALT contigs. Germline-ShortV can be applied to other model and non-model organisms (including non-diploid organisms), with some modifications as described below. 

## Human datasets

There are six PBS jobs included in Germline-ShortV for samples which have been aligned to the human reference genome (GRCh38/hg38 + ALT contigs) using the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. The first job “HaplotypeCaller” calls raw SNPs and indels at 3,200 evenly-sized genomic intervals and multiple samples in parallel. “GatherVCFs” gathers per interval VCF files into per sample GVCF files, operating at multiple samples in parallel. We recommend backing up per sample GVCFs into the University of Sydney’s Research Data Store or similar. The sample GVCFs can be included in “Joint-calling” jobs in future projects as more samples are sequenced and are included in your cohort, saving compute resources. 

“Joint calling” includes three PBS jobs and commences with multiple per sample GVCF files generated from the two jobs in “Variant calling”. The job “GenomicsDBImport” consolidates sample GVCFs into databases and “GenotypeGVCFs” joint-calls variants at the pre-defined 3,200 genomic intervals in parallel. The resulting multiple-sample VCFs obtained for 3,200 intervals are then gathered with GatherVCFs to obtain a single cohort VCF file. Variants in the cohort VCF file are filtered and refined, first by removing sites with excess heterozygosity (indicative of technical artefacts). GATK’s variant quality score recalibration (VQSR) methods including the tools VariantRecalibrator and ApplyVQSR are then applied to SNPs and indels separately. VQSR is a machine learning method that uses high quality variant resources (1000 Genomes, omni, hapmap) as a training set to profile properties of probable true variants from technical artefacts. Variant calling metrics are then obtained from the Analysis ready cohort VCFs containing SNPs and indels. These files should be backed up before proceeding with downstream analysis. 

# Set up

## GRCh38/hg38 + ALT contigs

The Germline-ShortV pipeline works seamlessly with the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. The scripts use relative paths, so correct set-up is important. 

Upon completion of [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM):

1. Change to the working directory where your final bams were created.
* ensure you have a `<cohort>.config` file, that is a tab-delimited file including `#SampleID	LabSampleID	SeqCentre	Library(default=1)` (the same config or a subset of samples from the config used in [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) is perfect). Sample GVCFs and multi-sample VCFs will be created for samples included in <cohort>.config. Sample ID's must end in -B or -N (this is to denote that they are normal, not tumour samples). 
* ensure you have a `Final_bams` directory, containing `<labsampleid>.final.bam` and `<labsampleid>.final.bai` files. <labsampleid> should match LabSampleID column in your `<cohort>.config` file.
 * ensure you have `References` directory from [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM). This contains input data required for Germline-ShortV (ordered and pre-definted intervals, known variants for variant quality score recalibration).
2. Clone this respository by `git clone https://github.com/Sydney-Informatics-Hub/Germline-ShortV.git`

Your set up should look like this. 

├── Fastq

├── Fastq_to_BAM_job_logs

├── Fastq_to_BAM_program_logs

├── Fastq_to_BAM_scripts_and_inputs

├── Final_bams

├── Germline-ShortV

├── Reference

├── samples.config


`Germline-ShortV` will be your working directory.

3. Follow the instructions in Quickstart or in the User Guide section (coming soon!)

# User guide

## Human (GRCh38/hg38 + ALT contigs)

Once you have followed the __Set up__ instructions, you can follow the instructions below. These instructions will create per sample GVCFs and perform joint-genotyping for multiple samples listed in `../<cohort>.config`.


# References

GATK4: Van der Auwera et al. 2013 https://currentprotocols.onlinelibrary.wiley.com/doi/abs/10.1002/0471250953.bi1110s43

OpenMPI: Graham et al. 2015 https://dl.acm.org/doi/10.1007/11752578_29
