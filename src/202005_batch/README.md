
## origin of the HC phenotype list

- ukbb-tools repo (commit ID: `7bf9ddb2c591268360485b0e4fea61e2a0f5be5a`)
  - `~/repos/rivas-lab/ukbb-tools/02_phenotyping/extras/highconfidenceqc/highconfidenceqc_gbe_map.tsv`

## data location

- output: `/oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch`

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

