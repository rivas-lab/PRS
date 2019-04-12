#!/bin/bash
set -beEuo pipefail
usage () {
    echo "$0: snpnet PRS" >&2
    echo "usage: $0 in_phe phe_type keep out_dir_root [memory] [threads] [app_id] [nPCs]" >&2
    echo "in_phe: phe file or GBE ID (the script automatically extracts phe file from the most recent master phe file)" >&2
}

software_versions () {
    which plink
    which plink2
    which bgzip
    which python
    which R
}

copy_with_check () {
    src=$1 
    dst=$2 
    if [ -f $src ] || [ -d $src ] ; then
        if [ ! -d $(dirname $dst) ] ; then mkdir -p $(dirname $dst) ; fi
    fi
    if [ -f $src ] && [ ! -f $dst ] ; then cp -a  $src $dst ; fi
    if [ -d $src ] && [ ! -d $dst ] ; then cp -ar $src $dst ; fi
}

# helper scripts
helper_dir="$(dirname $(dirname $(readlink -f $0)))/helper"
echo ${helper_dir}
src4score="${helper_dir}/plink-score.sh"
src5eval="${helper_dir}/compute_r_or_auc.py"

# dump software versions
software_versions

# parse command line args
if [ $# -lt 4 ] ; then usage ; exit 1 ; fi
in_phe_arg="$1"
phe_type="$2"
keep="$(readlink -f $3)"
out_dir_root="$(readlink -f $4)"

if [ $# -gt 4 ] ; then memory=$5 ;  else memory=32000 ; fi
if [ $# -gt 5 ] ; then threads=$6 ; else threads=4 ; fi
if [ $# -gt 6 ] ; then app_id=$7 ;  else app_id="24983" ; fi
if [ $# -gt 7 ] ; then nPCs=$8 ;    else nPCs=4 ; fi
if [ $# -gt 8 ] ; then file_covar=$9 ; else file_covar="${OAK}/private_data/ukbb/${app_id}/sqc/ukb${app_id}_GWAS_covar.phe" ; fi
if [ $# -gt 9 ] ; then covar_list_f=${10} ; else covar_list_f="" ; fi

echo $@ | tr " " "\n" | awk '{print NR, $0}' >&2
echo "" >&2
echo "$0 file_covar=${file_covar}" >&2

# file_covar="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20190406_biomarker_covar/biomarker_covar.tsv"
# covar_list_f="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20190406_biomarker_covar/biomarker_covar.colnames"

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) 
echo "tmp_dir = $tmp_dir" >&2
handler_exit () { rm -rf $tmp_dir ; }
#trap handler_exit EXIT

pop="$(basename $keep .phe | sed -e 's/ukb24983_//g')"

# file names
dir0input="${out_dir_root}/0_input"
dir1split="${out_dir_root}/1_split"
dir3snpnet="${out_dir_root}/3_snpnet"
if [ ${pop} == "white_british" ] ; then
    dir4score="${out_dir_root}/4_score"
    dir5eval="${out_dir_root}/5_eval"
else
    dir4score="${out_dir_root}/6_score_multi_ethnic/${pop}"
    dir5eval="${out_dir_root}/7_eval_multi_ethnic/${pop}"
fi

if [ -f ${in_phe_arg} ] ; then
    phe_name="$(basename ${in_phe_arg} .phe)"
else
    phe_name=${in_phe_arg}
fi

in_phe="${dir0input}/${phe_name}.phe"
file1split="${dir1split}/${phe_name}"
file3snpnet="${dir3snpnet}/${phe_name}"
file3snpnet_geno="${file3snpnet}.tsv.gz"
file3snpnet_covars="${file3snpnet}.covars.tsv.gz"

file4score="${dir4score}/${phe_name}.sscore"
file5eval="${dir5eval}/${phe_name}.sscore.eval"

# create directories
for d in ${out_dir_root} ${dir0input} ${dir3snpnet} ${dir4score} ${dir5eval}; do
    if [ ! -d ${d} ] ; then mkdir -p ${d} ; fi
done

# step 4 : PLINK --score
echo bash ${src4score} ${file3snpnet_geno} ${keep} ${file4score} ${phe_type} ${memory} ${threads} ${app_id}
bash ${src4score}      ${file3snpnet_geno} ${keep} ${file4score} ${phe_type} ${memory} ${threads} ${app_id}

# step 5 : evaluation
if [ ${pop} == "white_british" ] ; then
    keep_eval=${file1split}.test
else
    keep_eval=$keep
fi
echo python ${src5eval} -i ${file4score} -o ${file5eval} -k ${keep_eval} -p ${in_phe} -t ${phe_type} -c ${file_covar} -b ${file3snpnet_covars}
if [ ! -f ${file5eval} ]; then
    cat ${in_phe} | awk '(NR==1){print "#" $0}(NR>1){print $0}' | python ${src5eval} -i ${file4score} -o ${file5eval} -k ${keep_eval} -p /dev/stdin -t ${phe_type} -c ${file_covar} -b ${file3snpnet_covars}
fi
echo ""
