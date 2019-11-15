import pandas as pd


def pd_read_csv_usecols_by_key(df_file, cols, **argv):
    '''
    usecols option in pandas.read_csv() takes column indices. 
    In practice, it would be convenient to pass list of column names.
    This wrapper provides that functionality    
    '''
    df_cols = pd.read_csv(df_file, nrows=0, **argv)
    col_idx = dict(zip(list(df_cols.columns), range(len(df_cols.columns))))
    return pd.read_csv(df_file, usecols=[col_idx[x] for x in cols], **argv)

