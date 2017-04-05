#!/usr/bin/env bash

module load picard python py_packages 

sample="$(basename $1 .bam)"
if [ ! -e "picard/${sample}" ]; then
    mkdir -p "picard/${sample}"
fi


FASTA=/sc/orga/projects/PBG/REFERENCES/GRCh38/Gencode/release_24/GRCh38.primary_assembly.genome.fa
REFFLAT=/sc/orga/projects/AMP_AD/reprocess/inputs/picard_stuff/gencode.v24.primary_assembly.refFlat.txt
RIBOINTS=/sc/orga/projects/AMP_AD/reprocess/inputs/picard_stuff/gencode.v24.primary_assembly.rRNA.interval_list

# Sort BAM
java -Xmx8G -jar $PICARD SortSam \
    INPUT=$1 \
    OUTPUT="picard/${sample}.tmp.bam" \
    SORT_ORDER=coordinate \
    VALIDATION_STRINGENCY=SILENT \
    COMPRESSION_LEVEL=0 \
    TMP_DIR="/sc/orga/scratch/${USER}/${sample}/"

# CollectAlignmentSummaryMetrics (after sorting)
java -Xmx8G -jar $PICARD CollectAlignmentSummaryMetrics \
    VALIDATION_STRINGENCY=LENIENT \
    MAX_RECORDS_IN_RAM=4000000 \
    ASSUME_SORTED=true \
    ADAPTER_SEQUENCE= \
    IS_BISULFITE_SEQUENCED=false \
    MAX_INSERT_SIZE=100000 \
    R=$FASTA \
    INPUT="picard/${sample}.tmp.bam" \
    OUTPUT="picard/${sample}/picard.analysis.CollectAlignmentSummaryMetrics" \
    TMP_DIR="/sc/orga/scratch/${USER}/${sample}/"


# CollectRnaSeqMetrics (after sorting)
java -Xmx8G -jar $PICARD CollectRnaSeqMetrics \
    VALIDATION_STRINGENCY=LENIENT \
    MAX_RECORDS_IN_RAM=4000000 \
    STRAND_SPECIFICITY=NONE \
    MINIMUM_LENGTH=500 \
    RRNA_FRAGMENT_PERCENTAGE=0.8 \
    METRIC_ACCUMULATION_LEVEL=ALL_READS \
    R=$FASTA \
    REF_FLAT=$REFFLAT \
    RIBOSOMAL_INTERVALS=$RIBOINTS \
    INPUT="picard/${sample}.tmp.bam" \
    OUTPUT="picard/${sample}/picard.analysis.CollectRnaSeqMetrics" \
    TMP_DIR="/sc/orga/scratch/${USER}/${sample}/"

# MarkDuplicates (after sorting)
# java -Xmx8G -jar $PICARD MarkDuplicates \
#     VALIDATION_STRINGENCY=LENIENT \
#     MAX_RECORDS_IN_RAM=4000000 \
#     ASSUME_SORTED=true \
#     REMOVE_DUPLICATES=false \
#     OPTICAL_DUPLICATE_PIXEL_DISTANCE=100 \
#     INPUT="picard/${sample}.tmp.bam" \
#     OUTPUT="/sc/orga/scratch/xdangk01/${sample}/tmp.bam" \
#     METRICS_FILE="picard/${sample}/picard.analysis.MarkDuplicates" \
#     TMP_DIR="/sc/orga/scratch/${USER}/${sample}/"


# Clean up
rm "picard/${sample}.tmp.bam"
#rm "/sc/orga/scratch/${USER}/${sample}/tmp.bam"
rmdir "/sc/orga/scratch/${USER}/${sample}"

picard_outputs=$(find picard/${sample} -name "picard.analysis*")
/sc/orga/projects/AMP_AD/reprocess/code/amp-rnaseq/combine_picard_sample.py $picard_outputs \
    -o "picard/${sample}/picard.CombinedMetrics.csv"