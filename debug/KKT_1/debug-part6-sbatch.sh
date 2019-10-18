#!/bin/bash
set -beEuo pipefail

sbatch --cores=1 --mem=30000 debug-part6.sh 1 30000
sbatch --cores=2 --mem=30000 debug-part6.sh 2 30000
sbatch --cores=4 --mem=30000 debug-part6.sh 4 30000
sbatch --cores=6 --mem=30000 debug-part6.sh 6 30000
sbatch --cores=6 --mem=40000 debug-part6.sh 6 40000
sbatch --cores=6 --mem=50000 debug-part6.sh 6 50000
sbatch --cores=6 --mem=60000 debug-part6.sh 6 60000

