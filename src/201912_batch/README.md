# snpnet batch run

The phenotype file was prepared using the script below:

```{bash}
[ytanigaw@sh-109-56 ~/repos/rivas-lab/PRS/src/201912_batch]$ Rscript master.20191219.phe.R
[1] 488377     90
[1] 337151      3
[1] 516885   3271
[1] 3317
[1] 516884   3317
```

Note that we removed the individual with an reported error [https://github.com/rivas-lab/ukbb-tools/issues/14](https://github.com/rivas-lab/ukbb-tools/issues/14).

Then the file is copied to the SCRATCH space.

```{bash}
[ytanigaw@sh-109-56 ~/repos/rivas-lab/PRS/src/201912_batch]$ cat /scratch/groups/mrivas/projects/PRS/private_data/phe_file/master.20191219.phe.info.tsv | grep '^INI' | wc
   1404   19656  293613
[ytanigaw@sh-109-56 ~/repos/rivas-lab/PRS/src/201912_batch]$ sbatch --array=1-1000 snpnet_batch.INI.sbatch.sh
Submitted batch job 56765285
[ytanigaw@sh-109-56 ~/repos/rivas-lab/PRS/src/201912_batch]$ sbatch --array=1-404 snpnet_batch.INI.sbatch.sh 1000
Submitted batch job 56767929
```
