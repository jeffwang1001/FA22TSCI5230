
#start off with reticulate::repl_python() to load interactive session of python in R
import pandas as pd
import numpy as np

import os
import pickle

import re

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
  

kw_abx = ["vanco", "zosyn", "piperacillin", "tazobactam", "cefepime", "meropenam", "ertapenem", "carbapenem", "levofloxacin"]
kw_lab = "creatinine"
kw_aki = ["acute renal failure", "acute kidney injury", "acute kidney failure", "acute kidney", "acute renal insufficiency"]
kw_aki_pp = ["postpartum", "labor and delivery"]

label_abx = "|".join(kw_abx)
label_aki = "|".join(kw_aki)
label_aki_pp = "|".join(kw_aki_pp)

items_abx = dd['d_items'][dd['d_items'].label.str.contains(label_abx, case = False)].copy()
items_aki = dd['d_icd_diagnoses'][dd['d_icd_diagnoses'].long_title.str.contains(label_aki, case = False)]
items_aki = items_aki[~items_aki.long_title.str.contains(label_aki_pp, case = False)]
items_lab = dd['d_labitems'][dd['d_labitems'].label.str.contains(kw_lab, case = False, na = False)][items_lab.fluid =="Blood"]
given_abx = items_abx.merge(dd['inputevents'], on = 'itemid')

given_abx['group'] = np.where(given_abx.label=='Vancomycin','Vanc', 
  np.where(given_abx.label.str.contains('Piperacillin'), 'Zosyn', 'Other'))
  
given_abx['starttime'] = pd.to_datetime(given_abx['starttime']).dt.date
given_abx['endtime'] = pd.to_datetime((given_abx['endtime'])).dt.date

given_abx['ip_dates'] = given_abx.apply(lambda row:
  pd.date_range(row['starttime'], row['endtime'], freq = 'D'), axis = 1 )
abx_dates = given_abx.explode('ip_dates')

abx_dates['Vanc'] = 1
abx_dates['Zosyn'] = 1
abx_dates['Other'] = 1



aki_diagnosis = dd['diagnoses_icd'][dd['diagnoses_icd'].icd_code.str.contains("^584|^N17", case = False)]

cr_labevents = items_lab.merge(dd['labevents'], on = 'itemid')
cr_labevents['ip_dates'] = pd.to_datetime(cr_labevents['charttime']).dt.date
cr_labevents = cr_labevents[(cr_labevents.category == 'Chemistry') & (cr_labevents.fluid == 'Blood')][['hadm_id', 'ip_dates','valuenum','flag']].groupby(['hadm_id', 'ip_dates']).agg(
  Creatinine = ('valuenum', 'max'), cr_flag = ('flag', lambda xx: max(np.where(xx == 'abnormal', '1', '0')))).reset_index(drop = False).drop_duplicates()

emar_abx = dd['emar'][dd['emar'].medication.str.contains(label_abx, case = False, na = False)]

#dd['admissions'][['hadm_id', 'admittime', 'dischtime']]

admissions_scaffold = dd['admissions'][['hadm_id', 'admittime', 'dischtime']].copy()
admissions_scaffold['admittime'] = pd.to_datetime(admissions_scaffold['admittime']).dt.round('D')
admissions_scaffold['dischtime'] = pd.to_datetime(admissions_scaffold['dischtime']).dt.round('D')

admissions_scaffold['ip_dates'] = admissions_scaffold.apply(lambda row:
  pd.date_range(row['admittime'], row['dischtime'], freq = 'D'), axis = 1 )
admissions_scaffold = admissions_scaffold.explode('ip_dates')[['hadm_id','ip_dates']]

abx_dates = admissions_scaffold.merge(abx_dates[abx_dates['group'] == 'Zosyn'][['hadm_id','ip_dates', 'Zosyn']], 
  how = 'left').merge(abx_dates[abx_dates['group'] == 'Vanc'][['hadm_id','ip_dates', 'Vanc']], 
  how = 'left').merge(abx_dates[abx_dates['group'] == 'Other'][['hadm_id','ip_dates', 'Other']], 
  how = 'left').fillna(0).drop_duplicates()

abx_dates['ip_dates'] = pd.to_datetime(abx_dates['ip_dates']).dt.date
analysis_data = abx_dates.merge(cr_labevents, on = ['hadm_id', 'ip_dates'], how = 'left').fillna(method = 'ffill', axis = 1)

#start of code for lecture on 11/30/22
#check the previous code and add what was missing from last time




