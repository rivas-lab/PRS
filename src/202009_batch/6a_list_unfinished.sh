#!/bin/bash
set -beEuo pipefail

out_d="/scratch/groups/mrivas/projects/PRS/private_output/202009_batch"
find ${out_d} -mindepth 4 -maxdepth 4 -type f -name "snpnet.RData" | rev | awk -v FS='/' '{print $3}' | rev | sort -u \
    | comm -3 <(cat GBE_IDs/*.lst | grep -v '#GBE_ID' | sort -u) /dev/stdin | sort -V

