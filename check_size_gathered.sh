#!/bin/bash
samples=$(awk -v FS=' ' 'NR>1 {print$2}' ../samples.config |grep "\-B")
for sample in $samples
do
	ls -al Interval_VCFs/${sample}/${sample}.g.vcf.*
done


