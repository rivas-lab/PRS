#!/bin/bash
set -beEuo pipefail
usage () {
    echo "$0: snpnet PRS" >&2
    echo "usage: $0 in_phe phe_type keep out_dir_root [memory] [threads] [app_id] [nPCs]" >&2
    echo "in_phe: phe file or GBE ID (the script automatically extracts phe file from the most recent master phe file)"
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
src1split="${helper_dir}/split-individuals.sh"
src2bfile="${helper_dir}/plink-subset-bfile.sh"
src_phe_extract="$OAK/users/$USER/repos/rivas-lab/ukbb-tools/06_phewas/extract_phe.sh"
src_combine_phe_and_covar="${helper_dir}/combine_phe_and_covar.sh"
src3snpnet="${helper_dir}/snpnet_wrapper.sh"
src4score="${helper_dir}/plink-score.sh"
src5eval="${helper_dir}/compute_r_or_auc.py"

# configure parameters
split_names=("train" "val" "test")

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

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) ; echo "tmp_dir = $tmp_dir"
handler_exit () { rm -rf $tmp_dir ; }
#trap handler_exit EXIT

# file names
dir0input="${out_dir_root}/0_input"
dir1split="${out_dir_root}/1_split"
dir2bfile="${out_dir_root}/2_bfile"
dir3snpnet="${out_dir_root}/3_snpnet"
dir4score="${out_dir_root}/4_score"
dir5eval="${out_dir_root}/5_eval"

file_covar="${OAK}/private_data/ukbb/${app_id}/sqc/ukb${app_id}_GWAS_covar.phe"

if [ -f ${in_phe_arg} ] ; then
    in_phe=$(readlink -f ${in_phe_arg})
    phe_name="$(basename ${in_phe_arg} .phe)"
else
    phe_name=${in_phe_arg}
    in_phe="${tmp_dir}/${phe_name}.phe"
    bash ${src_phe_extract} ${phe_name} | awk 'NR>1' > ${in_phe}
fi

in_phe_copy="${dir0input}/${phe_name}.phe"
keep_copy="${dir0input}/${phe_name}.$(basename ${keep})"
file1split="${dir1split}/${phe_name}"
tmp2phe="${tmp_dir}/${phe_name}.snpnet.phe"

file3snpnet="${dir3snpnet}/${phe_name}"
file3snpnet_geno="${file3snpnet}.tsv.gz"
file3snpnet_covars="${file3snpnet}.covars.tsv.gz"
file4score="${dir4score}/${phe_name}.sscore"
file5eval="${dir5eval}/${phe_name}.sscore.eval"

# create directories
for d in ${out_dir_root} ${dir0input} ${dir1split} ${dir2bfile} ${dir3snpnet} ${dir4score} ${dir5eval}; do
    if [ ! -d ${d} ] ; then mkdir -p ${d} ; fi
done

# step 0: copy input files
cat ${in_phe} | awk -v OFS='\t' '{print $1, $2, $3}' > ${in_phe_copy}
cat ${keep}   | awk -v OFS='\t' '{print $1, $2}'     > ${keep_copy}

# step 1: split cohorts into training ( 60 % ), validation ( 20 % ), and test ( 20 % ) sets
bash ${src1split}        ${in_phe_copy} ${file1split} ${phe_type} ${keep_copy}

# step 2: prepare files
if [ ! -d ${dir2bfile}/${phe_name} ] ; then mkdir -p ${dir2bfile}/${phe_name} ; fi
for split in ${split_names[@]} ; do
    bash ${src2bfile}        ${file1split}.${split} ${dir2bfile}/${phe_name}/${split} ${memory} ${threads} ${app_id}
done
if [ -f ${in_phe_arg} ] ; then
    bash ${src_combine_phe_and_covar} ${phe_name} ${in_phe_copy} 
else
    bash ${src_phe_extract} --covar ${phe_name} 
fi | cut -f2- | tr "\t" "," | sed -e 's/^IID/ID/g' > ${tmp2phe}

# step 3: fit Lasso (snpnet)
echo bash ${src3snpnet} ${dir2bfile}/${phe_name} ${tmp2phe} ${phe_name} ${phe_type} ${file_covar} ${file1split}.train ${file3snpnet} ${memory} ${threads} ${nPCs}
bash      ${src3snpnet} ${dir2bfile}/${phe_name} ${tmp2phe} ${phe_name} ${phe_type} ${file_covar} ${file1split}.train ${file3snpnet} ${memory} ${threads} ${nPCs}

# step 4 : PLINK --score
echo bash ${src4score}        ${file3snpnet_geno} ${keep_copy} ${file4score} ${phe_type} ${memory} ${threads} ${app_id}
bash ${src4score}        ${file3snpnet_geno} ${keep_copy} ${file4score} ${phe_type} ${memory} ${threads} ${app_id}

# step 5 : evaluation
echo python ${src5eval} -i ${file4score} -o ${file5eval} -k ${file1split}.test -p ${in_phe_copy} -t ${phe_type} -c ${file_covar} -b ${file3snpnet_covars}
python ${src5eval} -i ${file4score} -o ${file5eval} -k ${file1split}.test -p ${in_phe_copy} -t ${phe_type} -c ${file_covar} -b ${file3snpnet_covars}
echo ""
