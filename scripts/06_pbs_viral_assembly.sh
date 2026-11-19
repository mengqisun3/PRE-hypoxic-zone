#!/bin/bash
#PBS -q workq
#PBS -N assembly
#PBS -l nodes=c007:ppn=16
#PBS -S /bin/bash
#PBS -j oe
#PBS -V
#PBS -l walltime=24000:00:00

cd $PBS_O_WORKDIR

CWD=$(pwd)
#Each sample is individually processed until the clustering step in the viral population generation script

metaspades.py -t 16 -m 2000 \
    -1 $CWD/final_pure_reads_1.fastq \
    -2 $CWD/final_pure_reads_2.fastq \
    -o metaspadesout
