#!/bin/bash
set -beEuo pipefail

ml load R/3.6 gcc

data_d=/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test

find ${data_d} -maxdepth 3 -mindepth 3 | while read d; do
    if [ ! -f ${d}/snpnet.RData ] || [ ! -f ${d}/metric_df.R ] ; then
        Rscript metric_df.R $d $d/metric.tsv
    fi
done

{

echo "#run_name phenotype fit_or_refit lambda_idx train val" | tr ' ' '\t'

find ${data_d} -name "metric.tsv" | sort -V | while read f ; do
    if [ "${f}" != "" ] ; then
        run_name=$(     echo $f | rev | awk -v FS='/' '{print $4}'| rev)
        phenotype=$(    echo $f | rev | awk -v FS='/' '{print $3}'| rev)
        fit_or_refit=$( echo $f | rev | awk -v FS='/' '{print $2}'| rev)

        ! cat $f | egrep -v '^#' \
        | awk -v FS='\t' -v OFS='\t' \
        -v rn=${run_name} -v p=${phenotype} -v fr=${fit_or_refit} \
        '{print rn, p, fr, $1, $2, $3}'
    fi
done | sort -k1,1V -k2,2V -k3,3V -k4,4n

} > metric_df.tsv
