#!/bin/bash
set -euo pipefail

# Wrapper script for running Exomiser outside of Nextflow if needed
# Usage: ./run_exomiser.sh <sample_id> <vcf_path> <assembly> <hpo_terms> <output_dir>

SAMPLE_ID=$1
VCF_PATH=$2
ASSEMBLY=$3  # 37 or 38
HPO_TERMS=${4:-"HP:0001156"}  # Default HPO if not provided
OUTPUT_DIR=${5:-"./exomiser_results"}

# Configuration - adjust these paths as needed
EXOMISER_JAR="/home/abudllah/exomiser-cli-14.0.0-distribution/exomiser-cli-14.0.0/exomiser-cli-14.0.0.jar"
EXOMISER_DATA="/home/abudllah/exomiser-cli-14.0.0-distribution/exomiser-cli-14.0.0/data"
APP_PROPERTIES="/home/abudllah/exomiser-cli-14.0.0-distribution/exomiser-cli-14.0.0/application.properties"

# Convert assembly to genome build
if [ "$ASSEMBLY" == "37" ]; then
    GENOME="hg19"
else
    GENOME="hg38"
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}/${SAMPLE_ID}"

# Convert HPO terms to YAML array format
HPO_ARRAY=$(echo "$HPO_TERMS" | sed "s/,/', '/g" | sed "s/^/'/" | sed "s/$/'/")

# Extract actual sample name from VCF
if command -v bcftools > /dev/null; then
    VCF_SAMPLE_NAME=$(bcftools query -l "${VCF_PATH}" | head -n1)
else
    # Fallback: extract from #CHROM line in VCF
    VCF_SAMPLE_NAME=$(grep "^#CHROM" "${VCF_PATH}" | cut -f10)
fi

echo "Sample name in VCF: ${VCF_SAMPLE_NAME}"

# Use VCF sample name if found, otherwise use provided sample ID
PROBAND_NAME="${VCF_SAMPLE_NAME:-$SAMPLE_ID}"

# Generate analysis YAML
cat > "${OUTPUT_DIR}/${SAMPLE_ID}/${SAMPLE_ID}_analysis.yml" <<EOF
---
analysis:
    genomeAssembly: ${GENOME}
    vcf: ${VCF_PATH}
    proband: ${PROBAND_NAME}
    hpoIds: [${HPO_ARRAY}]
    inheritanceModes: {
        AUTOSOMAL_DOMINANT: 0.1,
        AUTOSOMAL_RECESSIVE_HOM_ALT: 0.1,
        AUTOSOMAL_RECESSIVE_COMP_HET: 2.0,
        X_RECESSIVE_HOM_ALT: 0.1,
        X_RECESSIVE_COMP_HET: 2.0
    }
    analysisMode: PASS_ONLY
    frequencySources: [
        THOUSAND_GENOMES, TOPMED, UK10K,
        ESP_AFRICAN_AMERICAN, ESP_EUROPEAN_AMERICAN, ESP_ALL,
        EXAC_AFRICAN_INC_AFRICAN_AMERICAN, EXAC_AMERICAN, EXAC_EAST_ASIAN,
        EXAC_NON_FINNISH_EUROPEAN, EXAC_SOUTH_ASIAN,
        GNOMAD_E_AFR, GNOMAD_E_AMR, GNOMAD_E_EAS, GNOMAD_E_NFE, GNOMAD_E_SAS,
        GNOMAD_G_AFR, GNOMAD_G_AMR, GNOMAD_G_EAS, GNOMAD_G_NFE, GNOMAD_G_SAS
    ]
    pathogenicitySources: [ REVEL, MVP ]
    steps: [
        failedVariantFilter: {},
        variantEffectFilter: {
            remove: [
                FIVE_PRIME_UTR_EXON_VARIANT, FIVE_PRIME_UTR_INTRON_VARIANT,
                THREE_PRIME_UTR_EXON_VARIANT, THREE_PRIME_UTR_INTRON_VARIANT,
                NON_CODING_TRANSCRIPT_EXON_VARIANT, NON_CODING_TRANSCRIPT_INTRON_VARIANT,
                CODING_TRANSCRIPT_INTRON_VARIANT, UPSTREAM_GENE_VARIANT,
                DOWNSTREAM_GENE_VARIANT, INTERGENIC_VARIANT, REGULATORY_REGION_VARIANT
            ]
        },
        frequencyFilter: { maxFrequency: 2.0 },
        pathogenicityFilter: { keepNonPathogenic: true },
        inheritanceFilter: {},
        omimPrioritiser: {},
        hiPhivePrioritiser: {}
    ]
outputOptions:
    outputContributingVariantsOnly: false
    numGenes: 0
    outputFormats: [ HTML, JSON, TSV_GENE, TSV_VARIANT, VCF ]
    outputFileName: ${OUTPUT_DIR}/${SAMPLE_ID}/${SAMPLE_ID}_exomiser
EOF

echo "=========================================="
echo "Running Exomiser for ${SAMPLE_ID}"
echo "VCF: ${VCF_PATH}"
echo "Assembly: ${ASSEMBLY} (${GENOME})"
echo "HPO Terms: ${HPO_TERMS}"
echo "Output: ${OUTPUT_DIR}/${SAMPLE_ID}"
echo "=========================================="

# Run Exomiser
java -Xms4g -Xmx16g \
    -Dspring.config.location=${APP_PROPERTIES} \
    -jar ${EXOMISER_JAR} \
    --analysis "${OUTPUT_DIR}/${SAMPLE_ID}/${SAMPLE_ID}_analysis.yml" \
    --spring.config.location=${APP_PROPERTIES}

echo "=========================================="
echo "Exomiser analysis complete!"
echo "Results: ${OUTPUT_DIR}/${SAMPLE_ID}/"
echo "=========================================="