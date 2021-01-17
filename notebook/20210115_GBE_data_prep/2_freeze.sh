#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

data_d=/scratch/groups/mrivas/projects/PRS
tar_f=${data_d}/GBE_data.$(date +%Y%m%d-%H%M%S).tar.gz

ml load rclone

cd ${data_d}

tar -czvf $(basename ${tar_f}) GBE_data

rclone copy ${tar_f} gdrive://rivas-lab/projects/PRS/

