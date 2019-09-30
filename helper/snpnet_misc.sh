#!/bin/bash
set -beEuo pipefail

copy_geno_to_tmp () {
    local geno_dir=$1
    local tmp_geno_dir=$2
    
    if [ ! -d ${tmp_geno_dir} ] ; then mkdir -p ${tmp_geno_dir} ; fi
    for s in train val ; do for ext in bim fam bed ; do 
        if [ ! -f ${tmp_geno_dir}/${s}.${ext} ] ; then
            cp ${geno_dir}/${s}.${ext} ${tmp_geno_dir}/ 
        fi
    done ; done
}

get_results_dir () {
    local data_dir_root=$(readlink -f $1)
    local phenotype_name=$2

    echo "${data_dir_root}/${phenotype_name}/results"
}

find_prevIter () {
    local data_dir_root=$1
    local phenotype_name=$2
    
    local results_dir=$(get_results_dir "${data_dir_root}" "${phenotype_name}")
    
    { 
    if [ -d ${results_dir}/results ] ; then
        find ${results_dir}/results -maxdepth 1 -name "output_iter_*.RData" | sort -Vr \
        | while read f ; do basename $f .RData ; done 
    fi 
    echo "output_iter_0" 
    } | awk 'NR==1' | sed -e "s/output_iter_//g"
}
