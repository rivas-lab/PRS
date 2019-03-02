#!/bin/bash
set -beEuo pipefail

results_dir=$(readlink -f $1)

find ${results_dir} -type f -name "*.eval" \
| while read f ; do cat $f ; done \
| sed -e "s%${results_dir}%%" \
| sed -e 's%/%\t%g' \
| sed -e 's/ukb24983_v2.//g' \
| sed -e 's/ukb16698_v2.//g' \
| sed -e 's/.PHENO1.glm.linear.sscore//g' \
| sed -e 's/.PHENO1.glm.logistic.hybrid.sscore//g' \
| awk -v OFS='\t' '{print $3, $2, $4, $5, $6}' \
| sort -k1,1 -k2,2

