# Germline-ShortV

Jump to the [quickstart](#quickstart) if you are impatient and not a first timer :).

## Description

This pipeline is an implementation of the [BROAD's Best Practice Workflow for Germline short variant discovery (SNPS + Indels)](https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels-). This implementation is optimised for the **National Compute Infrastucture Gadi HPC**, utilising scatter-gather parallelism and the `nci.parallel` utility to enable use of multiple nodes with high CPU or memory efficiency. Scatter-gather parallelism also enables checkpointing and 

This workflow requires sample BAM files, which can be generated using the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. Optimisations for scalability and parallelization have been performed on the human reference genome GRCh38/hg38 + ALT contigs. Germline-ShortV can be applied to other model and non-model organisms (including non-diploid organisms), with some modifications as described below. 

The primary steps to this pipeline are:

* HaplotypeCaller
* GenomicsDBImport
* GenotypeGVCFs
* Variant Quality Score Recalibration

Most jobs follow a typical pattern which is:

1. Creating an inputs file using `<job>_make_input.sh <path/to/cohort.config>`
2. Adjusting compute resources and submitting your job by `qsub <job>_run_parallel.pbs`. [Benchmarking metrics](#benchmarking-metrics) are available on this page as a guide for compute resources required for your dataset. 

## Human datasets: GRCh38/hg38 + ALT contigs reference

This pipeline has been optimised for BAMs mapped to the GRCh38/hg38 + ALT contigs reference genome. Scatter-gather parallelism has been designed to operate over 3,200 evenly sized genomic intervals (~1Mb in size) across your sample cohort. For each of the primary steps, this means:

* HaplotypeCaller:
  * The number of scatter tasks = N samples x 3,200 genomic intervals
  * 3,200 VCFs are gathered per sample to create a `sample.g.vcf.gz`
* GenomicsDBImport:
  * The number of scatter tasks = 3,200 genomic intervals
  * Each output is used as input for GenotypeGVCFs
* GenotypeGVCFs:
  * The number of scatter tasks = 3,200 genomic intervals
  * 3,200 VCFs are gathered into a single `cohort.g.vcf.gz`
* Variant Quality Score Recalibration
  * Is relatively quick and scattering is not required.
  * Inputs are `cohort.g.vcf.gz` and the final output is written to `cohort.recalibrated.vcf.gz`

The 3,200 genomic intervals have been ordered from longest to shortest task duration for job maximum efficiency. Some [genomic intervals are excluded](#excluded-sites) - these typically include repetitive regions which can significantly impede on compute performance. 

### Excluded sites

Excluded sites are listed in the Delly group's [sv_repeat_telomere_centromere.bed](https://gist.github.com/chapmanb/4c40f961b3ac0a4a22fd) file. The BED file contains:

* telemeres
* centromeres
* chrUn (unplaced)
* chrUn_XXXXX_decoy (decoy)
* chrN_XXXXX_random (unlocalized)
* chrEBV

### Cancer studies

A `<cohort>.config` file containing both tumour and normal samples can be used to call germline variants on the normal samples only. The make input files will ignore writing inputs for tumour samples. Tumour samples are specified in `LabSampleID` column the `<cohort>.config` file if they __end__ in:

* -T.* (e.g. -T, -T1, -T100). This is used to indicate tumour samples belonging.
* -P.* (e.g. -P, -P1, -P100). This can be used to specify primary tumour samples belonging to a single patient.
* -M.* (e.g. -M, -M1, -MCL1). This can be used to specify metastatic tumour samples belonging to a single patient.

## Workflow Diagram

<img src="https://user-images.githubusercontent.com/49257820/87390949-2b253080-c5ed-11ea-83a2-b559c0c4df2e.png" width="50%" height="50%">

## Quickstart

The following will perform germline short variant calling for all samples present in `<cohort>.config`. The scripts use relative paths and the `Germline-ShortV` is your working directory. Adjust compute resources requested in the `.pbs` files using the guide provided in each of the PBS job scripts. 

### Set up

0. Clone this repository and ensure you are correctly [set up](#set-up):
```
git clone https://github.com/Sydney-Informatics-Hub/Germline-ShortV.git
cd Germline-ShortV
```
### HaplotypeCaller

1. Run HaplotypeCaller by creating inputs, adjusting compute resources and submitting the PBS script:
```
sh gatk4_hc_make_input.sh /path/to/cohort.config
qsub gatk4_hc_run_parallel.pbs
```
2. Check HaplotypeCaller job. The script checks that all sample interval `.vcf` and `.vcf.idx` files exist, and for any files in `Logs/GATK4_HC_error_capture`. Any failed tasks will be written to `Inputs/gatk4_hc_missing.inputs`. If there are failed tasks, investigate cause of errors using sample interval log files in `Logs/GATK4_HC`
```
sh gatk4_hc_check.sh /path/to/cohort.config
# Only run the job below if there were tasks that failed
qsub gatk4_hc_missing_run_parallel.pbs
```
3. Merge HaplotypeCaller per interval VCFs into single sample-level GVCFs creating inputs, adjusting compute resources and submitting the PBS script:
```
sh gatk4_hc_gathervcfs_make_input.sh /path/to/cohort.config
qsub gatk4_hc_gathervcfs_run_parallel.pbs
```
4. Backup GVCFs

Sample GVCFs can be used again if you wish perform multi-sample calling with a bigger cohort (e.g. when you sequence new samples), so we recommend backing these up.

### GenomicsDBImport

5. Consolidate interval VCFs using GATK’s GenomicsDBImport by:
  * `sh gatk4_genomicsdbimport_make_input.sh <cohort>`
  * `qsub gatk4_genomicsdbimport_run_parallel.pbs`
6. Check interval GenomicsDBImport databases are present, check log files, check interval duration, check Runtime.totalMemory(), re-run tasks that failed
  * `sh gatk4_genomicsdbimport_missing_make_input.sh <cohort>`. Re-run this script until there are 0 intervals that need to be re-run. 
  * `qsub gatk4_genomicsdbimport_missing_run_parallel.pbs`. Run this if there are intervals that need to be run.

### GenotypeGVCFs

7. Perform joint calling using GATK's GenotypeGVCFs by:
  * `sh gatk4_genotypegvcfs_make_input.sh <cohort>`
  * `qsub gatk4_genotypegvcfs_run_parallel.pbs`
8. Check interval VCFs made by GenotypeGVCFs. Check for errors in logs, print duration, Runtime.totalMemory() per interval, re-run tasks that failed
  * `sh gatk4_genotypegvcfs_missing_make_input.sh <cohort>`
  * `qsub gatk4_genotypegvcfs_missing_run_parallel.pbs`
9. Gather joint-genotyped interval VCFs into a multisample GVCF. 
  * `qsub gatk4_gather_sort_vcfs.pbs`

### Variant Quality Score Recalibration

10. Run Variant Quality Score Recalibration (VQSR) by:
  *  Change cohort=<cohort>
  * `qsub gatk4_vqsr.pbs`
  * Check `<cohort>.recalibrated.metrics.variant_calling_detail_metrics`
11. Back up cohort, genotyped, recalibrated GVCFs and varaint calling metrics 

## Set up

* For sample BAMs aligned to the human reference genome, follow [Human (GRCh38/hg38 + ALT contigs)](#human-(grc38/hg38-+-ALT-contigs))
* For sample BAMs aligned to other reference genomes, follow [Non-human organisms](#non-human-organisms)
 
### Human (GRCh38/hg38 + ALT contigs)
 
The Germline-ShortV pipeline works seamlessly with the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline and human datasets using the GRCh38/hg38 + ALT contigs reference. The scripts use relative paths, so correct set-up is important. 

Upon completion of [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM):

1. Change to the working directory where your final bams were created. The required inputs are:
* ensure you have a `<cohort>.config` file, that is a tab-delimited file including `#SampleID	LabSampleID	SeqCentre	Library(default=1)` (the same config or a subset of samples from the config used in [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) is perfect). Sample GVCFs and multi-sample VCFs will be created for samples included in `<cohort>.config`. 
* ensure you have a `Final_bams` directory, containing `<labsampleid>.final.bam` and `<labsampleid>.final.bai` files. <labsampleid> should match LabSampleID column in your `<cohort>.config` file.
 * ensure you have `References` directory from [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM). This contains input data required for Germline-ShortV (ordered and pre-definted intervals and reference variants). **For other organisms you will need to create the scattered interval files - script for this is coming soon**

Your high level directory structure should resemble the following:

```bash
|-- Align_split
|-- BQSR_apply
|-- BQSR_tables
|-- Check_split_fastq
|-- Dedup_sort
|-- FastQC
|-- Fastq
|-- Final_bams
|-- HLA_fastq
|-- Merge_align
|-- Reference
|-- Scripts
|-- SplitDisc
`-- Split_fastq
```

2. Clone this respository by `git clone https://github.com/Sydney-Informatics-Hub/Germline-ShortV.git`

`Germline-ShortV` will be your working directory.

3. Follow the instructions in Quickstart or in the User Guide section (coming soon!)

## Non-human organisms

This pipeline can be used on reference datasets other than GRCh38/hg38 + ALT contigs, including other model or non-model organisms. You will need to complete an additional set-up step to create a list of intervals for scatter-gathering in this pipeline.

### Create a list of intervals

To create a list of intervals for scattering tasks:

* Change to your `Reference` directory, containing the reference genome you wish to use
* Load the version of GATK 4 that you wish to use, e.g. `module load gatk/4.1.2.0`
* Run `gatk SplitIntervals -R <reference.fa> --scatter-count 3200 -XL <exclude_intervals.bed> -O ShortV_intervals`. `-XL <exclude_intervals.bed>` allows exclusion of intervals that can impede on compute efficiency and performance (e.g. centromeres, telomeres, unplaced and unlocalised contigs, etc). The pipeline is set up to run on 3200 scattered intervals. 

# Benchmarking metrics

The benchmarking results provided were obtained from a human dataset with an average coverage of 35X.

## Step 1. Benchmarking: HaplotypeCaller

The benchmarking metrics below were obtained using human datasets with an average coverage of 35X. 

Scalability to compute resources

| Samples processed | CPUs_used | CPUs_per_sample | Mem_used | CPUtime    | Walltime_used | JobFS_used | Efficiency | Service_units(CPU_hours) | Queue  | Average SUs per sample | Exit_status |
|-------------------|-----------|-----------------|----------|------------|---------------|------------|------------|--------------------------|--------|------------------------|-------------|
| 20                | 960       | 48              | 3.29TB   | 1675:26:10 | 1:46:42       | 20.43MB    | 0.98       | 3414                     | normal | 171                    | 0           |
| 20                | 1920      | 96              | 6.52TB   | 1693:46:28 | 0:54:08       | 20.55MB    | 0.98       | 3465                     | normal | 173                    | 0           |
| 20                | 2880      | 144             | 9.15TB   | 1744:28:32 | 0:39:07       | 20.55MB    | 0.93       | 3755                     | normal | 188                    | 0           |
| 20                | 3840      | 192             | 11.42TB  | 2154:15:26 | 0:40:05       | 20.55MB    | 0.84       | 5131                     | normal | 257                    | 0           |

Scalability to cohort size

| Samples processed | CPUs_used | Mem_used | CPUtime     | Walltime_used | JobFS_used | Efficiency | Service_units(CPU_hours) | Queue  | Average SUs per sample | Exit_status |
|-------------------|-----------|----------|-------------|---------------|------------|------------|--------------------------|--------|------------------------|-------------|
| 20                | 1920      | 6.52TB   | 1693:46:28  | 0:54:08       | 20.55MB    | 0.98       | 3465                     | normal | 173                    | 0           |
| 30                | 2880      | 9.56TB   | 2490:01:45  | 0:53:19       | 26.97MB    | 0.97       | 5118                     | normal | 171                    | 0           |
| 40                | 3840      | 12.85TB  | 3757:02:48  | 1:00:11       | 33.24MB    | 0.98       | 7703                     | normal | 193                    | 0           |
| 60                | 5760      | 19.66TB  | 7581:22:59  | 2:01:12       | 46.05MB    | 0.65       | 23270                    | normal | 388                    | 271         |
| 80                | 7680      | 26.92TB  | 11522:42:48 | 2:01:07       | 62.59MB    | 0.74       | 31006                    | normal | 388                    | 271         |

# References

GATK 4: Van der Auwera et al. 2013 https://currentprotocols.onlinelibrary.wiley.com/doi/abs/10.1002/0471250953.bi1110s43

OpenMPI: Graham et al. 2015 https://dl.acm.org/doi/10.1007/11752578_29
