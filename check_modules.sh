#!/bin/bash
# File: check_modules.sh
# Check which modules exist and which are missing

echo "======================================"
echo "Checking Pipeline Modules"
echo "======================================"
echo ""

# List of required modules
MODULES=(
    "modules/parse_samplesheet.nf"
    "modules/snpeff_annotate.nf"
    "modules/snpsift_clinvar.nf"
    "modules/snpsift_hgmd.nf"
    "modules/snpsift_dbnsfp.nf"
    "modules/snpsift_omim.nf"
    "modules/split_vcf_by_chr.nf"
    "modules/snpsift_dbnsfp_chr.nf"
    "modules/merge_chr_vcfs.nf"
    "modules/save_final_vcf.nf"
    "modules/extract_tsv.nf"
    "modules/exomiser_analysis.nf"
)

echo "Required modules:"
echo ""

MISSING_COUNT=0
for module in "${MODULES[@]}"; do
    if [ -f "$module" ]; then
        echo "✓ $module"
    else
        echo "✗ $module - MISSING!"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

echo ""
echo "======================================"
echo "Summary: $MISSING_COUNT modules missing"
echo "======================================"

if [ $MISSING_COUNT -gt 0 ]; then
    echo ""
    echo "Creating missing modules..."
    
    # Create split_vcf_by_chr.nf if missing
    if [ ! -f "modules/split_vcf_by_chr.nf" ]; then
        cat > modules/split_vcf_by_chr.nf << 'EOF'
process SPLIT_VCF_BY_CHR {
    tag "$meta.id"
    label 'process_low'
    container 'staphb/snpeff:latest'
    publishDir "${params.outdir}/${meta.id}/temp/chr_splits", mode: 'copy', enabled: false
    
    input:
    tuple val(meta), path(vcf)
    
    output:
    tuple val(meta), path("${meta.id}.chr*.vcf"), emit: chr_vcfs
    path "${meta.id}.split.log", emit: log
    
    script:
    """
    echo "Splitting VCF by chromosome for ${meta.id}" > ${meta.id}.split.log
    
    # Get header
    grep "^#" ${vcf} > header.txt
    
    # Define chromosomes
    CHROMOSOMES="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y MT M"
    
    created_files=0
    
    for chr in \${CHROMOSOMES}; do
        echo "Processing chromosome \${chr}..." >> ${meta.id}.split.log
        
        # Create temp file
        touch temp_chr\${chr}.vcf
        
        # Extract chromosome
        if [ "\${chr}" = "MT" ] || [ "\${chr}" = "M" ]; then
            grep -E "^(chrM|chrMT|MT|M)\\s" ${vcf} | grep -v "^#" > temp_chr\${chr}.vcf || true
        else
            grep -E "^(chr)?\${chr}\\s" ${vcf} | grep -v "^#" > temp_chr\${chr}.vcf || true
        fi
        
        variant_count=\$(cat temp_chr\${chr}.vcf | wc -l)
        
        if [ \${variant_count} -eq 0 ]; then
            echo "  No variants for chromosome \${chr}" >> ${meta.id}.split.log
            rm temp_chr\${chr}.vcf
        else
            cat header.txt > ${meta.id}.chr\${chr}.vcf
            cat temp_chr\${chr}.vcf >> ${meta.id}.chr\${chr}.vcf
            rm temp_chr\${chr}.vcf
            echo "  Found \${variant_count} variants for chromosome \${chr}" >> ${meta.id}.split.log
            created_files=\$((created_files + 1))
        fi
    done
    
    echo "Created \${created_files} chromosome VCF files" >> ${meta.id}.split.log
    
    if [ \${created_files} -eq 0 ]; then
        echo "ERROR: No chromosome files created!" >> ${meta.id}.split.log
        exit 1
    fi
    """
}
EOF
        echo "Created modules/split_vcf_by_chr.nf"
    fi
    
    # Create snpsift_dbnsfp_chr.nf if missing
    if [ ! -f "modules/snpsift_dbnsfp_chr.nf" ]; then
        cat > modules/snpsift_dbnsfp_chr.nf << 'EOF'
process SNPSIFT_DBNSFP_CHR {
    tag "$meta.id - ${chr_name}"
    label 'process_medium'
    container 'staphb/snpeff:latest'
    publishDir "${params.outdir}/${meta.id}/temp/dbnsfp_chr", mode: 'copy', enabled: false
    
    input:
    tuple val(meta), path(chr_vcf), val(chr_name)
    
    output:
    tuple val(meta), path("${chr_vcf.baseName}.dbnsfp.vcf"), emit: vcf
    path "${chr_vcf.baseName}.dbnsfp.log", emit: log
    
    when:
    !params.skip_dbnsfp
    
    script:
    def dbnsfp = params.dbnsfp_db_37
    def memory = task.memory ? "-Xmx${task.memory.toGiga()}g" : '-Xmx8g'
    """
    if [ -f "${dbnsfp}" ]; then
        echo "Starting dbNSFP annotation for ${chr_name}..." > ${chr_vcf.baseName}.dbnsfp.log
        
        input_vars=\$(grep -v '^#' ${chr_vcf} | wc -l)
        echo "Input variants: \${input_vars}" >> ${chr_vcf.baseName}.dbnsfp.log
        
        java ${memory} -jar /snpEff/SnpSift.jar dbnsfp \\
            -v \\
            -db ${dbnsfp} \\
            ${chr_vcf} \\
            > ${chr_vcf.baseName}.dbnsfp.vcf 2>> ${chr_vcf.baseName}.dbnsfp.log
        
        if [ -s "${chr_vcf.baseName}.dbnsfp.vcf" ]; then
            echo "dbNSFP annotation completed" >> ${chr_vcf.baseName}.dbnsfp.log
        else
            cp ${chr_vcf} ${chr_vcf.baseName}.dbnsfp.vcf
        fi
    else
        echo "ERROR: dbNSFP database not found" > ${chr_vcf.baseName}.dbnsfp.log
        cp ${chr_vcf} ${chr_vcf.baseName}.dbnsfp.vcf
    fi
    """
}
EOF
        echo "Created modules/snpsift_dbnsfp_chr.nf"
    fi
    
    # Create merge_chr_vcfs.nf if missing
    if [ ! -f "modules/merge_chr_vcfs.nf" ]; then
        cat > modules/merge_chr_vcfs.nf << 'EOF'
process MERGE_CHR_VCFS {
    tag "$meta.id"
    label 'process_low'
    container 'biocontainers/bcftools:1.19--h8b25389_0'
    publishDir "${params.outdir}/${meta.id}/annotations", mode: 'copy'
    
    input:
    tuple val(meta), path(chr_vcfs)
    
    output:
    tuple val(meta), path("${meta.id}.dbnsfp.vcf"), emit: vcf
    path "${meta.id}.merge.log", emit: log
    
    script:
    """
    echo "Merging chromosome VCFs for ${meta.id}" > ${meta.id}.merge.log
    
    > vcf_list.txt
    for chr in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y MT M; do
        if [ -f "${meta.id}.chr\${chr}.dbnsfp.vcf" ]; then
            echo "${meta.id}.chr\${chr}.dbnsfp.vcf" >> vcf_list.txt
        fi
    done
    
    num_files=\$(cat vcf_list.txt | wc -l)
    echo "Found \${num_files} chromosome files to merge" >> ${meta.id}.merge.log
    
    if [ \${num_files} -eq 0 ]; then
        echo "ERROR: No files to merge!" >> ${meta.id}.merge.log
        exit 1
    elif [ \${num_files} -eq 1 ]; then
        cp \$(cat vcf_list.txt) ${meta.id}.dbnsfp.vcf
    else
        bcftools concat \\
            --allow-overlaps \\
            --output-type v \\
            --output ${meta.id}.dbnsfp.vcf \\
            --file-list vcf_list.txt \\
            2>> ${meta.id}.merge.log
    fi
    
    total_variants=\$(grep -v "^#" ${meta.id}.dbnsfp.vcf | wc -l)
    echo "Total variants in merged file: \${total_variants}" >> ${meta.id}.merge.log
    """
}
EOF
        echo "Created modules/merge_chr_vcfs.nf"
    fi
fi

echo ""
echo "Done!"