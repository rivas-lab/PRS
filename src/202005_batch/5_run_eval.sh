#!/bin/bash
set -beEuo pipefail

GBE_ID_list_file=$1

cat ${GBE_ID_list_file} | parallel -k --eta -j6 'singularity run -H /home/jovyan /scratch/groups/mrivas/users/ytanigaw/simg/jupyter_yt_20200516.sif Rscript eval.R {}'
