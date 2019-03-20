_README_ = '''
-------------------------------------------------------------------------
compute_r_or_auc.py

Evaluation script for PRS score by computing r or AUC

Author: Yosuke Tanigawa (ytanigaw@stanford.edu)
Date: 2019/02/25 (updated on 2019/3/19)
-------------------------------------------------------------------------
'''


import argparse, os, collections


import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.metrics import roc_auc_score

from rivaslab_PRS_misc import pd_read_csv_usecols_by_key

class PRS_eval:
    '''
    This class computes R or AUC for multiple PRS models
    '''
    
    ######################################################
    # Constructor
    ######################################################
    
    def __init__(self, phe_type, seed_file=None):
        '''
        Constructor for PRS_eval class
        
        phe_type: [ binary | bin | linear | qt ]
        seed_file: optional. used as a seed for logistic regression
        '''
        self._set_consts()        
        self.metrics = collections.OrderedDict()
        self.phe_type = phe_type                
        assert(self._is_bin() or self._is_qt())
        self.seed_file = seed_file
        self.seed = self._read_seed()
    
    ######################################################    
    # Private funcs
    ######################################################    
            
    def _set_consts(self):
        self.const = collections.OrderedDict()
        self.const['phe_type_bin'] = set(['binary', 'bin'])
        self.const['phe_type_qt']  = set(['linear', 'qt'])
        
    def _is_bin(self):
        return (self.phe_type in self.const['phe_type_bin'])

    def _is_qt(self):
        return (self.phe_type in self.const['phe_type_qt'])
            
    def _read_seed(self):
        if self._is_bin() and self.seed_file is not None:
            return int(np.loadtxt(self.seed_file))
        else: 
            return None
            
    def _compute_r(self, x, y):
        lm = LinearRegression().fit(x, y)    
        return np.corrcoef(y, lm.predict(x))[0, 1]

    def _compute_auc(self, x, y, seed=None):
        lm = LogisticRegression(
            random_state=seed, solver='lbfgs'
        ).fit(x, y)
        roc_auc = roc_auc_score(y, lm.predict_log_proba(x)[:, 1])
        return max(roc_auc, 1 - roc_auc)

    ######################################################    
    # public funcs
    ######################################################    
    
    def compute_r_or_auc(self, model_name, x, y):
        if self._is_qt():
            self.metrics[model_name] = self._compute_r(x, y)

        elif self._is_bin():
            print(collections.Counter(y))        
            self.metrics[model_name] = self._compute_auc(x, y, self.seed)
        
    def get_metrics_str(self):
        return ['{}\t{:.6e}'.format(x[0], x[1]) for x in self.metrics.items()]
    
    def format_metrics(self, info_str=None):
        metrics_str = self.get_metrics_str()
        if info_str is None:
            return '\n'.join(metrics_str)
        else:
            return '\n'.join(['{}\t{}'.format(str(info_str), x) for x in metrics_str])
        

def read_data_for_eval(in_score, phe, covar_phe, keep=None):
    print(in_score, phe, covar_phe, keep)
    df = pd_read_csv_usecols_by_key(
        in_score, cols=['IID', 'SCORE1_SUM'], sep='\t'
    ).merge(
        pd.read_csv(
            phe, sep='\t', usecols=[1,2], names=['IID', 'phe']
        ),
        on='IID'
    ).merge(
        pd.read_csv(covar_phe, sep='\t'),
        on='IID'
    )
    df_non_missing=df[df['phe'] != 9]
    if keep is None:
        return df_non_missing
    else:
        return df_non_missing.merge(
            pd.read_csv(
                keep, sep='\t', usecols=[0], names=['IID']
            ),
            on='IID',
            how='inner'
        )
    
def compute_score_for_covariates(df, betas, center=False, Z=False):
    betas_df=pd.read_csv(betas, compression='gzip', sep='\t')
    covar_mat = df[list(betas_df['ID'])].values
    
    betas_vec = np.array(betas_df['BETA'])[:,np.newaxis]
    
    if 'mean' in set(betas_df.columns) and (center or Z):
        covar_mat_centered = (covar_mat - np.array(betas_df['mean'])[np.newaxis, :])
        if 'Z' in set(betas_df.columns) and Z:
            covar_mat_Z = (covar_mat_centered / np.array(betas_df['std'])[np.newaxis, :])
            return np.dot(covar_mat_Z, betas_vec)
        else:
            return np.dot(covar_mat_centered, betas_vec)
    else:            
        return np.dot(covar_mat, betas_vec)
    
        
def compute_r_or_auc_main(in_score, phe, phe_type, covar_phe, betas, keep, out_file, seed_file=None):  
    df = read_data_for_eval(in_score=in_score, phe=phe, covar_phe=covar_phe, keep=keep)
    
    PRS = collections.OrderedDict()
    
    PRS['Genotype_only'] = df[['SCORE1_SUM']].values
    PRS['Covariates_only'] = compute_score_for_covariates(df, betas)
#    PRS['Covariates_only_center'] = compute_score_for_covariates(df, betas, center=True)
#    PRS['Covariates_only_Z'] = compute_score_for_covariates(df, betas, Z=True)
    PRS['Genotype_and_covariates'] = PRS['Genotype_only'] + PRS['Covariates_only']
#    PRS['Genotype_and_covariates_center'] = PRS['Genotype_only'] + PRS['Covariates_only_center']
#    PRS['Genotype_and_covariates_Z'] = PRS['Genotype_only'] + PRS['Covariates_only_Z']

    Y  = np.array(df['phe'])
    prs_eval = PRS_eval(phe_type, seed_file)
    for k,v in PRS.items():
        prs_eval.compute_r_or_auc(k, v, Y)    

    info_str='\t'.join([in_score, phe_type])
    results_str = prs_eval.format_metrics(info_str)
    with open(out_file, 'w') as fw:        
        fw.write(results_str + '\n')        
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
    default_seed_file=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'rand.seed.txt')

    parser.add_argument('-i', metavar='i', required=True,
                        help='in_score')    
    parser.add_argument('-p', metavar='p', required=True,
                        help='phenotype')        
    parser.add_argument('-o', metavar='o', required=True,
                        help='out_file')
    parser.add_argument('-b', metavar='b', 
                        help='BETA file for covariates')
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
    betas=args.b
    out_file=os.path.abspath(args.o)    
    if(args.k is not None):
        keep=os.path.abspath(args.k)
    else:
        keep=None
    seed_file=os.path.abspath(args.s)    
    
    assert(phe_type in set(['bin', 'qt']))
        
    compute_r_or_auc_main(in_score, phe, phe_type, covar_phe, betas, keep, out_file, seed_file)
    
    
if __name__ == "__main__":
    main()
