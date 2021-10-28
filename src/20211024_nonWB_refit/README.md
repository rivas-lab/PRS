# non-WB refit

For non-WB populations, we tested whether using the "refit" of the snpnet model on the selected model help improve the predictive performance.

To that end, we implemented extract/exclude options in snpnet software (version 1.4.0) and used it from the wrapper script in this directory.

## job submission

- fit the models
  - `bash 2a_submit.sh GBE_ID_list.txt`
  - `bash 2a_submit.sh GBE_ID_list.txt refit`
- copy the results to `oak`
  - `cd /scratch/groups/mrivas/projects/PRS/private_output/20211024_nonWB_refit/snpnet.nonWBrefit`
  - `find . -maxdepth 4 -type f -print0 | rsync -av --files-from=- --from0 ./ $(dirname $(pwdo))/`

