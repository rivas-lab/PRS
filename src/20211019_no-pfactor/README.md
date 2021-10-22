# snpnet PRS models without penalty factors

## data location

- `/oak/stanford/groups/mrivas/projects/PRS/private_output/20211019_no-pfactor`

For the PRS fitting, we used the following location:

- `/scratch/groups/mrivas/projects/PRS/private_output/20211019_no-pfactor/snpnet.wo-pf`

## job submission commands

- submission for the initial fit (without refit)
  - `$ bash 2a_submit.sh GBE_ID_list.txt`
- submission for the refit
  - `$ bash 2a_submit.sh GBE_ID_list.txt refit`
- copy the results to `/oak`

```
cd /scratch/groups/mrivas/projects/PRS/private_output/20211019_no-pfactor/snpnet.wo-pf
find . -maxdepth 3 -type f -print0 | rsync -av --files-from=- --from0 ./ $(dirname $(pwdo))/
```
