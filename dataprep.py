import pandas as pd
import numpy as np

import os
import pickle

if not os.path.exists('data.pickle'):
  import runpy
  runpy.run_path('data.py')
  
dd = pickle.load(open('data.pickle', 'rb'))

# dd.keys()
# dd['admissions']

demographics = dd['admissions'].copy()

patients = dd['patients'].copy().drop('dod', axis = 1)

demographics['LOS'] = (pd.to_datetime(demographics['dischtime']) - pd.to_datetime(demographics['admittime']))/np.timedelta64(1, 'D')

demographics1 = demographics.groupby('subject_id').agg(admits = ('subject_id', 'count'),
  eth = ('ethnicity', 'nunique'),
  ethnicity_combo = ('ethnicity', lambda xx: ':'.join(sorted(list(set(xx))))),
  language = ('language', 'last'),
  dod = ('deathtime', lambda xx: max(pd.to_datetime(xx))),
  los = ('LOS', np.median),
  numED = ('edregtime', lambda xx: xx.notnull().sum())).reset_index(drop = False).merge(patients, on = 'subject_id')
  

  

