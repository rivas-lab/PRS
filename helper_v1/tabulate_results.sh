#!/bin/bash
set -beEuo pipefail

default_icdinfo=$OAK/users/$USER/repos/rivas-lab/wiki/ukbb/icdinfo/icdinfo.txt

usage () {
    echo "usage: $0 results_dir [PRS_type ( clumped_snpnet |  snpnet | vanilla | snpnet_biomarker ) default: vanilla] [icdinfo.txt default: $default_icdinfo ]" >&2
}

# parse command line args
if [ $# -lt 1 ] ; then usage ; exit 1 ; fi
results_dir=$(readlink -f $1)
if [ $# -gt 1 ] ; then PRS_type=$2 ; else PRS_type='vanilla' ; fi
if [ ${PRS_type} != 'clumped_snpnet' ] && [ ${PRS_type} != 'snpnet' ] && [ ${PRS_type} != 'vanilla' ] && [ ${PRS_type} != 'snpnet_biomarker' ] ; then usage ; exit 1 ; fi
if [ $# -gt 2 ] ; then icdinfo=$3 ;  else icdinfo=${default_icdinfo} ; fi

if [ ${PRS_type} != 'snpnet_biomarker' ] ; then

{
echo "#GBE_ID PRS_model phe_type features R_or_AUC phe_name"
find ${results_dir} -type f -name "*.eval" \
| while read f ; do cat $f ; echo "" ; done \
| awk 'length($0)>0' \
| sed -e "s%${results_dir}/%%" \
| sed -e 's/ukb24983_v2.//g' \
| sed -e 's/ukb16698_v2.//g' \
| sed -e 's/.sscore//g' \
| sed -e 's/.PHENO1.glm.linear//g' \
| sed -e 's/.PHENO1.glm.logistic.hybrid//g' \
| {
  if [ ${PRS_type} == 'snpnet' ] ; then
    awk -v FS='\t' -v OFS='\t' -v PRS_type=${PRS_type} '{split($1, a, "/*"); print a[length(a)], PRS_type "_PRS", $2, $3, $4}'
  else # vanilla PRS
    awk -v FS='\t' -v OFS='\t' -v PRS_type=${PRS_type} '{split($1, a, "/*"); print a[length(a)], PRS_type "_PRS_" a[length(a) - 1], $2, $3, $4}'
  fi
} \
| sed -e  's/.adjusted//g' \
| sort -k1b,1 \
| join -1 1 -2 1 /dev/stdin <( cat ${icdinfo} | awk -v FS='\t' '{print $1, $3, $2}' | sort -k1b,1 ) \
| sort -k1V,1 -k2V,2 -k4,4 
} | tr " " "\t"

else

{
echo "#Population GBE_ID PRS_model phe_type features R_or_AUC" | tr " " "\t"
find ${results_dir} -type f -name "*.eval" \
| while read f ; do cat $f ; echo "" ; done \
| awk 'length($0)>0' \
| sed -e "s%${results_dir}/%%" \
| sed -e 's/ukb24983_v2.//g' \
| sed -e 's/ukb16698_v2.//g' \
| sed -e 's/.sscore//g' \
| sed -e 's/.PHENO1.glm.linear//g' \
| sed -e 's/.PHENO1.glm.logistic.hybrid//g' \
| awk -v FS='\t' -v OFS='\t' -v PRS_type=${PRS_type%_biomarker} '{split($1, a, "/*"); print a[length(a) - 1], a[length(a)], PRS_type, $2, $3, $4}' \
| sed -e 's/4_score/white_british/g' \
| sort -k1V,1 -k2V,2 -k4,4
}

fi

