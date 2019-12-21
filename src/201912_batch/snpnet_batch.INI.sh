#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
PROGNAME=$(basename $SRCNAME)
VERSION="0.0.1"
NUM_POS_ARGS="1"

source "$(dirname ${SRCNAME})/snpnet_batch_misc.sh"

############################################################
# wrapper functions
############################################################

show_default_helper () {
    cat ${SRCNAME} | grep -n __Default_parameters_ | tail -n+2 | awk -v FS=':' '{print $1}' | tr "\n" "\t" 
}

show_default () {
    cat ${SRCNAME} \
        | tail -n+$(show_default_helper | awk -v FS='\t' '{print $1+1}') \
        | head  -n$(show_default_helper | awk -v FS='\t' '{print $2-$1-1}')
}

usage () {
cat <<- EOF
	$PROGNAME (version $VERSION)
	Run snpnet_batch
	
	Usage: $PROGNAME [options] input_file
	  input_file      The input file
	
	Options:
	  --nCores     (-t)  Number of CPU cores
	  --memory     (-m)  The memory amount
	
	Default configurations for snpnet (please use the options above to modify them):
	#   snpnet_dir=${snpnet_dir}
EOF
    show_default | awk -v spacer="  " '{print spacer $0}'
}

############################################################
# tmp dir
############################################################
tmp_dir_root="$LOCAL_SCRATCH"
if [ ! -d ${tmp_dir_root} ] ; then mkdir -p $tmp_dir_root ; fi
local_tmp_dir="$(mktemp -p ${tmp_dir_root} -d tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX)"
# echo "tmp_dir = $tmp_dir" >&2
handler_exit () { rm -rf $local_tmp_dir ; }
trap handler_exit EXIT

############################################################
# parser start
############################################################
## == __Default_parameters_start__ == ##
nCores=4
mem=30000
offset=0
master_phe_file="/scratch/groups/mrivas/projects/PRS/private_data/phe_file/master.20191219.phe"
master_phe_info_file="/scratch/groups/mrivas/projects/PRS/private_data/phe_file/master.20191219.phe.info.tsv"
genotype_pfile="/scratch/groups/mrivas/ukbb/24983/array_combined/pgen/ukb24983_cal_hla_cnv.p"
covars="age,sex,Array,$(get_PCs_str 40)"
pop="white_british"
## == __Default_parameters__end___ == ##

declare -a params=()
for OPT in "$@" ; do
    case "$OPT" in 
        '-h' | '--help' )
            usage >&2 ; exit 0 ; 
            ;;
        '-v' | '--version' )
            echo $VERSION ; exit 0 ;
            ;;
        '-t' | '--nCores' )
            nCores=$2 ; shift 2 ;
            ;;
        '-m' | '--mem' )
            mem=$2 ; shift 2 ;
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

batch_idx="${params[0]}"

############################################################
# config params
############################################################

ml load snpnet_yt

batch_run_version="201912"
geno_dataset=$(basename $(dirname $(dirname $genotype_pfile)))
# gbe_id=INI5254
# phe_file="/oak/stanford/groups/mrivas/ukbb24983/phenotypedata/10136/21731/phe/INI5254.phe"
gbe_id=$(   get_phe_info_line_INI ${master_phe_info_file} ${batch_idx} | awk '{print $1}' )
phe_file=$( get_phe_info_line_INI ${master_phe_info_file} ${batch_idx} | awk '{print $2}' )
family=$(gbe_id_to_family ${gbe_id})
tmp_dir=$(get_snpnet_tmp_dir ${gbe_id} ${batch_run_version} ${geno_dataset})

############################################################
# body
############################################################

${snpnet_wrapper} --nCores ${nCores} --memory ${mem} \
--covariates ${covars} \
--glmnetPlus \
--verbose \
 ${genotype_pfile} ${master_phe_file} ${gbe_id} ${family} ${tmp_dir}

copy_results_from_tmp ${tmp_dir} $(phe_file_to_snpnet_res ${gbe_id} ${phe_file} ${geno_dataset} ${pop})
