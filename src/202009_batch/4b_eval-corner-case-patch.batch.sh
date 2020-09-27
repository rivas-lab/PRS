#!/bin/bash
set -beEuo pipefail

find /scratch/groups/mrivas/projects/PRS/private_output/202009_batch -name "snpnet.RData" \
| parallel -j2 -k --eta 'bash 4b_eval-corner-case-patch.sh'
