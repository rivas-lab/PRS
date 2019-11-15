#!/bin/bash
set -beEuo pipefail

src_dir="$(dirname $(readlink -f $0))"

############################################################
# tmp dir
############################################################
tmp_dir_root="$LOCAL_SCRATCH"
if [ ! -d ${tmp_dir_root} ] ; then mkdir -p $tmp_dir_root ; fi
tmp_dir="$(mktemp -p ${tmp_dir_root} -d tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX)"
echo "tmp_dir = $tmp_dir" >&2
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

############################################################
# input args
############################################################
snpnet_dir=$1
genotype_pfile=$2
phe_file=$3
phenotype_name=$4
covariates=$5
# "None" or "age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"
split_col=$6
family=$7
out_dir_root=$8
cores=$9
mem=${10}


############################################################
# functions
############################################################
source "${src_dir}/snpnet_misc.sh"

############################################################
if [ ! -d ${out_dir_root} ] ; then mkdir -p ${out_dir_root} ; fi
prevIter="$(find_prevIter ${out_dir_root} ${phenotype_name})"

# configure and run
config_file=${tmp_dir}/config.tsv

cat <<- EOF | tr " " "\t" > ${config_file}
	#key val
	snpnet_dir ${snpnet_dir}
	mem2bufferSizeDivisionFactor 5
	cpu ${cores}
	mem ${mem}
	niter 100
	genotype_pfile ${genotype_pfile}
	out_dir_root ${out_dir_root}
	phenotype_file ${phe_file}
	phenotype_name ${phenotype_name}
	family ${family}
	split_col ${split_col}
	covariates ${covariates}
	prevIter ${prevIter}
EOF

echo "===================config_file===================" >&2
cat ${config_file} >&2
echo "===================config_file===================" >&2


Rscript "${src_dir}/snpnet_wrapper.v2.1.R" "${config_file}"

