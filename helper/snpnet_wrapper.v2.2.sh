#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
PROGNAME=$(basename $SRCNAME)
VERSION="2.2"
NUM_POS_ARGS="5"

source "$(dirname ${SRCNAME})/snpnet_misc.sh"


############################################################
# functions
############################################################

usage () {
cat <<- EOF
	$PROGNAME (version $VERSION)
	Run snpnet
	  Usage: $PROGNAME [options] genotype_pfile phe_file phenotype_name family out_dir_root
	  Options:
	  --snpnet_dir
	  --nCores     (-t)
	  --memory     (-m)
	  --niter      (-n)
	  --covariates (-c)
	  --split_col  (-s)
	  --status_col
	  --no_save
	  --verbose
	  --no_validation
EOF
}

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
# parser start
############################################################
snpnet_dir="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet"
nCores=4
mem=30000
niter=100
covariates="None"
split_col="split"
status_col="status"
save=T
KKT_verbose=F
verbose=F
validation=T

declare -a params=()
for OPT in "$@" ; do
    case "$OPT" in 
        '-h' | '--help' )
            usage >&2 ; exit 0 ; 
            ;;
        '-v' | '--version' )
            echo $VERSION ; exit 0 ;
            ;;
        '--snpnet_dir' )
            snpnet_dir=$2 ; shift 2 ;
            ;;
        '-t' | '--nCores' )
            nCores=$2 ; shift 2 ;
            ;;
        '-m' | '--memory' )
            memory=$2 ; shift 2 ;
            ;;
        '-n' | '--niter' )
            niter=$2 ; shift 2 ;
            ;;
        '-c' | '--covariates' )
            covariates=$2 ; shift 2 ;            
            ;;
        '-s' | '--split_col' )
            split_col=$2 ; shift 2 ;            
            ;;
        '--status_col' )
            status_col=$2 ; shift 2 ;            
            ;;
        '--no_save' )
            save="F" ; shift 1 ;            
            ;;
        '--verbose' )
            verbose="T" ; KKT_verbose="T" ; shift 1 ;            
            ;;
        '--no_validation' )
            validation="F" ; shift 1 ;            
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

genotype_pfile="${params[0]}"
phe_file="${params[1]}"
phenotype_name="${params[2]}"
family="${params[3]}"
out_dir_root="${params[4]}"

############################################################
if [ ! -d ${out_dir_root} ] ; then mkdir -p ${out_dir_root} ; fi
prevIter="$(find_prevIter ${out_dir_root} ${phenotype_name})"
results_dir="${out_dir_root}/${phenotype_name}/results"

# configure and run
config_file=${tmp_dir}/config.tsv

cat <<- EOF | tr " " "\t" > ${config_file}
	#key val
	genotype.pfile ${genotype_pfile}
	phenotype.file ${phe_file}
	phenotype.name ${phenotype_name}
	family ${family}
	out.dir.root ${out_dir_root}
	results.dir ${results_dir}
	prevIter ${prevIter}
	snpnet.dir ${snpnet_dir}
	nCores ${nCores}
	mem ${mem}
	niter ${niter}
	covariates ${covariates}
	split.col ${split_col}
	status.col ${status_col}
	save ${save}
	KKT.verbose ${KKT_verbose}
	verbose ${verbose}
	validation ${validation}
EOF

echo "===================config_file===================" >&2
cat ${config_file} >&2
echo "===================config_file===================" >&2


Rscript "$(dirname ${SRCNAME})/snpnet_wrapper.v2.2.R" "${config_file}"

