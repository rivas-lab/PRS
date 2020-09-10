# PRS map 202005 version

## summary

- We applied `snpnet` for HC phenotypes.
- Master phe file version `20200522` --> meaning that the local PCs used in this batch was of low quality.

## origin of the HC phenotype list

- ukbb-tools repo (commit ID: `7bf9ddb2c591268360485b0e4fea61e2a0f5be5a`)
  - `~/repos/rivas-lab/ukbb-tools/02_phenotyping/extras/highconfidenceqc/highconfidenceqc_gbe_map.tsv`

## data location

- output: `/oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch`
- [Google Spreadsheet](https://docs.google.com/spreadsheets/d/12rtIrNFQUJFYlfgLqNLbgKxM6PAOl7b8C34vXiqHsU8/edit?usp=sharing)

# penalty factors in `snpnet`

- `/oak/stanford/groups/mrivas/ukbb24983/array_combined/snpnet/penalty.rds`

1. PTVs get .5
2. Protein altering variants is .75
3. Others 1

## scripts

2_list_unfinished.err.20200602-233121.txt
2_list_unfinished.lst.20200602-233121.txt
2_list_unfinished.sh

```{bash}
cat 2_list_unfinished.lst.20200602-233121.txt | awk 'NR>1' | while read GBE_ID ; do bash 3_export_intermediate.sh $GBE_ID ; done
```

compute AUC

```{bash}
bash 5_run_eval.sh 4_list_GBE_IDs_with_sscore.20200608-223851.txt
```

```
cat snpnet.gwasP.tsv  | awk -v OFS='\t' '($7 == "Others"){print $1, $2, $2+1, $3}' | sed -e "s/^XY/X/g" > snpnet.gwasP.Others.bed
```
