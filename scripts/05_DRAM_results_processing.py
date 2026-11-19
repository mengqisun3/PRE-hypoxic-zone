#A script to process the results of DRAM 95_bins
#Remove viral contamination and compare KEGG annotation results against viral fraction 
#Parse output file for subsequent analysis

from pathlib import Path
import pandas as pd

CWD = Path("./data")

FP1 = CWD / "annotations.tsv" #file from DRAM annotation output
FP2 = CWD / "uniq-IDs.txt" #file containing virus contig IDs, generated from viral population generation script
FP3 = CWD / "results.tsv" #file to save processed results

dram = pd.read_csv(FP1,sep = '\t',index_col=0)

viruses_lines = []
viruses = []
with open(FP2,'r') as v:
    viruses_lines = v.readlines()
    viruses = [x.rstrip() for x in viruses_lines]

indexes = dram[dram['scaffold'].isin(viruses)].index
dram_1 = dram.drop(indexes) #drop rows containing virus sequences

dram_1.to_csv(FP3,sep='\t')
