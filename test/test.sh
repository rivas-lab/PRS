#!/bin/bash

#SBATCH --job-name=snpnet_HC
#SBATCH   --output=snpnet_HC.%A_%a.out
#SBATCH    --error=snpnet_HC.%A_%a.err
#SBATCH --time=1:00:00
#SBATCH --qos=normal
#SBATCH -p owners,normal,mrivas
#SBATCH --nodes=1
#SBATCH --cores=2
#SBATCH --mem=16000
#SBATCH --constraint="CPU_GEN:HSW|CPU_GEN:BDW|CPU_GEN:SKX"
#SBATCH --mail-type=END,FAIL
#################


cat $0 | egrep '^#SBATCH --mem=' | awk -v FS='=' '{print $NF}'

