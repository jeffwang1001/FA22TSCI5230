library(reticulate)

repl_python()


import pandas as pd
import numpy as np
import os
import requests
import zipfile
import pickle

from tqdm import tqdm

Input_data = "https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip"

os.makedirs('data', exist_ok = True)

Downloadpath = os.path.join('data', 'TempData.zip')

Request = requests.get(Input_data, stream = True)
SizeInBytes = Request.headers.get('content-length', 0)
BlockSize = 1024
ProgressBar = tqdm(total = int(SizeInBytes), unit = 'iB', unit_scale = True)

with open(Downloadpath, 'wb') as file:
  for data in Request.iter_content(BlockSize):
    ProgressBar.update(len(data))
    file.write(data)
    
ProgressBar.close()    

assert ProgressBar.n==int(SizeInBytes), 'Download incomplete'

to_unzip = zipfile.ZipFile(Downloadpath)

dd = {}
for ii in to_unzip.namelist():
  if ii.endswith("csv.gz"):
    dd[os.path.split(ii)[1].replace(".csv.gz","")] = pd.read_csv(to_unzip.open(ii), compression ='gzip', low_memory = False)
