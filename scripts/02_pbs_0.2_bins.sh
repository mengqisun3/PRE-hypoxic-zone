#!/bin/bash
#PBS -q workq
#PBS -N bin
#PBS -l nodes=1:ppn=32
#PBS -S /bin/bash
#PBS -j oe
#PBS -V
#PBS -l walltime=24000:00:00

cd $PBS_O_WORKDIR

CWD=$(pwd)

export PATH="{CONDA_PATH}:$PATH"
module load miniconda3

source activate metawrap

metawrap binning -o 1 -t 32 -a polish/1.pilon-renamed.fasta \
    --metabat2 --maxbin2 --concoct $CWD/final_pure_reads_*.fastq

metawrap bin_refinement -o 1-refined -t 32 \
    -A 1/metabat2_bins -B 1/maxbin2_bins -C 1/concoct_bins -c 70 -x 5

source deactivate

mv metawrap_70_5_bins combined_bins

#Dereplication of bins at 95% ANI threshold
source activate drep-2.6.2

dRep dereplicate DREP -g combined_bins/OMZ*.fa -pa 0.9 -sa 0.95 -p 32

source deactivate

#Dereplicated bins have their fasta headers renamed, bins are combined to form file all_OMZ_95_bins.fa