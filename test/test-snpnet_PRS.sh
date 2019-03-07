#!/bin/bash
set -beEuo pipefail

script=$(dirname $(dirname $(readlink -f $0)))/src/$(basename $0 | cut -c6-)

bash $script \
	/oak/stanford/groups/mrivas/dev-ukbb-tools/phenotypes/9796/INI30150.phe \
	qt \
	/oak/stanford/groups/mrivas/private_data/ukbb/24983/sqc/population_stratification/ukb24983_white_british.phe \
	/oak/stanford/groups/mrivas/projects/PRS/private_output/snpnet_PRS/test \
	120000 \
	10 \
	24983 \
	10

bash $script \
	/oak/stanford/groups/mrivas/dev-ukbb-tools/phenotypes/10136/INI5255.phe \
	qt \
	/oak/stanford/groups/mrivas/private_data/ukbb/24983/sqc/population_stratification/ukb24983_white_british.phe \
	/oak/stanford/groups/mrivas/projects/PRS/private_output/snpnet_PRS/test \
	120000 \
	10 \
	24983 \
	10

exit 0
bash $script \
	/oak/stanford/groups/mrivas/dev-ukbb-tools/phenotypes/9796/INI50.phe \
	qt \
	/oak/stanford/groups/mrivas/private_data/ukbb/24983/sqc/population_stratification/ukb24983_white_british.phe \
	/oak/stanford/groups/mrivas/projects/PRS/private_output/snpnet_PRS/test \
	120000 \
	10 \
	24983 \
	10

