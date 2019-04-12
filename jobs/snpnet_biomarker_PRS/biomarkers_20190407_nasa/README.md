
```
MODULEPATH="$HOME/.modules:/home/groups/mrivas/.modules:/oak/stanford/groups/mrivas/.modules:$MODULEPATH"
ml load snpnet
export OAK=/oak/stanford/groups/mrivas
sbatch --array=50,68,69,23,45,58,46,47,57,59,53,54,64,65 -p owners,normal,mrivas,bigmem # please modify this to whatever queue you have access
```

