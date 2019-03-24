#!/bin/bash
set -beEuo pipefail

memory=120000
threads=10
app_id=24983
nPCs=10

dataset="test"
population_keep="${OAK}/private_data/ukbb/24983/sqc/population_stratification/ukb24983_white_british.phe"

repo_dir="$(dirname $(dirname $(readlink -f $0)))"
script="${repo_dir}/src/$(basename $0 | cut -c6-)"
method="$(basename ${script%.sh} )"
output_dir="${repo_dir}/private_output/${method}/${dataset}"
if [ ! -d ${output_dir} ] ; then mkdir -p ${output_dir} ; fi

bash $script \
	INI5255 \
	qt \
    ${population_keep} ${output_dir} \
	${memory} ${threads} ${app_id} ${nPCs}

exit 0

bash $script \
	HC276 \
	bin \
	${population_keep} ${output_dir} \
	${memory} ${threads} ${app_id} ${nPCs}

exit 0
bash $script \
	INI30150 \
	qt \
	${population_keep} ${output_dir} \
	${memory} ${threads} ${app_id} ${nPCs}

bash $script \
	INI50 \
	qt \
    ${population_keep} ${output_dir} \
	${memory} ${threads} ${app_id} ${nPCs}
