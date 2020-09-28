#!/bin/bash
set -beEuo pipefail

GBE_ID_lst_f=$(basename $0 .sh).$(date +%Y%m%d-%H%M%S).lst
new_list_dir=$1

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

cat /scratch/groups/mrivas/projects/PRS/private_output/202009_batch/snpnet.eval.tsv | awk '(NR > 1 && $8 > 0){print $1}' | sort -uV \
    | awk '(($0 != "INI50") && ($0 != "INI21001") && ($0 != "HC269") && ($0 != "HC382"))' | cat <(echo "#GBE_ID") /dev/stdin  > ${GBE_ID_lst_f}

if [ ! -d ${new_list_dir} ] ; then mkdir -p ${new_list_dir} ; fi

for subset in ${subsets[@]} ; do
    cat ${GBE_ID_lst_f} | egrep -v '#' | sort | comm -12 /dev/stdin <(cat GBE_IDs/${subset}.lst | sort) > ${new_list_dir}/${subset}.lst
done

