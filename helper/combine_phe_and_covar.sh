#!/bin/bash
set -beEuo pipefail

PROGNAME=$(basename $(readlink -f $0))
VERSION="1.0"
NUM_POS_ARGS=2

usage () {
    echo "$PROGNAME (version $VERSION)"
    echo "Usage: $PROGNAME phe_name phe.file"
}

if [ $# -lt ${NUM_POS_ARGS} ]; then
    echo "${NUM_POS_ARGS} positional arguments are required" >&2 ; usage >&2 ; exit 1 ; 
fi

phe_name=$1
phe_file=$(readlink -f $2)

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) ; echo "tmp_dir = $tmp_dir" >&2
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

src_phe_extract="$OAK/users/$USER/repos/rivas-lab/ukbb-tools/05_phewas/extract_phe.sh"

covar_file=${tmp_dir}/covar.phe

bash ${src_phe_extract} --covaronly > ${covar_file}

echo "#FID IID ${phe_name} $(cat ${covar_file} | awk 'NR==1' | sed -e 's/#//g' | cut -f3- )" | tr " " "\t"

cat $phe_file  | awk '{print $2, $3}' | sort -k1b,1 \
| join -1 1 -2 1 /dev/stdin <( cat ${covar_file} | cut -f2- | awk 'NR>1' | sort -k1b,1 ) \
| awk '{print $1, $0}' \
| tr " " "\t"

