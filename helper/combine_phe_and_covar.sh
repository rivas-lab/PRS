#!/bin/bash
set -beEuo pipefail

PROGNAME=$(basename $(readlink -f $0))
VERSION="1.1"
NUM_POS_ARGS=3

usage () {
    echo "$PROGNAME (version $VERSION)"
    echo "Usage: $PROGNAME [options] phe_name phe.file"
}

source $(dirname $(readlink -f $0))/PRS_common.sh

##############################
# parser start
##############################
verbose_level=0
tmp_dir="$(mktemp --dry-run -d -p ${TMPROOT_LOCAL} tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX)"
# mem=${MEM}
# cpu=${CPU}        
covar_file=""
src_phe_extract=${SRC_PHE_EXTRACT}

echo "${PROGNAME} $@" >&2

declare -a params=()
for OPT in "$@" ; do
    case "$OPT" in 
        '-h' | '--help' )
            usage >&2 ; exit 0 ; 
            ;;
        '-v' | '--version' )
            echo $VERSION ; exit 0 ;
            ;;
        '-V' | '--verbose' )
            verbose_level=1 ; shift 1
            ;;            
        '--tmp_dir' )
            if [[ $# -gt 1 ]] || [[ "$2" =~ ^-+ ]]; then error_option_req_arg $1 ; fi
            tmp_dir=$2 ; shift 2
            ;;
#         '--mem' )
#             if [[ $# -gt 1 ]] || [[ "$2" =~ ^-+ ]]; then error_option_req_arg $1 ; fi
#             mem=$2 ; shift 2
#             ;;
#         '--cpu' )
#             if [[ $# -gt 1 ]] || [[ "$2" =~ ^-+ ]]; then error_option_req_arg $1 ; fi
#             cpu=$2 ; shift 2
#             ;;
#         '--covarfile' )
# #             if [[ $# -gt 1 ]] || [[ "$2" =~ ^-+ ]]; then error_option_req_arg $1 ; fi
#             if [[ $# -gt 1 ]] ; then error_option_req_arg $1 ; fi            
#             covar_file=$2 ; shift 2
#             ;;
        '--src_phe_extract' )
            if [[ $# -gt 1 ]] || [[ "$2" =~ ^-+ ]]; then error_option_req_arg $1 ; fi
            src_phe_extract=$2 ; shift 2
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
    exit 1 ; 
fi


phe_name=${params[0]}
phe_file=$(readlink -f ${params[1]})
covar_file=$(readlink -f ${params[2]})

echo "${PROGNAME} parsed : covar_file = ${covar_file}" >&2

##############################
# parser end
##############################

# create a temp directory
mkdir_p $tmp_dir 
if [ $verbose_level -gt 0 ] ; then 
    echo "${PROGNAME} tmp_dir = $tmp_dir" >&2
fi
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

# # generate temp covar file
# if [ ${covar_file}=="" ] ; then
#     covar_file=${tmp_dir}/covar.phe
#     bash ${src_phe_extract} --covaronly > ${covar_file}
# fi

# join phe file with the covar file
join_phe_and_covar ${phe_name} ${phe_file} ${covar_file}
