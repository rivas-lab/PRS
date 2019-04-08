#!/bin/bash
set -beEuo pipefail

##############################
# configure variables
##############################

# temp directory root
[[ ${TMPROOT_LOCAL:-} -eq 1 ]] && return || readonly TMPROOT_LOCAL=${LOCAL_SCRATCH}

# computing resource requirements
[[ ${MEM:-} -eq 1 ]]           && return || readonly MEM="120000"
[[ ${CPU:-} -eq 1 ]]           && return || readonly CPU="10"

# src files
[[ ${SRC_UKBB_TOOLS:-}  -eq 1 ]] && return || readonly SRC_UKBB_TOOLS="${OAK}/users/${USER}/repos/rivas-lab/ukbb-tools"
[[ ${SRC_PHE_EXTRACT:-} -eq 1 ]] && return || readonly SRC_PHE_EXTRACT="${SRC_UKBB_TOOLS}/06_phewas/extract_phe.sh"


##############################
# create a default temp directory
##############################
PRS_common_tmp_dir="$(mktemp -d -p ${TMPROOT_LOCAL} tmp-PRS_common-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX)"
handler_exit_PRS_common_tmp_dir () { rm -rf ${PRS_common_tmp_dir} ; }
trap handler_exit_PRS_common_tmp_dir EXIT

##############################
# define helper functions
##############################
mkdir_p () {
    # run $ mkdir -p if the given directory does not exist
    dir=$1

    if [ ! -d ${dir} ] ; then mkdir -p ${dir} ; fi
}

error_option_req_arg (){
   echo "$PROGNAME: option requires an argument -- $1" >&2 ; exit 1
}


join_phe_and_covar (){
    phe_name=$1
    phe_file=$(readlink -f $2)
    covar_file=$(readlink -f $3)

    echo "join_phe_and_covar: phe_name=$phe_name" >&2
    echo "join_phe_and_covar: phe_file=$phe_file" >&2
    echo "join_phe_and_covar: covar_file=$covar_file" >&2

    echo "#FID IID ${phe_name} $(cat ${covar_file} | awk 'NR==1' | sed -e 's/#//g' | cut -f3- )" \
    | tr " " "\t"

    cat ${phe_file}  | awk '{print $2, $3}' | sort -k1b,1 \
    | join -1 1 -2 1 /dev/stdin <( cat ${covar_file} | cut -f2- | awk 'NR>1' | sort -k1b,1 ) \
    | awk '{print $1, $0}' \
    | tr " " "\t"

}


