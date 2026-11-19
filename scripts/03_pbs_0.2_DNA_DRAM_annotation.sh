#!/bin/bash
#PBS -q workq
#PBS -N dram
#PBS -l nodes=1:ppn=32
#PBS -S /bin/bash
#PBS -j oe
#PBS -V
#PBS -l walltime=24000:00:00

cd $PBS_O_WORKDIR

CWD=$(pwd)

export PATH="{CONDA_PATH}:$PATH"
module load miniconda3

source activate prodigal

prodigal -i $CWD/all_OMZ_95_bins.fa -o $CWD/all_OMZ_95_bins.gbk \
    -a $CWD/all_OMZ_95_bins.faa -p meta

source deactivate

source activate hmmer

#Download Pfam-A.hmm

hmmscan --tblout all_OMZ_95_bins.tblout.pfam.out -E 1e-3 --cpu 32 \
    Pfam-A.hmm $CWD/all_OMZ_95_bins.faa

source deactivate

source activate gtdbtk-2.3.2

gtdbtk classify_wf --extension fa --genome_dir /DREP/95_numbered_binset \
    --skip_ani_screen --out_dir OMZ_95_GTDBTK_classify --cpus 32

source deactivate

sed '1d' /GTDB-TK/OMZ_95_GTDBTK_classify/gtdbtk.ar53.summary.tsv > ar.tsv
cat /GTDB-TK/OMZ_95_GTDBTK_classify/gtdbtk.bac120.summary.tsv ar.tsv > /GTDB-TK/OMZ_95_GTDBTK_classify/gtdbtk.both.summary.tsv

source activate DRAM

DRAM-setup.py prepare_databases --output_dir DRAM_data \
    --skip_uniref --kofam_hmm_loc ko_profiles.tar.gz --kofam_ko_list_loc ko_list.gz \
    --pfam_loc Pfam-A.hmm.gz --pfam_hmm_loc Pfam-A.hmm.dat.gz --kegg_loc genes.pep.faa

DRAM.py annotate -i '/DREP/95_numbered_binset/*.fa' \
    --gtdb_taxonomy '/GTDB-TK/OMZ_95_GTDBTK_classify/gtdbtk.both.summary.tsv' \
    --checkm_quality '../DREP/95_checkm_qa.tab' --threads 32 -o annotation_95

source deactivate


