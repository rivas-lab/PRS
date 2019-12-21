#!/bin/bash
set -beEuo pipefail

get_PCs_str () {
    local n_PCs=$1
    seq 1 ${n_PCs} | while read i ; do echo PC$i ; done  | tr "\n" "," | sed -e "s/,$//g"
}

gbe_id_to_family () {
    local gbe_id=$1

    local gbe_id_prefix=$( echo ${gbe_id} | sed -e "s/[0-9]//g" )
    # gbe_id_prefix=INI

    if [ "${gbe_id_prefix}" == "COX" ] ; then
        family="cox"
    elif [ "${gbe_id_prefix}" == "INI" ] || [ "${gbe_id_prefix}" == "QT_BIN" ] ; then
        family="gaussian"
    else
        family="binomial"
    fi

    echo ${family}
}

get_snpnet_tmp_dir () {
    local gbe_id=$1
    local version=$2
    local geno_dataset=$3
    echo /scratch/users/ytanigaw/tmp/snpnet/jobs/${version}/${geno_dataset}/${gbe_id}
}

get_phe_info_line_INI () {
    local phe_info_file=$1    
    local batch_idx=$2
    cat ${phe_info_file} | awk '{print $1, $NF}' | grep -v '#' | grep "INI" \
    | awk -v nr=$batch_idx 'NR == nr'
}

phe_file_to_snpnet_res () {
    local gbe_id=$1
    local phe_file=$2
    local geno_dataset=$3
    local pop=$4

    phe_file=/oak/stanford/groups/mrivas/ukbb24983/phenotypedata/9796/24611/phe/INI50.phe
    geno_dataset=cal
    pop=white_british

    local out_dir=$(dirname $phe_file | sed -e "s%phenotypedata%${geno_dataset}/snpnet%g" | sed -e "s%phe$%${pop}%g")
    echo $out_dir/ukb24983_v2_hg19.${gbe_id}.${geno_dataset}
}

copy_results_from_tmp () {
    local tmp_dir=$1
    local res=$2

    res_dir=$(dirname ${res})
    if [ ! -d ${res_dir} ] ; then mkdir -p ${res_dir} ; fi

    for ext in RData tsv covars.tsv ; do 
        cp ${tmp_dir}/snpnet.${ext} ${res}.${ext}
    done
}
