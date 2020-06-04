#!/bin/bash
set -beEuo pipefail

project_dir="/oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch"

timestamp=$(date +%Y%m%d-%H%M%S)
out="2_list_unfinished.lst.${timestamp}.txt"
err="2_list_unfinished.err.${timestamp}.txt"

cat highconfidenceqc_gbe_map.tsv | egrep -v 'AD_|TTE_' | awk '{print $1}' | while read GBE_ID ; do
    if [ ! -f ${project_dir}/${GBE_ID}/snpnet.RData ] ; then
        if [ -f ${project_dir}/${GBE_ID}/results/output_iter_1.RData ] ; then
            echo $GBE_ID | tee -a $out
        else
            echo $GBE_ID | tee -a $err
        fi
    fi
done

echo $out
echo $err

