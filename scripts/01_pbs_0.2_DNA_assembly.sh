#!/bin/bash                 
#PBS -q workq               
#PBS -N assembly          
#PBS -l nodes=1:ppn=32      
#PBS -S /bin/bash           
#PBS -j oe                  
#PBS -V                     
#PBS -l walltime=24000:00:00                          
                            
cd $PBS_O_WORKDIR        

CWD=$(pwd)
#Each sample is individually processed until the clustering step in the viral population generation script

export PATH="{CONDA_PATH}:$PATH"
module load miniconda3

source activate unicycler

unicycler \
    -1 $CWD/final_pure_reads_1.fastq \ 
    -2 $CWD/final_pure_reads_2.fastq \ 
    -l $CWD/pass.fq.gz --min_fasta_length 1000 -t 32 \
    -o unicycler_output

source deactivate

#Genrate BAM files for polishing
source activate bwa

bwa index $CWD/unicycler_output/assembly.fasta
bwa mem \
    $CWD/unicycler_output/assembly.fasta \
    $CWD/final_pure_reads_1.fastq $CWD/final_pure_reads_2.fastq \
    > $CWD/bwa-results.sam

source deactivate

source activate samtools-1.9

samtools view -b -o $CWD/bwa-results.bam $CWD/bwa-results.sam
samtools sort $CWD/bwa-results.bam > $CWD/bwa-results.sorted.bam 
samtools index $CWD/bwa-results.sorted.bam

source deactivate

#Polish assembly with pilon
java -Xmx60G -jar pilon.jar \
    --genome $CWD/unicycler_output/assembly.fasta \
    --frags $CWD/bwa-results.sorted.bam \
    --output pilon \
    --outdir polish

#rename headers after pilon polishing
source activate seqkit

seqkit replace -p ^ -r OMZ1_ polish/1.pilon.fasta > 1.pilon-renamed.fasta



