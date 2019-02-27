#!/bin/bash
set -beEuo pipefail
usage () {
    echo "$0: Vanilla PRS" >&2
    echo "usage: $0 in_phe phe_type keep out_dir_root [memory] [threads] [app_id] [nPCs]" >&2
}

software_versions () {
    which plink
    which plink2
    which bgzip
    which python
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
src4clumped_GWAS="${helper_dir}/filter-sumstats-to-clumped.sh"
src5score="${helper_dir}/plink-score.sh"
src6eval="${helper_dir}/compute_r_or_auc.py"

# configure parameters
clump_p1_list=("1e-5" "1e-4" "1e-3")
#clump_p1_list=("1e-4" "1e-3")

# dump software versions
software_versions

# parse command line args
if [ $# -lt 4 ] ; then usage ; exit 1 ; fi
in_phe="$(readlink -f $1)"
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
trap handler_exit EXIT

# file names
dir0input="${out_dir_root}/0_input"
dir1split="${out_dir_root}/1_split"
dir2GWAS="${out_dir_root}/2_GWAS"
dir3clump="${out_dir_root}/3_clump"
dir4clumped_GWAS="${out_dir_root}/4_clumped_GWAS"
dir5score="${out_dir_root}/5_score"
dir6eval="${out_dir_root}/6_eval"

phe_name="$(basename ${in_phe} .phe)"
in_phe_copy="${dir0input}/${phe_name}.phe"
keep_copy="${dir0input}/${phe_name}.$(basename ${keep})"
file1split="${dir1split}/${phe_name}"
file2GWAS="${dir2GWAS}/$( get_GWAS_filename $phe_name $phe_type $app_id )"
tmp1keep="${tmp_dir}/${phe_name}.keep"
file_covar="${OAK}/private_data/ukbb/${app_id}/sqc/ukb${app_id}_GWAS_covar.phe"

# create directories
for d in ${out_dir_root} ${dir0input} ${dir1split} ${dir2GWAS} ${dir3clump} ${dir4clumped_GWAS} ${dir5score} ${dir6eval} ; do
	if [ ! -d ${d} ] ; then mkdir -p ${d} ; fi
done

# step 0: copy input files
cat ${in_phe} | awk -v OFS='\t' '{print $1, $2, $3}' > ${in_phe_copy}
cat ${keep}   | awk -v OFS='\t' '{print $1, $2}'     > ${keep_copy}

# step 1: split cohorts into training ( 80 % = 60 % + 20 % ) and test ( 20 % ) sets
bash ${src1split}        ${in_phe_copy} ${file1split} ${phe_type} ${keep_copy}
cat  ${file1split}.val ${file1split}.train > ${tmp1keep} # combine validation and training sets

# step 2: GWAS on training set
if [ ! -d ${dir2GWAS} ] ; then mkdir -p ${dir2GWAS} ; fi
bash ${src2GWAS}        ${dir2GWAS} ${in_phe_copy} ${phe_name} ${phe_type} ${tmp1keep} ${memory} ${threads} ${nPCs} ${app_id}

for clump_p1 in ${clump_p1_list[@]} ; do # loop over different LD clumping parameters
    for d in ${dir3clump} ${dir4clumped_GWAS} ${dir5score} ${dir6eval} ; do
	if [ ! -d ${d}/${clump_p1} ] ; then mkdir -p ${d}/${clump_p1} ; fi
    done
    file3clump="${dir3clump}/${clump_p1}/$( basename ${file2GWAS%.gz}.clumped.gz )"
    file4clumped_GWAS="${dir4clumped_GWAS}/${clump_p1}/$( basename ${file2GWAS} )"
    file5score="${dir5score}/${clump_p1}/$( basename ${file2GWAS%.gz} ).sscore"
    file6eval="${dir6eval}/${clump_p1}/$( basename ${file2GWAS%.gz} ).sscore.eval"

    # step 3: LD clumping
    echo bash ${src3clump}        ${file2GWAS} ${tmp1keep} ${file3clump} ${clump_p1} ${memory} ${threads} ${app_id}
    bash ${src3clump}        ${file2GWAS} ${tmp1keep} ${file3clump} ${clump_p1} ${memory} ${threads} ${app_id}

    # step 4 : subset GWAS hits to LD clumped markers
    echo bash ${src4clumped_GWAS} ${file2GWAS} ${file3clump} ${file4clumped_GWAS}
    bash ${src4clumped_GWAS} ${file2GWAS} ${file3clump} ${file4clumped_GWAS}

    # step 5 : the vanilla PRS
    echo bash ${src5score}        ${file4clumped_GWAS} ${keep_copy} ${file5score} ${phe_type} ${memory} ${threads} ${app_id}
    bash ${src5score}        ${file4clumped_GWAS} ${keep_copy} ${file5score} ${phe_type} ${memory} ${threads} ${app_id}

    # step 6 : evaluation
    echo python ${src6eval} -i ${file5score} -o ${file6eval} -k ${file1split}.test -p ${in_phe_copy} -t ${phe_type} -c ${file_covar}
    python ${src6eval} -i ${file5score} -o ${file6eval} -k ${file1split}.test -p ${in_phe_copy} -t ${phe_type} -c ${file_covar}
    echo ""
done

