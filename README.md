# Germline-ShortV
<img src="https://user-images.githubusercontent.com/49257820/87390949-2b253080-c5ed-11ea-83a2-b559c0c4df2e.png" width="50%" height="50%">

# Quickstart

This is not for first timers. :)

Clone this repository and run scripts in the `Germline-ShortV` directory.

1. Run haplotype caller by:
  * `sh gatk4_hc_make_input.sh samples`
  * `qsub gatk4_hc_run_parallel.pbs`
2. Check all interval .vcf and .vcf.idx files are present, check per sample task duration, check for errors in log files and archive logs by:
  * `sh gatk4_hc_missing_make_input.sh samples`. Re-run this script, check cause of errors until there are 0 missing vcf files.
  * `qsub gatk4_hc_missing_run_parallel.pbs`. There were no missing .vcf or .vcf.idx files, so we did not run this. 
  * `sh gatk4_hc_checklogs_make_input.sh samples`
  * `sh gatk4_hc_checklogs_run_parallel.sh`
3. Merge haplotype caller per interval vcfs by:
  * `sh gatk4_hc_gathervcfs_make_input.sh samples`
  * `qsub gatk4_hc_gathervcfs_run_parallel.pbs`
4. Backup GVCFs
5. Consolidate interval VCFs using GATK’s GenomicsDBImport by:
  * `sh gatk4_genomicsdbimport_make_input.sh samples`
  * Adjust `gatk4_genomicsdbimport.sh` memory according to the number of samples and sample coverage 
  * `qsub gatk4_genomicsdbimport_run_parallel.pbs`
6. Check interval GenomicsDBImport databases are present, check log files, check interval duration, check Runtime.totalMemory(), re-run tasks that failed
  * `sh gatk4_genomicsdbimport_missing_make_input.sh`. Re-run this script until there are 0 intervals that need to be re-run. 
  * `sh gatk4_genomicsdbimport_missing_run_parallel.pbs`
7. Perform joint calling using GATK's GenotypeGVCFs by:
  * `sh gatk4_genotypegvcfs_make_input.sh samples`
  * `qsub gatk4_genotypegvcfs_run_parallel.pbs`
8. Check interval VCFs made by GenotypeGVCFs. Check for errors in logs, print duration, Runtime.totalMemory() per interval, re-run tasks that failed
  * `sh gatk4_genotypegvcfs_missing_make_input.sh samples`
  * `qsub gatk4_genotypegvcfs_missing_run_parallel.pbs`
9. Gather joint-genotyped interval VCFs into a multisample GVCF
  * `qsub gatk4_gather_sort_vcfs.pbs`. Edit if your
10. Run Variant Quality Score Recalibration (VQSR) by:
  * `qsub gatk4_vqsr.pbs`
  * Check `samples.recalibrated.metrics.variant_calling_detail_metrics`
11. Back up cohort, genotyped, recalibrated GVCFs and varaint calling metrics 
