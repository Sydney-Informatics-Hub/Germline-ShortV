# Germline-ShortV

## Description

This pipeline is an implementation of the [BROAD's Best Practice Workflow for Germline short variant discovery (SNPS + Indels)](https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels-). This implementation is optimised for the **National Compute Infrastucture Gadi HPC**, utilising scatter-gather parallelism and the `nci.parallel` utility to enable use of multiple nodes with high CPU or memory efficiency. Scatter-gather parallelism also enables checkpointing and semi-automated re-running of failed tasks. 

This workflow requires sample BAM files, which can be generated using the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. Optimisations for scalability and parallelization have been performed on the human reference genome GRCh38/hg38 + ALT contigs. Germline-ShortV can be applied to other model and non-model organisms (including non-diploid organisms), with some modifications as described below. 

The primary steps to this pipeline are:

* HaplotypeCaller
* GenomicsDBImport
* GenotypeGVCFs
* Variant Quality Score Recalibration

Most jobs follow a typical pattern which is:

1. Creating an inputs file using `<job>_make_input.sh <path/to/cohort.config>`
2. Adjusting compute resources and submitting your job by `qsub <job>_run_parallel.pbs`. [Benchmarking metrics](#benchmarking-metrics) are available on this page as a guide for compute resources required for your dataset. This runs `<job>.sh` in parallel for the inputs file created (1 line = 1 task). Default parameters are typically used otherwise you can modify command specific parameters in `<job>.sh`. 
3. Performing a check using `<job>_check.sh` on the job by checking for expected output, and/or, checking for error messages in log files. Inputs will be written for failed tasks for job re-submission with `<job>_missing_run_parallel.pbs`

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
  * 3,200 VCFs are gathered into a single, co-ordinate sorted `cohort.sorted.vcf.gz`
* Variant Quality Score Recalibration
  * Is relatively quick and scattering is not required.
  * Inputs are `cohort.g.vcf.gz` and the final output is written to `cohort.recalibrated.vcf.gz`

The 3,200 genomic intervals have been ordered from longest to shortest task duration for job maximum efficiency. Some [genomic intervals are excluded](#excluded-sites) - these typically include repetitive regions which can significantly impede on compute performance. 

### Excluded sites

Excluded sites are listed in the Delly group's [sv_repeat_telomere_centromere.bed](https://gist.github.com/chapmanb/4c40f961b3ac0a4a22fd) file. This is included in the `References` dataset. The BED file contains:

* telemeres
* centromeres
* chrUn (unplaced)
* chrUn_XXXXX_decoy (decoy)
* chrN_XXXXX_random (unlocalized)
* chrEBV

### Cancer studies

A `<cohort>.config` file containing both tumour and normal samples can be used to call germline variants on the normal samples only. The make input files will ignore writing inputs for tumour samples. Tumour samples are specified in `LabSampleID` column the `<cohort>.config` file if they __end__ in:

* -T.* (e.g. Sample1-T, Sample1-T1, Sample1-T100). This is used to indicate different tumour samples belonging to Sample1.
* -P.* (e.g. Sample2-P, Sample2-P1, Sample2-P100). This can be used to specify primary tumour samples belonging to Sample2.
* -M.* (e.g. Sample3-M, Sample3-M1, Sample3-MCL1). This can be used to specify metastatic tumour samples belonging to Sample3. 

A normal sample with `LabSampleID` as Sample1, Sample1-B, Sample1-N, will be considered "normal" and be included in this germline variant calling pipeline.

## Workflow Diagram

<img src="https://user-images.githubusercontent.com/49257820/87390949-2b253080-c5ed-11ea-83a2-b559c0c4df2e.png" width="50%" height="50%">

## User guide

The following will perform germline short variant calling for samples present in `<cohort>.config`. The scripts use relative paths and the `Germline-ShortV` is your working directory. Adjust compute resources requested in the `.pbs` files using the guide provided in each of the PBS job scripts.

This guide is intended for use of the scripts in this repository. For information on [GATK's Best Practice Workflow for Germline short variant discovery please see their website](https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels-).

At minimum, you will need a `<cohort>.config` and your current working directory should contain:

* `Final_bams` directory with your `<sample>.final.bam` and `<labsampleid>.final.bai` files within. 
* `References` directory from [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM)

See [set up](#set-up) for more details or if you are __not__ using the GRCh38/hg38 + ALT contigs reference genome.

Clone this repository:
```
git clone https://github.com/Sydney-Informatics-Hub/Germline-ShortV.git
cd Germline-ShortV
```
### HaplotypeCaller

1. Run HaplotypeCaller by creating task inputs, adjusting compute resources and submitting the PBS script:
```
sh gatk4_hc_make_input.sh /path/to/cohort.config
qsub gatk4_hc_run_parallel.pbs
```
2. Check HaplotypeCaller job. The script checks that all sample interval `.vcf` and `.vcf.idx` files exist, and for any error files in `Logs/GATK4_HC_error_capture`. Any failed tasks will be written to `Inputs/gatk4_hc_missing.inputs`. If there are failed tasks, investigate cause of errors using sample interval log files in `Logs/GATK4_HC`
```
sh gatk4_hc_check.sh /path/to/cohort.config

# Only run the job below if there were tasks that failed
qsub gatk4_hc_missing_run_parallel.pbs
```
3. Merge HaplotypeCaller per interval VCFs into single sample-level GVCFs creating by creating task inputs, adjusting compute resources and submitting the PBS script:
```
sh gatk4_gathervcfs_make_input.sh /path/to/cohort.config
qsub gatk4_gathervcfs_run_parallel.pbs
```
4. Check GatherVcfs job. The script checks that all `<sample>.g.vcf.gz` and `<sample>.g.vcf.gz.tbi` files exist, and for any error files in `Logs/GATK4_GatherVCFs_error_capture`. Any failed tasks will be written to `Inputs/gatk4_gathervcfs_missing.inputs`. If there are failed tasks, investigate cause of errors using sample interval log files in `Logs/GATK4_GatherVCFs`
```
sh gatk4_gathervcfs_check.sh

# Only run the job below if there were tasks that failed
qsub gatk4_gathervcfs_missing_run_parallel.pbs
```
Sample GVCFs can be used again if you wish perform multi-sample calling with a bigger cohort (e.g. when you sequence new samples), so we recommend backing these up.

### GenomicsDBImport

1. Consolidate interval VCFs using GATK’s GenomicsDBImport by creating task inputs, adjusting compute resources and submitting the PBS script:
```
sh gatk4_genomicsdbimport_make_input.sh /path/to/cohort.config
qsub gatk4_genomicsdbimport_run_parallel.pbs`
```
2. Check interval GenomicsDBImport databases are present, check log files for errors for each interval present in the scatter list file. Report interval duration and Runtime.totalMemory() to `Logs/GATK4_GenomicsDBImport/GATK_duration_memory.txt`. 
```
sh gatk4_genomicsdbimport_check.sh /path/to/cohort.config

# Only run the job below if there were tasks that failed
qsub gatk4_genomicsdbimport_missing_run_parallel.pbs
```
__Tip__ - if you have tasks that failed, it is likely that it needs more memory. The memory and task duration to process each interval is variable to the number and coverage of your samples. The `gatk4_genomicsdbimport_check.sh` script will output duration and memory used per task from step 1 in `Logs/GATK4_GenomicsDBImport/GATK_duration_memory.txt` which is handy for benchmarking. Compute resources in the `gatk4_genomicsdbimport_missing.sh` task script (run in parallel by `gatk4_genomicsdbimport_missing_run_parallel.pbs`) by default allocates more memory per task, but you may want to make further adjustments to the `--java-options -Xmx58g` flag.

### GenotypeGVCFs

1. Perform joint calling using GATK's GenotypeGVCFs by creating task inputs, adjusting compute resources and submitting the PBS script:
```
 sh gatk4_genotypegvcfs_make_input.sh /path/to/cohort.config
 qsub gatk4_genotypegvcfs_run_parallel.pbs
```
2. Check all GenotypeGVCFs scatter outputs `<cohort>.<interval>.vcf.gz` and `<cohort>.<interval>.vcf.gz.tbi` exists and are not empty. Report interval duration and Runtime.totalMemory() to `Logs/GATK4_GenotypeGVCFs/GATK_duration_memory.txt`. 
```
sh gatk4_genotypegvcfs_check.sh /path/to/cohort.config

# Only run the job below if there were tasks that failed
qsub gatk4_genotypegvcfs_missing_run_parallel.pbs
```
3. Gather joint-genotyped interval VCFs into a multisample GVCF. 
```
qsub gatk4_gather_sort_vcfs.pbs
```

### Variant Quality Score Recalibration

The `gatk4_vqsr.pbs` script runs a series of single core commands that performs the workflow described [in GATK's documentation - 1. VQSR: filter a cohort callset with VariantRecalibrator & ApplyVQSR
](https://gatk.broadinstitute.org/hc/en-us/articles/360035531112--How-to-Filter-variants-either-with-VQSR-or-by-hard-filtering#1.1). This includes:

* Filtering excessive heterozygous sites. This is only recommended for large cohorts, please read GATK's recommendations for more detail and only use this if it applies to your cohort
* Create variant-sites only VCF
* Perform `VariantRecalibrator` for indels and SNPs
* Perform `ApplyVQSR` for indels and SNPs to get final, indexed `cohort.final.recalibrated.vcf.gz`
* Perform `CollectVariantCallingMetrics` on the final VCFs to get metrics in `cohort.final.recalibrated.metrics.variant_calling_detail_metrics`

1. Run these steps editing `gatk4_vqsr` by:
```
Change cohort=/path/to/cohort.conifg

# Adjusting memory, more memory is required for larger cohorts (more variants)
qsub gatk4_vqsr.pbs`
```

Back up cohort, genotyped, recalibrated GVCFs and varaint calling metrics.

## Set up

## Tools

The scripts have been tested and are compatible with:

* gatk/4.1.2.0
* gatk/4.1.8.1
* samtools/1.10

GATK periodically likes to change flag names and how they are called, please keep this in mind if using a different version of GATK :).
 
## Required inputs
 
The Germline-ShortV pipeline works seamlessly with the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. Upon completion of [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM):

1. Change to the working directory where your final bams were created. The required inputs are:
* `<cohort>.config` file. This is a tab-delimited file including `#SampleID	LabSampleID	SeqCentre	Library(default=1)` (the same config or a subset of samples from the config used in [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM)). Sample GVCFs and multi-sample VCFs will be created for samples included in `<cohort>.config`. Output files and directories will be named using the config prefix `<cohort>`.
   * _Disclaimer_ LabSampleID's ending in -T, -P or -M [see cancer studies](#cancer-studies) will be ignored by default.
* `Final_bams` directory, containing `<labsampleid>.final.bam` and `<labsampleid>.final.bai` files. <labsampleid> should match LabSampleID column in your `<cohort>.config` file. The output of [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) will be structured this way, otherwise you can easily create this structure by creating symbolic links to your sample BAM and BAI files in `Final_bams`

2. Ensure you have scatter-gather intervals set up for your reference genome. This pipeline has been pre-set up and optimised for the GRCh38/hg38 + ALT contigs reference genome. You can use this pipeline with other model or non-model organisms with an additional set-up step.

 __For samples aligned to human (GRCh38/hg38 + ALT contigs)__
* Ensure you have the `Reference` directory (available through from [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM).

 __For samples aligned to other reference genomes__
Create a list of intervals for scattering tasks by: 
  * Change to your `Reference` directory, containing the reference genome you wish to use
  * Load the version of GATK 4 that you wish to use, e.g. `module load gatk/4.1.8.1`
  * Run `gatk SplitIntervals -R <reference.fa> --scatter-count <number_of_scatter_intervals> -XL <exclude_intervals.bed> -O ShortV_intervals`
    * `-XL <exclude_intervals.bed>` is optional - it allows exclusion of intervals that can impede on compute efficiency and performance (e.g. centromeres, telomeres, unplaced and unlocalised contigs, etc).
    * It is recommended to set <number_of_scatter_intervals> such that the reference genome size/<number_of_scatter_intervals> = 1000000 (as benchmarking metrics are based of 1Mb sized intervals). I do not recommend going any smaller than that as the tasks become too short in duration and can cause extra overhead. 
  * Run `find ShortV_intervals/ -name "*interval_list" -printf "%f\n" > ShortV_intervals/interval.list` to create a single text file containing the `interval_list` files created with `gatk SplitIntervals`
    * The order of the intervals in this file are used to order tasks in the job
    * To optimise the pipeline for your reference genome/species of interest, I would recommend running the pipeline to HaplotypeCaller on a small dataset, and ordering this list from longest to shortest duration, before running this on the full dataset. You can get task duration for a sample using `perl gatk4_duration_mem.pl Logs/GATK4_HC/<labsampleid>`

Your current working directory should resemble the following:

```bash
|-- Align_split
|-- BQSR_apply
|-- BQSR_tables
|-- Check_split_fastq
|-- cohort.config
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

You can now refer to the main [user guide](#user-guide).

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

## Acknowledgements
   
Acknowledgements (and co-authorship, where appropriate) are an important way for us to demonstrate the value we bring to your research. Your research outcomes are vital for ongoing funding of the Sydney Informatics Hub and national compute facilities.  
 
### Suggested acknowledgements

The authors acknowledge the technical assistance provided by the Sydney Informatics Hub, a Core Research Facility of the University of Sydney and the Australian BioCommons which is enabled by NCRIS via Bioplatforms Australia. The authors acknowledge the use of the National Computational Infrastructure (NCI) supported by the Australian Government and the Sydney Informatics Hub HPC Allocation Scheme, supported by the Deputy Vice-Chancellor (Research), University of Sydney and the ARC LIEF, 2019: Smith, Muller, Thornber et al., Sustaining and strengthening merit-based access to National Computational Infrastructure (LE190100021).
 
# References

GATK 4: Van der Auwera et al. 2013 https://currentprotocols.onlinelibrary.wiley.com/doi/abs/10.1002/0471250953.bi1110s43

OpenMPI: Graham et al. 2015 https://dl.acm.org/doi/10.1007/11752578_29
