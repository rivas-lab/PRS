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
phenotype_name=$2
family=$3
geno_dir=$4
out_dir_root=$5
phe_file=$6
covariates=$7
# "None" or "age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"
cores=$8
mem=$9

############################################################
# functions
############################################################
source "${src_dir}/snpnet_misc.sh"

############################################################

# We were originally copying the files to LOCAL_SCRATCH. 
# We don't do it anymore (simply because LOCAL_SCRATCH is not large enough to keep the copy)
tmp_geno_dir="${geno_dir}" 
# copy the genotype data to SCRATCH
#tmp_geno_dir=${tmp_dir}/snpnet-geno
#copy_geno_to_tmp ${geno_dir} ${tmp_geno_dir}

prevIter="$(find_prevIter ${out_dir_root} ${phenotype_name})"

# configure and run
config_file=${tmp_dir}/config.tsv
{
echo "#key val"
echo "snpnet_dir ${snpnet_dir}"
echo "mem2bufferSizeDivisionFactor 5"
echo "cpu ${cores}"
echo "mem ${mem}"
echo "niter 100"
echo "genotype_dir ${tmp_geno_dir}"
echo "out_dir_root ${out_dir_root}"
echo "phenotype_file ${phe_file}"
echo "phenotype_name ${phenotype_name}"
echo "family ${family}"
echo "covariates ${covariates}"
echo "prevIter ${prevIter}"
} | tr " " "\t" > ${config_file}

echo "===================config_file===================" >&2
cat ${config_file} >&2
echo "===================config_file===================" >&2

Rscript "${src_dir}/snpnet_wrapper.R" "${config_file}"

