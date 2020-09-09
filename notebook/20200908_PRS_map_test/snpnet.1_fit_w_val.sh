#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)
VERSION="0.0.1"
NUM_POS_ARGS="2"

############################################################
# functions
############################################################

show_default_helper () {
    cat ${SRCNAME} | grep -n Default | tail -n+3 | awk -v FS=':' '{print $1}' | tr "\n" "\t" 
}

show_default () {
    cat ${SRCNAME} \
        | tail -n+$(show_default_helper | awk -v FS='\t' '{print $1+1}') \
        | head  -n$(show_default_helper | awk -v FS='\t' '{print $2-$1-1}')
}

usage () {
cat <<- EOF
	$PROGNAME (version $VERSION)
	Run snpnet
	
	Usage: $PROGNAME [options] input_file
	  input_file      The input file
	
	Options:
	  --cpus     (-t)  Number of CPU cores
	  --mem      (-m)  The memory amount
	
	Default configurations:
EOF
    show_default | awk -v spacer="  " '{print spacer $0}'
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
# parser start
############################################################
## == Default parameters (start) == ##
cpus=6
mem=30000
weighted=T
## == Default parameters (end) == ##

declare -a params=()
for OPT in "$@" ; do
    case "$OPT" in 
        '-h' | '--help' )
            usage >&2 ; exit 0 ; 
            ;;
        '-v' | '--version' )
            echo $VERSION ; exit 0 ;
            ;;
        '-c' | '--cpus' )
            cpus=$2 ; shift 2 ;
            ;;
        '-m' | '--mem' )
            mem=$2 ; shift 2 ;
            ;;
        '--no-weight' )
            weighted="F" ; shift 1 ;
            ;;
        '-w' | '--weighted' )
            weighted="T" ; shift 1 ;
            ;;
        '--'|'-' )
            shift 1 ; params+=( "$@" ) ; break
            ;;
        -*)
            echo "$PROGNAME: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2 ; exit 1
            ;;
        *)
            if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-+ ]]; then
                params+=( "$1" ) ; shift 1
            fi
            ;;
    esac
done

if [ ${#params[@]} -lt ${NUM_POS_ARGS} ]; then
    echo "${PROGNAME}: ${NUM_POS_ARGS} positional arguments are required" >&2
    usage >&2 ; exit 1 ; 
fi

phenotype_name=${params[0]}
family=${params[1]}
############################################################

echo "[job] cpus:${cpus} mem:${mem}"
echo ${params[@]}

############################################################
# Required arguments for ${snpnet_wrapper} script
############################################################
genotype_pfile="/scratch/groups/mrivas/ukbb24983/array_combined/pgen/ukb24983_cal_hla_cnv"
phe_file="/scratch/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20200828.phe.zst"
project_dir="/oak/stanford/groups/mrivas/projects/PRS/private_output/$(basename ${SRCDIR})"
results_dir="${project_dir}/${phenotype_name}"

############################################################
# Additional optional arguments for ${snpnet_wrapper} script
############################################################
covariates="age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"
keep="/oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification_w24983_20200828/ukb24983_white_british.phe"
if [ "${weighted}" == "T" ] ; then
    p_factor_file="/oak/stanford/groups/mrivas/ukbb24983/array-combined/snpnet/penalty.rds"
else
    p_factor_file="None"
fi

############################################################
# Configure other parameters
############################################################
# ml load snpnet_yt/dev R/3.6 gcc
ml load snpnet_yt/0.3.13 R/3.6 gcc

############################################################

echo "[$0 $(date +%Y%m%d-%H%M%S)] [start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2

bash ${snpnet_wrapper} \
--nCores ${cpus} --memory ${mem} \
--covariates ${covariates} \
--verbose --save_computeProduct --glmnetPlus \
--keep ${keep} \
--p_factor_file ${p_factor_file} \
${genotype_pfile} \
${phe_file} \
${phenotype_name} \
${family} \
${results_dir}/1_fit_w_val

Rscript ${SRCDIR}/snpnet.eval.R ${phenotype_name} ${results_dir}/1_fit_w_val

echo "[$0 $(date +%Y%m%d-%H%M%S)] [end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2

