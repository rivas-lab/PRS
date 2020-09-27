#!/bin/bash
set -beEuo pipefail

! cat 6_list_unfinished.20200924-232835.lst  | while read GBE_ID ; do find /scratch/groups/mrivas/projects/PRS/private_output/202009_batch -maxdepth 2 -mindepth 2 -type d -name $GBE_ID | grep -v bkup ;  done | while read d ; do grep -l "only 0's may be mixed with negative subscripts" $d/1_fit_w_val/snpnet.log ; done 

exit 0
| rev | awk -v FS='/' '{print $3}' | rev

