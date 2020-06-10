#!/bin/bash
set -beEuo pipefail

out=6_aggregate_eval.$(date +%Y%m%d-%H%M%S).tsv

{
cat /oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch/HC1/snpnet.eval.tsv | egrep '^#'

find /oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch -name "snpnet.eval.tsv" | sort -V | while read f ; do cat $f | egrep -v '^#' ; done
} > ${out}

echo $out

