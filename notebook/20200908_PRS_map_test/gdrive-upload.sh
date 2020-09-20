#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)

run_name="7_pfactor_v5"
refit="F"

GBE_ID=$1

####################
# parse optional cmdargs
if [ $# -gt 1 ] && [ $2 == "refit" ] ; then refit="T" ; fi
####################

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

project_d="/oak/stanford/groups/mrivas/projects/PRS"

data_d=${project_d}/private_output/$(basename ${SRCDIR})/${run_name}/${GBE_ID}/$([ "${refit}" == "T" ] && echo "2_refit" || echo "1_fit_w_val")

for ext in plot.png plot.pdf eval.tsv tsv ; do
    if [ -s ${data_d}/snpnet.${ext} ] ; then
        cp ${data_d}/snpnet.${ext} ${tmp_dir}/${GBE_ID}.${ext}
        rclone copy ${tmp_dir}/${GBE_ID}.${ext} gdrive://rivas-lab/projects/PRS/$(basename ${SRCDIR})/
        rm ${tmp_dir}/${GBE_ID}.${ext}
    fi
done

# We copy the file to GBE:
# /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/static/PRS_map
