# KKT check takes too long

### KKT takes 3-6 hours per iteration in the original run.

```
[ytanigaw@sh-109-53 ~/repos/rivas-lab/PRS/debug/KKT_1]$ cat snpnet.50984390.out | egrep 'Iteration|End checking KKT condition'
Iteration 0. Now time: 2019-09-25 16:11:58
Iteration 1. Now time: 2019-09-25 17:25:17
  End checking KKT condition. Elapsed time: 5.3378 hours
Iteration 2. Now time: 2019-09-25 22:52:57
  End checking KKT condition. Elapsed time: 3.2644 hours
Iteration 3. Now time: 2019-09-26 02:15:18
  End checking KKT condition. Elapsed time: 3.4957 hours
Iteration 4. Now time: 2019-09-26 05:51:59
  End checking KKT condition. Elapsed time: 3.683 hours
Iteration 5. Now time: 2019-09-26 09:39:58
  End checking KKT condition. Elapsed time: 3.5924 hours
Iteration 6. Now time: 2019-09-26 13:22:18
  End checking KKT condition. Elapsed time: 3.5996 hours
Iteration 7. Now time: 2019-09-26 17:05:00
  End checking KKT condition. Elapsed time: 3.2856 hours
Iteration 8. Now time: 2019-09-26 20:29:09
[ytanigaw@sh-109-53 ~/repos/rivas-lab/PRS/debug/KKT_1]$ tail snpnet.50984390.err
Loaded glmnet 2.0-20

Loading required package: survival
Loading snpnet
Loading required namespace: glmnetPlus
Extracting number of samples and rownames from train.fam...
Extracting number of variants and colnames from train.bim...
Extracting number of samples and rownames from val.fam...
Extracting number of variants and colnames from val.bim...
slurmstepd: error: *** JOB 50984390 ON sh-109-56 CANCELLED AT 2019-09-26T23:42:43 DUE TO TIME LIMIT ***
```

### The running parameters for this run.

```
[ytanigaw@sh-109-53 ~/repos/rivas-lab/PRS/debug/KKT_1]$ head -n16 snpnet.50984390.err
[/var/spool/slurmd/job50984390/slurm_script 20190924-234223] [start] hostname = sh-109-56.int SLURM_JOBID = 50984390; phenotype = Cystatin_C
tmp_dir = /lscratch/ytanigaw/tmp-snpnet_wrapper.sh-20190924-234223-6Z0q8pSjAK
===================config_file===================
#key    val
snpnet_dir      /oak/stanford/groups/mrivas/software/snpnet
mem2bufferSizeDivisionFactor    4
cpu     10
mem     200000
niter   100
genotype_dir    /scratch/users/ytanigaw/tmp/snpnet/geno/array_imp_combined
data_dir_root   /oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/public-resources/uk_biobank/biomarkers/snpnet/data_array_imp
phenotype_file  biomarkers_covar.phe
phenotype_name  Cystatin_C
family  gaussian
prevIter        0
===================config_file===================
```