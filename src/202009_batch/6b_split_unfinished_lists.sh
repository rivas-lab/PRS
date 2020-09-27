#!/bin/bash
set -beEuo pipefail

GBE_ID_lst_f=$1
new_list_dir=$2

subsets=(
BIN.1-400
BIN.401-737
cancer
FH
HC.1-400
HC.401-800
HC.801-1103
INI.1-400
INI.401-800
INI.801-1200
INI.1201-1515
QT_FC
)

data_d=/scratch/groups/mrivas/projects/PRS/private_output/202009_batch

check_max_valid_idx () {
    run_name=$1
    GBE_ID=$2
    ! grep 'Lambda idx' ${data_d}/${run_name}/${GBE_ID}/1_fit_w_val/snpnet.log | awk '{print $7}' | sed -e 's/\.$//g' | cat <(echo 0) /dev/stdin | sort -nr | awk 'NR==1'
}

check_largest_mem () {
    run_name=$1
    GBE_ID=$2
    ! cat ${data_d}/${run_name}/${GBE_ID}/1_fit_w_val/snpnet.log | grep -A1 '$mem' | tail -n1 | awk '{print $NF}'
}

if [ ! -d ${new_list_dir} ] ; then mkdir -p ${new_list_dir} ; fi

for subset in ${subsets[@]} ; do
    cat ${GBE_ID_lst_f} | sort | comm -12 /dev/stdin <(cat GBE_IDs/${subset}.lst | sort) > ${new_list_dir}/${subset}.lst
done

{
echo "#GBE_ID run_name max_valid_idx largest_mem" | tr ' ' '\t'
for subset in ${subsets[@]} ; do
    GBE_list_f=${new_list_dir}/${subset}.lst
    cat ${GBE_list_f} | awk 'length($0)>0' | while read GBE_ID ; do
    echo ${GBE_ID} ${subset} $(check_max_valid_idx ${subset} ${GBE_ID}) $(check_largest_mem ${subset} ${GBE_ID})
    done | tr ' ' '\t'
done
} > ${new_list_dir}/GBE_IDs.tsv

echo ${new_list_dir}/GBE_IDs.tsv
