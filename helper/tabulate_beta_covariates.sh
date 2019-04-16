#!/bin/bash
set -beEuo pipefail


usage () {
    echo "usage: $0 results_dir" >&2
}

cat_or_zcat () {
    local file=$1
    if [ ${file%.gz}.gz == ${file} ] ; then zcat $file ; else cat $file ; fi
}

show_covar () {
    local file=$1
    local phe=$2
    cat_or_zcat $file | awk -v phe=${phe} -v OFS='\t' '!/^#/ {print phe, $0}'
}

if [ $# -lt 1 ] ; then usage ; exit 1 ; fi
results_dir=$(readlink -f $1)

snpnet_res_dir="${results_dir%/}/3_snpnet"

echo "#Phe ID BETA mean std" | tr " " "\t"
find ${snpnet_res_dir} -name "*.covars.tsv.gz" | sort | while read f ; do
    show_covar $f $(echo $f | sed -e "s%${snpnet_res_dir}/%%g" | sed -e 's/.covars.tsv.gz//g')
    #$show_covar $f $f
done

