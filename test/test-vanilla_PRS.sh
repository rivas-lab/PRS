#!/bin/bash
set -beEuo pipefail

script=$(dirname $(dirname $(readlink -f $0)))/src/$(basename $0 | cut -c6-)

bash $script \
	/oak/stanford/groups/mrivas/dev-ukbb-tools/phenotypes/9796/INI50.phe \
	qt \
	/oak/stanford/groups/mrivas/private_data/ukbb/24983/sqc/population_stratification/ukb24983_white_british.phe \
	/oak/stanford/groups/mrivas/projects/PRS/private_output/vanilla_PRS \
	32000 \
	4 \
	24983 \
	4

