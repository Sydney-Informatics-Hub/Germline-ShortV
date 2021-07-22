# Germline-ShortV

This pipeline is an implementation of the [BROAD's Best Practice Workflow for Germline short variant discovery (SNPS + Indels)](https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels-). This implementation is optimised for the **National Compute Infrastucture Gadi HPC**, utilising scatter-gather parallelism and the `nci.parallel` utility to enable use of multiple nodes with high CPU or memory efficiency.

<img src="https://user-images.githubusercontent.com/49257820/87390949-2b253080-c5ed-11ea-83a2-b559c0c4df2e.png" width="50%" height="50%">

# Quickstart

This quickstart is not for first timers. :)

The following will perform germline short variant calling for all samples present in `../<cohort>.config`. Once you're set up (see the guide below), change into the `Germline-ShortV` directory after cloning this repository. The scripts use relative paths and the `Germline-ShortV` is your working directory. Adjust compute resources requested in the `.pbs` files using the guide provided in each of the parallel scripts. This will often be according to the number of samples in `../<cohort>.config`.

0. Follow [Set up](#set-up) instructions if you are running this for the first time
1. Run HaplotypeCaller by:
  * `sh gatk4_hc_make_input.sh <cohort>`
  * `qsub gatk4_hc_run_parallel.pbs`
2. Check all interval .vcf and .vcf.idx files are present, check per sample task duration, check for errors in log files and archive logs by:
  * `sh gatk4_hc_missing_make_input.sh <cohort>`. 
  * `qsub gatk4_hc_missing_run_parallel.pbs`. Run this if there were missing .vcf or .vcf.idx files.
  The above two scripts should be re-run until all expected .vcf and .idx files are present for each sample. Once all files are present, run the following two scripts to check log files for errors. If there are none, log files will be archived.
  * `sh gatk4_hc_checklogs_make_input.sh <cohort>`
  * `sh gatk4_hc_checklogs_run_parallel.sh <cohort>` after adjusting project codes in the script. 
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

## Human datasets: GRCh38/hg38 + ALT contigs reference

There are six PBS jobs included in Germline-ShortV for samples which have been aligned to the human reference genome (GRCh38/hg38 + ALT contigs) using the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. The first job “HaplotypeCaller” calls raw SNPs and indels at 3,200 evenly-sized genomic intervals and multiple samples in parallel. “GatherVCFs” gathers per interval VCF files into per sample GVCF files, operating at multiple samples in parallel. We recommend backing up per sample GVCFs into the University of Sydney’s Research Data Store or similar. The sample GVCFs can be included in “Joint-calling” jobs in future projects as more samples are sequenced and are included in your cohort, saving compute resources. 

“Joint calling” includes three PBS jobs and commences with multiple per sample GVCF files generated from the two jobs in “Variant calling”. The job “GenomicsDBImport” consolidates sample GVCFs into databases and “GenotypeGVCFs” joint-calls variants at the pre-defined 3,200 genomic intervals in parallel. The resulting multiple-sample VCFs obtained for 3,200 intervals are then gathered with GatherVCFs to obtain a single cohort VCF file. Variants in the cohort VCF file are filtered and refined, first by removing sites with excess heterozygosity (indicative of technical artefacts). GATK’s variant quality score recalibration (VQSR) methods including the tools VariantRecalibrator and ApplyVQSR are then applied to SNPs and indels separately. VQSR is a machine learning method that uses high quality variant resources (1000 Genomes, omni, hapmap) as a training set to profile properties of probable true variants from technical artefacts. Variant calling metrics are then obtained from the Analysis ready cohort VCFs containing SNPs and indels. These files should be backed up before proceeding with downstream analysis. 

### Excluded sites

By default, some genomic sites that significantly impede on compute performance are excluded from calling. Excluded sites are listed in the Delly group's [sv_repeat_telomere_centromere.bed](https://gist.github.com/chapmanb/4c40f961b3ac0a4a22fd) file. The BED file contains:

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

# Set up

The Germline-ShortV pipeline works seamlessly with the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline and human datasets using the GRCh38/hg38 + ALT contigs reference. The scripts use relative paths, so correct set-up is important. 

Upon completion of [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM):

1. Change to the working directory where your final bams were created. The required inputs are:
* ensure you have a `<cohort>.config` file, that is a tab-delimited file including `#SampleID	LabSampleID	SeqCentre	Library(default=1)` (the same config or a subset of samples from the config used in [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) is perfect). Sample GVCFs and multi-sample VCFs will be created for samples included in `<cohort>.config`. 
* ensure you have a `Final_bams` directory, containing `<labsampleid>.final.bam` and `<labsampleid>.final.bai` files. <labsampleid> should match LabSampleID column in your `<cohort>.config` file.
 * ensure you have `References` directory from [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM). This contains input data required for Germline-ShortV (ordered and pre-definted intervals and reference variants)

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

# User guide

Once you have followed the __Set up__ instructions, you can follow the instructions below. These instructions will create per sample GVCFs and perform joint-genotyping for multiple samples listed in `../<cohort>.config`.

## Step 1. HaplotypeCaller

This step runs GATK 4's HaplotypeCaller in a scatter-gather fashion. Each task in the job runs HaplotypeCaller for a single sample for a single genomic interval. 

1. Create inputs for samples in `../<cohort>.config` by `sh gatk4_hc_make_input.sh <cohort>`. This creates Germline-ShortV/Inputs/gatk4_hc.inputs. Each line contains inputs for a single task for `gatk4_hc.sh`
2. Check `gatk4_hc.sh` and add any parameters relevant to your study. E.g.:

  * For PCR-free libraries it is recommended to include `-pcr_indel_model NONE`
  * The next version of this pipeline will automatically set this option for you through `../<cohort>.config` file

3. Set up and run the gatk4 HaplotypeCaller job by:

  * Adjusting PBS directives in `gatk4_hc_run_parallel.pbs`
  * Submitting your job: `qsub gatk4_hc_run_parallel.pbs`

# Benchmarking metrics

The benchmarking results provided were obtained from a human dataset with an average coverage of 35X.
 
## Summary 
 
| #JobName                     | CPUs_requested | Mem_used  | CPUtime    | Walltime_used | JobFS_used | Efficiency | Service_units | Queue   | Samples processed | Number of tasks | NCPUs per task | Average mem allowed per task(GB) | Memory Efficiency |
|------------------------------|----------------|-----------|------------|---------------|------------|------------|---------------|---------|-------------------|-----------------|----------------|----------------------------------|-------------------|
| gatk4_hc_960                 | 960            | 3.29TB    | 1675:26:10 | 1:46:42       | 20.43MB    | 0.98       | 3414.4        | normal  | 20                | 64000           | 1              | 4                                | 0.88              |
| gatk4_hc_1920                | 1920           | 6.52TB    | 1693:46:28 | 0:54:08       | 20.55MB    | 0.98       | 3464.5        | normal  | 20                | 64000           | 1              | 4                                | 0.87              |
| gatk4_hc_2880                | 2880           | 9.15TB    | 1744:28:32 | 0:39:07       | 20.55MB    | 0.93       | 3755.2        | normal  | 20                | 64000           | 1              | 4                                | 0.81              |
| gatk4_hc_3840                | 3840           | 11.42TB   | 2154:15:26 | 0:40:05       | 20.55MB    | 0.84       | 5130.7        | normal  | 20                | 64000           | 1              | 4                                | 0.76              |
| gatk4_gathervcfs_5           | 5              | 160.0GB   | 10:22:28   | 2:43:03       | 8.05MB     | 0.76       | 40.8          | hugemem | 20                | 20              | 1              | 32                               | 1.00              |
| gatk4_gathervcfs_10          | 10             | 320.0GB   | 9:56:00    | 1:17:49       | 8.07MB     | 0.77       | 38.9          | hugemem | 20                | 20              | 1              | 32                               | 1.00              |
| gatk4_gathervcfs_15          | 15             | 480.0GB   | 13:28:19   | 1:44:05       | 8.08MB     | 0.52       | 78.1          | hugemem | 20                | 20              | 1              | 32                               | 1.00              |
| gatk4_gathervcfs_20          | 20             | 486.12GB  | 28:21:05   | 1:49:46       | 8.09MB     | 0.77       | 109.8         | hugemem | 20                | 20              | 1              | 32                               | 0.76              |
| gatk4_genomicsdbimport_48    | 48             | 746.06GB  | 84:38:42   | 2:29:53       | 8.92MB     | 0.71       | 359.7         | hugemem | 20                | 3200            | 1              | 31                               | 0.51              |
| gatk4_genomicsdbimport_192_n | 192            | 519.53GB  | 119:33:16  | 3:41:05       | 8.93MB     | 0.17       | 1414.9        | normal  | 20                | 3200            | 4              | 16                               | 0.68              |
| gatk4_genomicsdbimport_96    | 96             | 1.48TB    | 155:27:45  | 2:28:12       | 8.92MB     | 0.66       | 711.4         | hugemem | 20                | 3200            | 1              | 31                               | 0.51              |
| gatk4_genomicsdbimport_144   | 144            | 931.71GB  | 122:04:35  | 3:14:25       | 8.92MB     | 0.26       | 1399.8        | hugemem | 20                | 3200            | 1              | 31                               | 0.21              |
| gatk4_genotypegvcfs_48       | 48             | 326.98GB  | 94:44:02   | 5:21:39       | 8.88MB     | 0.37       | 772.0         | hugemem | 20                | 3200            | 2              | 63                               | 0.22              |
| gatk4_genotypegvcfs_96       | 96             | 701.23GB  | 92:53:48   | 2:43:46       | 8.88MB     | 0.35       | 786.1         | hugemem | 20                | 3200            | 2              | 63                               | 0.24              |
| gatk4_genotypegvcfs_144      | 144            | 1.05TB    | 92:09:53   | 1:58:00       | 8.88MB     | 0.33       | 849.6         | hugemem | 20                | 3200            | 2              | 63                               | 0.24              |
| gatk4_genomicsdbimport_48_h  | 48             | 435.48 GB | 131:03:01  | 3:41:18       | 9383082b   | 0.74       | 531.3         | hugemem | 20                | 3200            | 1              | 31                               | 0.29              |

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
