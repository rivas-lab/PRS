# non-WB refit

For non-WB populations, we tested whether using the "refit" of the snpnet model on the selected model help improve the predictive performance.

To that end, we implemented extract/exclude options in snpnet software (version 1.4.0) and used it from the wrapper script in this directory.

## job submission

```
[ytanigaw@sh03-12n24 ~/repos/rivas-lab/PRS/src/20211024_nonWB_refit] (job 36268905) $ bash 2a_submit.sh GBE_ID_list.txt
HC269 (refit: F)
HC382 (refit: F)
INI21001 (refit: F)
INI50 (refit: F)
```
