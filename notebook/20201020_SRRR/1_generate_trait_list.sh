#!/bin/bash
set -beEuo pipefail

! zcat /oak/stanford/groups/mrivas/projects/PRS/private_output/202009_batch/ukb24983_GWAS_covar.20200828.PRSs.phe.gz \
    | head -n1 | cut -f95- | tr '\t' '\n' \
    | sed -e 's/^PRS_//g' > SRRR.GBE_ID.lst


