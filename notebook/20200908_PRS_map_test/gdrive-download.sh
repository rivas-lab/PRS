#!/bin/bash
set -beEuo pipefail

GBE_ID=$1

for ext in plot.png plot.pdf eval.tsv tsv ; do rclone copy gdrive://rivas-lab/projects/PRS/20200908_PRS_map_test/${GBE_ID}.${ext} . ; done

