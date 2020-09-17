#!/bin/bash
set -beEuo pipefail
usage () {
    echo "$0: The snpnet PRS on LD clumped variants" >&2
    echo "usage: $0 in_phe phe_type keep out_dir_root [memory] [threads] [app_id] [nPCs]" >&2
}

software_versions () {
    which plink
    which plink2
    which bgzip
    which python
    which R	
}

get_GWAS_filename () {
	phe_name=$1
	phe_type=$2
	app_id=$3

	# configure file names
	qt_suffix="linear"
	bin_suffix="logistic.hybrid"
	prefix="ukb${app_id}_v2.${phe_name}.PHENO1.glm"
	if   [ ${phe_type} == "qt" ] ; then
	    res_file="${prefix}.${qt_suffix}.gz"
	elif [ ${phe_type} == "bin" ] ; then
	    res_file="${prefix}.${bin_suffix}.gz"
	fi
	echo ${res_file}
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
src2GWAS="${helper_dir}/ukb-cal_gwas-v5.sh"
src3clump="${helper_dir}/plink-clump.sh"
src4bfile="${helper_dir}/plink-subset-bfile.sh"
src4extract="${helper_dir}/plink-extract.sh"
src5snpnet="${helper_dir}/snpnet_wrapper.sh"
src6score="${helper_dir}/plink-score.sh"
src7eval="${helper_dir}/compute_r_or_auc.py"
src_combine_phe_and_covar="${helper_dir}/combine_phe_and_covar.sh"
src_phe_extract="$OAK/users/$USER/repos/rivas-lab/ukbb-tools/06_phewas/extract_phe.sh"

# configure parameters
clump_p1_list=("1e-5" "1e-4" "1e-3")
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
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) ; echo "tmp_dir = $tmp_dir" >&2
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

# file names
dir0input="${out_dir_root}/0_input"
dir1split="${out_dir_root}/1_split"
dir2GWAS="${out_dir_root}/2_GWAS"
dir3clump="${out_dir_root}/3_clump"
dir4bfile="${out_dir_root}/4_bfile"
dir5snpnet="${out_dir_root}/5_snpnet"
dir6score="${out_dir_root}/6_score"
dir7eval="${out_dir_root}/7_eval"

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
file2GWAS="${dir2GWAS}/$( get_GWAS_filename $phe_name $phe_type $app_id )"
tmp_keep="${tmp_dir}/${phe_name}.keep"
tmp_phe="${tmp_dir}/${phe_name}.snpnet.phe"


# create directories
for d in ${out_dir_root} ${dir0input} ${dir1split} ${dir2GWAS} ${dir3clump} ${dir4bfile} ${dir5snpnet} ${dir6score} ${dir7eval} ; do
	if [ ! -d ${d} ] ; then mkdir -p ${d} ; fi
done

# step 0: copy input files
cat ${in_phe} | awk -v OFS='\t' '{print $1, $2, $3}' > ${in_phe_copy}
cat ${keep}   | awk -v OFS='\t' '{print $1, $2}'     > ${keep_copy}

# step 1: split cohorts into training ( 80 % = 60 % + 20 % ) and test ( 20 % ) sets
bash ${src1split} ${in_phe_copy} ${file1split} ${phe_type} ${keep_copy}
# combine validation and training sets for GWAS
cat  ${file1split}.val ${file1split}.train > ${tmp_keep} 
# prepare phe file for snpnet
if [ -f ${in_phe_arg} ] ; then
    bash ${src_combine_phe_and_covar} ${phe_name} ${in_phe_copy}    
else
    bash ${src_phe_extract} --covar ${phe_name}
fi | cut -f2- | tr "\t" "," | sed -e 's/^IID/ID/g' > ${tmp_phe}

# step 2: GWAS on training set
if [ ! -d ${dir2GWAS} ] ; then mkdir -p ${dir2GWAS} ; fi
bash ${src2GWAS} ${dir2GWAS} ${in_phe_copy} ${phe_name} ${phe_type} ${tmp_keep} ${memory} ${threads} ${nPCs} ${app_id}

for clump_p1 in ${clump_p1_list[@]} ; do # loop over different LD clumping parameters
    for d in ${dir3clump} ${dir4bfile} ${dir5snpnet} ${dir6score} ${dir7eval} ; do
	if [ ! -d ${d}/${clump_p1} ] ; then mkdir -p ${d}/${clump_p1} ; fi
    done
    file3clump="${dir3clump}/${clump_p1}/$( basename ${file2GWAS%.gz}.clumped.gz )"
    tmp4clumped_var_list=${tmp_dir}/${phe_name}.${clump_p1}.vars
    tmp4bfile_all_variants=${tmp_dir}/${phe_name}.all_variants
    file4bfile=${dir4bfile}/${clump_p1}/${phe_name}
    file5snpnet="${dir5snpnet}/${clump_p1}/${phe_name}"
    file5snpnet_geno="${file5snpnet}.tsv.gz"
    file5snpnet_covars="${file5snpnet}.covars.tsv.gz"
    file6score="${dir6score}/${clump_p1}/${phe_name}.sscore"
    file7eval="${dir7eval}/${clump_p1}/${phe_name}.sscore.eval"

    # step 3: LD clumping
    bash ${src3clump} ${file2GWAS} ${tmp_keep} ${file3clump} ${clump_p1} ${memory} ${threads} ${app_id}
    zcat ${file3clump} | awk 'NR>1 {print $3}' > ${tmp4clumped_var_list}
    
    # step 4: prepare files
    if [ ! -d ${file4bfile} ] ; then mkdir -p ${file4bfile} ; fi
    for split in ${split_names[@]} ; do
        # split PLINK file into train/val/test
        bash ${src4bfile} ${file1split}.${split} ${tmp4bfile_all_variants}.${split} ${memory} ${threads} ${app_id}                
        # extract LD clumped variants
        bash ${src4extract} ${tmp4bfile_all_variants}.${split} ${tmp4clumped_var_list} ${file4bfile}/${split} ${memory} ${threads} ${app_id}
    done

    # step 5: fit Lasso (snpnet)
    bash ${src5snpnet} ${file4bfile} ${tmp_phe} ${phe_name} ${phe_type} ${file_covar} ${file1split}.train ${file5snpnet} ${memory} ${threads} ${nPCs}

    # step 6 : PLINK --score
    bash ${src6score} ${file5snpnet_geno} ${keep_copy} ${file6score} ${phe_type} ${memory} ${threads} ${app_id}

    # step 7 : evaluation
    python ${src7eval} -i ${file6score} -o ${file7eval} -k ${file1split}.test -p ${in_phe_copy} -t ${phe_type} -c ${file_covar} -b ${file5snpnet_covars}
    echo ""

done
