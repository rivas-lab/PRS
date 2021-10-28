# snpnet PRS models for admixed individuals (others)

We fit snpnet using the individuals in `others`. The training, validation, and test set split is specified in population stratification version 20211020.

## data location

- `/oak/stanford/groups/mrivas/projects/PRS/private_output/20211020_admixed`

For the PRS fitting, we used the following location:

- `/scratch/groups/mrivas/projects/PRS/private_output/20211020_admixed/snpnet.admixed`

## job submission commands

- submission for the initial fit (without refit)
  - `$ bash 2a_submit.sh GBE_ID_list.txt`
- submission for the refit
  - `$ bash 2a_submit.sh GBE_ID_list.txt refit`
- copy the results to `/oak`

```
cd /scratch/groups/mrivas/projects/PRS/private_output/20211020_admixed/snpnet.admixed
find . -maxdepth 3 -type f -print0 | rsync -av --files-from=- --from0 ./ $(dirname $(pwdo))/
```

