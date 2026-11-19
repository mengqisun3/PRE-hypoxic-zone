#!/bin/bash
#PBS -q workq
#PBS -N viral-population-generation
#PBS -l nodes=1:ppn=32
#PBS -S /bin/bash
#PBS -j oe
#PBS -V
#PBS -l walltime=24000:00:00

cd $PBS_O_WORKDIR

CWD=$(pwd)

export PATH="{CONDA_PATH}:$PATH"
module load miniconda3

source activate vs2

#Virsorter identification
virsorter run --keep-original-seq -i $CWD/metaspadesout/scaffolds.fasta \
    -w 0.7 --include-groups dsDNAphage,ssDNA --min-length 5000 --min-score 0.7 -j 16 all
virsorter run --keep-original-seq -i $CWD/metaspadesout/scaffolds.fasta \
    -w 0.9 --include-groups dsDNAphage,ssDNA --min-length 5000 --min-score 0.9 -j 16 all

source deactivate

source activate dvf
#Deepvirfinder identification
python $CWD/DeepVirFinder/dvf.py -i $CWD/metaspadesout/scaffolds.fasta -o $CWD/vir -l 5000 -c 32

awk '$3>0.9 && $4<0.05' $CWD/vir/scaffolds.fasta_gt5000bp_dvfpred.txt \
    > fasta_gt5000bp_dvfpred-0.9.txt
awk '$3>0.7 && $4<0.05' $CWD/vir/scaffolds.fasta_gt5000bp_dvfpred.txt \
    > fasta_gt5000bp_dvfpred-0.7.txt

source deactivate

#Consoldating results of Virsorter2 and DeepVirFinder to generate a list of viral contigs
source activate seqkit

seqkit seq 0.7/final-viral-combined.fa -n -i | cut -d '|' -f1 > virsorter2-0.7-IDs-cut.txt
seqkit seq 0.9/final-viral-combined.fa -n -i | cut -d '|' -f1 > virsorter2-0.9-IDs-cut.txt

awk '{print $1}' fasta_gt5000bp_dvfpred-0.7.txt > DVF-0.7-IDs.txt
awk '{print $1}' fasta_gt5000bp_dvfpred-0.9.txt > DVF-0.9-IDs.txt

sort virsorter2-0.7-IDs-cut.txt > virsorter2-0.7-IDs-cut-sorted.txt
sort DVF-0.7-IDs.txt > DVF-0.7-IDs-sorted.txt
comm -12 --check-order virsorter2-0.7-IDs-cut-sorted.txt DVF-0.7-IDs-sorted.txt > comm-IDs.txt

sort virsorter2-0.9-IDs-cut.txt DVF-0.9-IDs.txt comm-IDs.txt | uniq > uniq-IDs.txt

seqkit grep -f uniq-IDs.txt $CWD/metaspadesout/scaffolds.fasta > $CWD/OMZ_viral.fasta

#CheckV rapid clustering protocol to generate viral clusters from viral contigs
source activate viral-id-sop

makeblastdb -in OMZ_viral.fasta -dbtype nucl -out OMZ_viral_database
blastn -query OMZ_viral.fasta \
    -db OMZ_viral_database -outfmt '6 std qlen slen' -max_target_seqs 10000 \
    -out blasted_OMZ_viral.tsv -num_threads 16
python anicalc.py -i blasted_OMZ_viral.tsv -o blasted_OMZ_viral_ani.tsv
python aniclust.py --fna OMZ_viral.fasta \
    --ani blasted_OMZ_viral_ani.tsv --out OMZ_viral_clusters.tsv \
    --min_ani 95 --min_tcov 85 --min_qcov 0

source deactivate

#The longest contig of each cluster is extracted to produce a non-redundant set of viral populations
source activate seqkit

awk '{print $1}' OMZ_viral_clusters.tsv > OMZ_viral_centroids.tsv
seqkit grep -f OMZ_viral_centroids.tsv $CWD/OMZ_viral.fasta -o OMZ_viral_centroids.fasta

source deactivate
