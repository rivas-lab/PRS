#!/bin/bash
set -beEuo pipefail

data_d=/scratch/groups/mrivas/projects/PRS/private_output/202009_batch

find ${data_d} -maxdepth 4 -mindepth 4 -type f -name "*.sscore.zst" \
| grep 2_refit \
| awk -v FS='/' -v OFS='\t' '{print $(NF-2), $(NF-3), $0}' \
| sort -k1,1V > ${data_d}/snpnet.sscore.2_refit.tsv

echo ${data_d}/snpnet.sscore.2_refit.tsv
