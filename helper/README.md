# helper scripts

This directory has helper scripts to run `snpnet`

## List of scripts in this directory

### `snpnet_misc.sh`

This script has miscellaneous functions that are used in other scripts.

### `snpnet_wrapper.{sh,R}`

`snpnet_wrapper.R` takes a config file and run `snpnet::snpnet()` function.
`snpnet_wrapper.sh` generates an appropriate config file.

In most cases, you'd like to run this script using a SLURM job.
`example_sbatch_array.sh` and `example_sbatch_array_imp.sh` are examples of the job scripts for array combined data and array & imputation combined data, respectively.

We assume you've prepared a phenotype file that contains the response variable(s) as well as the covariates.
The file needs to be placed at `${data_dir_root}/${phe_file}`.

For covariate, a comma separated list or 'None' are accepted.
For example the followings are valid input for "covariate" string.
- `None`
- `age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10`
