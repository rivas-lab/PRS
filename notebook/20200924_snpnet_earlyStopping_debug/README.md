# validation metric index error

https://github.com/rivas-lab/PRS/issues/26


[2020-09-24 17:45:39 snpnet] Here, we check the early stopping condition. max.valid.idx = 0, configs[['stopping.lag']] = 2, max.valid.idx.lag = -2
Error in metric.val[1:(max.valid.idx.lag)] :
  only 0's may be mixed with negative subscripts
Calls: snpnet -> checkEarlyStopping
In addition: Warning message:
In checkMissingPhenoWarning(phe.master, phe.no.missing.IDs) :
  We detected missing values for 179746 individuals (-1_-1, -2_-2, -3_-3, -4_-4, -5_-5 ...).

Execution halted

