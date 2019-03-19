_README_ = '''
-------------------------------------------------------------------------
compute_covar_Z_transform_statistics.py

Compute mean and std of covariates and add them to betas

Author: Yosuke Tanigawa (ytanigaw@stanford.edu)
Date: 2019/03/19
-------------------------------------------------------------------------
'''


import argparse, collections, os


import pandas as pd


from rivaslab_PRS_misc import pd_read_csv_usecols_by_key


def compute_covar_Z_transform_statistics(covar_phe, keep=None, covars=None):
    if covars is None:
        covar_df_all = pd.read_csv(covar_phe, sep='\t')
        covars=[
            x for x in list(covar_df_all.columns) 
            if x not in set(['IID', 'FID'])
        ]
        covar_df = covar_df_all[['IID'] + covars]        
    else:
        covar_df = pd_read_csv_usecols_by_key(
            covar_phe, cols=(['IID'] + covars), sep='\t'
        )
    if keep is None:
        df = covar_df
    else:
        df = covar_df.merge(
            pd.read_csv(keep, sep='\t', usecols=[0], names=['IID']),
            on='IID'
        )
    mat = df[covars].values
    return(pd.DataFrame(collections.OrderedDict([
        ('ID',   covars),
        ('mean', mat.mean(axis=0)),
        ('std',  mat.std(axis=0))
    ])))


def compute_covar_Z_transform_statistics_main(in_beta, covar_phe, keep, out_file):
    betas_df=pd.read_csv(
        in_beta, 
        compression=('gzip' if in_beta[-3:] == '.gz' else None), 
        sep='\t'
    )
    covars_df = compute_covar_Z_transform_statistics(
        covar_phe, 
        keep=keep, 
        covars=list(betas_df['ID'])
    )
    betas_df.merge(
        covars_df, on='ID'
    ).to_csv(
        out_file, index=False, sep='\t'    
    )

    
def main():    
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=_README_
    )

    default_covar=os.path.join(
        '/oak/stanford/groups/mrivas',
        'private_data/ukbb/24983/sqc/ukb24983_GWAS_covar.phe'
    )

    parser.add_argument('-i', metavar='i', required=True,
                        help='in_beta')    
    parser.add_argument('-o', metavar='o', required=True,
                        help='out_file')
    parser.add_argument('-c', metavar='c', default=default_covar,
                        help='covariate_file (default: {})'.format(default_covar))
    parser.add_argument('-k', metavar='k', required=True, help='keep_file')
    
    args = parser.parse_args()
    in_beta=os.path.abspath(args.i)
    covar_phe=os.path.abspath(args.c)
    out_file=os.path.abspath(args.o)    
    if(args.k is not None):
        keep=os.path.abspath(args.k)
    else:
        keep=None
            
    compute_covar_Z_transform_statistics_main(in_beta, covar_phe, keep, out_file)        
    
    
if __name__ == "__main__":
    main()
    