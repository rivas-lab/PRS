#!/bin/bash
set -beEuo pipefail

find /oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch/ -name "snpnet.tsv" | sort -V |
parallel --eta -j6 -k 'singularity run -H /home/jovyan /scratch/groups/mrivas/users/ytanigaw/simg/jupyter_yt_20200516.sif Rscript 7_count_PTVs_PAVs.R {}'

out=7_count_PTVs_PAVs.$(date +%Y%m%d-%H%M%S).tsv

{
cat /oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch/HC1/snpnet.cnt.tsv | egrep '^#'

find /oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch -name "snpnet.cnt.tsv" | sort -V | while read f ; do cat $f | egrep -v '^#' ; done
} > ${out}

echo $out
