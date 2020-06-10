#!/bin/bash
set -beEuo pipefail

data_d="/oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch"
ext=".sscore.zst"
out_f="4_list_GBE_IDs_with_sscore.$(date +%Y%m%d-%H%M%S).txt"

find ${data_d} -name "*.sscore.zst" | while read f ; do basename ${f} .sscore.zst ; done | sort -V  > ${out_f}
echo ${out_f}

