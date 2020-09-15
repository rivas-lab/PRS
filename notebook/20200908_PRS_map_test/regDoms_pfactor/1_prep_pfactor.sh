#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)
VERSION="0.0.1"
NUM_POS_ARGS="1"

GBE_ID=$1

############################################################
# functions
############################################################

GBE_ID_to_HPO () {
    local GBE_ID=$1

    if   [ ${GBE_ID} == "HC269" ] ; then
        # https://hpo.jax.org/app/browse/term/HP:0003124
        # High cholesterol
        echo "HP:0003124"
    elif [ ${GBE_ID} == "HC382" ] ; then
        # https://hpo.jax.org/app/browse/term/HP:0002099
        # Asthma
        echo "HP:0002099"
    else
        echo "unsupported GBE ID ${GBE_ID}" >&2
        exit 1
    fi
    
}

############################################################
# tmp dir
############################################################
tmp_dir_root="$LOCAL_SCRATCH"
if [ ! -d ${tmp_dir_root} ] ; then mkdir -p $tmp_dir_root ; fi
tmp_dir="$(mktemp -p ${tmp_dir_root} -d tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX)"
# echo "tmp_dir = $tmp_dir" >&2
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

############################################################

ml load R/3.6 gcc

rds_in_f="/oak/stanford/groups/mrivas/ukbb24983/array-combined/snpnet/penalty.v4.rds"
regDom_repo_d="/oak/stanford/groups/mrivas/users/ytanigaw/repos/yk-tanigawa/regDoms-stat-gen"
cal_pvar="/oak/stanford/groups/mrivas/ukbb24983/cal/pgen/ukb24983_cal_cALL_v2_hg19.pvar"
project_dir="/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test"
out_d="${project_dir}/5_regDoms_pfactor_v4/"

HPO=$(GBE_ID_to_HPO ${GBE_ID})
HPO_str=$(echo ${HPO} | tr ':' '_')
HPO_pvar=${tmp_dir}/HPO.pvar
rds_out_f=${out_d}/$(basename ${rds_in_f} .rds).${GBE_ID}.rds

if [ ! -d ${out_d} ] ; then mkdir -p ${out_d} ; fi

bash ${regDom_repo_d}/src/4_intersect.sh --onto_id ${HPO} ${cal_pvar} hg19 > ${HPO_pvar}

Rscript update.pfactor.R ${HPO_pvar} ${rds_in_f} ${rds_out_f}
