_README_ = '''
-------------------------------------------------------------------------
compute_r_or_auc.py

Evaluation script for PRS score by computing r or AUC

Author: Yosuke Tanigawa (ytanigaw@stanford.edu)
Date: 2019/02/25
-------------------------------------------------------------------------
'''

import argparse, os
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.metrics import roc_auc_score


def read_seed(seed_file):
    with open(seed_file) as f:
        s = int(f.read().splitlines()[0])    
    return s


def read_data(in_score, phe, covar_phe, keep=None):
    df = pd.read_csv(
        in_score, sep='\t', usecols=[1,4]
    ).merge(
        pd.read_csv(
            phe, sep='\t', usecols=[1,2], names=['IID', 'phe']
        ),
        on='IID'
    ).merge(
        pd.read_csv(
            covar_phe, sep='\t', usecols=[1,2,3,5,6,7,8]
        ),
        on='IID'
    )
    df_non_missing=df[df['phe'] != 9]
    if keep is None:
        return df_non_missing
    else:
        return df_non_missing.merge(
            pd.read_csv(
                keep, sep=' ', usecols=[0], names=['IID']
            ),
            on='IID',
            how='inner'
        )

    
def compute_r(x, y):
    lm = LinearRegression().fit(x, y)    
    return np.corrcoef(y, lm.predict(x))[0, 1]


def compute_auc(x, y, seed=None):
    lm = LogisticRegression(
        random_state=seed, solver='lbfgs'
    ).fit(x, y)
    roc_auc = roc_auc_score(y, lm.predict_log_proba(x)[:, 1])
    return max(roc_auc, 1 - roc_auc)    


def compute_r_or_auc_main(in_score, phe, phe_type, covar_phe, keep, out_file, seed_file=None):    
    df = read_data(in_score=in_score, phe=phe, covar_phe=covar_phe, keep=keep)
    
    covars=['age', 'sex']+['PC{}'.format(x+1) for x in range(4)]
    X1 = df[['SCORE1_AVG']].values
    X2 = df[covars + ['SCORE1_AVG']].values
    Y  = np.array(df['phe'])
    
    if phe_type in set(['linear', 'qt']):
        eval1 = compute_r(X1, Y)
        eval2 = compute_r(X2, Y)
        
    elif phe_type in set(['binary', 'bin']):
        if seed_file is None:
            seed = None
        else: 
            seed = read_seed(seed_file)
            
        eval1 = compute_auc(X1, Y, seed)
        eval2 = compute_auc(X2, Y, seed)

    results_str='{}\t{}\t{:.6e}\t{:.6e}\n'.format(
        in_score, phe_type, eval1, eval2
    )
    with open(out_file, 'w') as fw:        
        fw.write(results_str)        
    print(results_str)

    
def main():    
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=_README_
    )

    default_covar=os.path.join(
        '/oak/stanford/groups/mrivas',
        'private_data/ukbb/24983/sqc/ukb24983_GWAS_covar.phe'
    )
    default_seed_file=os.path.abspath('rand.seed.txt')

    parser.add_argument('-i', metavar='i', required=True,
                        help='in_score')    
    parser.add_argument('-p', metavar='p', required=True,
                        help='phenotype')        
    parser.add_argument('-o', metavar='o', required=True,
                        help='out_file')
    parser.add_argument('-c', metavar='c', default=default_covar,
                        help='covariate_file (default: {})'.format(default_covar))
    parser.add_argument('-k', metavar='k', default=None,
                        help='keep_file')
    parser.add_argument('-t', metavar='t', required=True,
                        help='type [bin | qt]')
    parser.add_argument('-s', metavar='s', default=default_seed_file,
                        help='seed_file (default: {})'.format(default_seed_file))
    
    args = parser.parse_args()
    in_score=os.path.abspath(args.i)
    phe=os.path.abspath(args.p) 
    phe_type=args.t
    covar_phe=os.path.abspath(args.c)
    out_file=os.path.abspath(args.o)    
    if(args.k is not None):
        keep=os.path.abspath(args.k)
    else:
        keep=None
    seed_file=os.path.abspath(args.s)    
    
    assert(phe_type in set(['bin', 'qt']))
        
    compute_r_or_auc_main(in_score, phe, phe_type, covar_phe, keep, out_file, seed_file)
    
    
if __name__ == "__main__":
    main()
