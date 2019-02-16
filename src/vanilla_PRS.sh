#!/bin/bash
set -beEuo pipefail
usage () {
    echo "$0: Vanilla PRS" >&2
    echo "usage: $0 in_sumstats individuals_keep out_score" >&2
}

in_phe="$(readlink -f $1)"
phe_type="$2"
keep="$(readlink -f $3)"
out_dir_root="$(readlink -f $4)"
app_id=24983

# helper scripts
helper_dir="$(dirname $(dirname $(readlink -f $0)))/helper"
src1split="${helper_dir}/split-individuals.sh"
src2GWAS="${helper_dir}/ukb-cal_gwas-v5.sh"
src3clump="${helper_dir}/plink-clump.sh"
src4clumped_GWAS="${helper_dir}/filter-sumstats-to-clumped.sh"
src5score="${helper_dir}/plink-score.sh"

nPCs=4

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) ; echo "tmp_dir = $tmp_dir"
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

# file names
dir0input="${out_dir_root}/0_input"
dir1split="${out_dir_root}/1_split"
dir2GWAS="${out_dir_root}/2_GWAS"
dir3clump="${out_dir_root}/3_clump"
dir4clumped_GWAS="${out_dir_root}/4_clumped_GWAS"
dir5score="${out_dir_root}/5_score"

phe_name="$(basename ${in_phe} .phe)"
in_phe_copy="${dir0input}/${phe_name}.phe"
keep_copy="${dir0input}/$(basename ${keep})"
file1split="${dir1split}/${phe_name}"

tmp1keep=${tmp_dir}/${phe_name}.keep

# step 0: copy input
cp -a ${in_phe} ${in_phe_copy}
cp -a ${keep}   ${keep_copy}

# step 1: split
bash ${src1split}        ${in_phe_copy} ${file1split} ${phe_type} ${keep_copy}
cat  ${file1split}.val ${file1split}.train > ${tmp1keep} # combine validation and training sets

# step 2: GWAS
bash ${src2gwas}         ${dir2GWAS} ${in_phe_copy} ${phe_name} ${phe_type} ${tmp1keep} ${memory} ${threads} ${nPCs} ${app_id}

# To Do

bash ${src3clump}        ${}
bash ${src4clumped_GWAS} ${}
bash ${src5score}        ${}

exit 0

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

in_sumstats=$1
individuals_keep=$2
out_sumstats=$3

if [ $# -gt 3 ] ; then memory=$4 ; else memory=32000 ; fi
if [ $# -gt 4 ] ; then threads=$5 ; else threads=4 ; fi
if [ $# -gt 5 ] ; then app_id=$6 ; else app_id="24983" ; fi

plink_score ${in_sumstats} ${individuals_keep} ${out_score}

