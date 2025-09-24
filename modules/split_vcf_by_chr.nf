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
    
    # Define chromosomes (NOTE: Only use MT, not both MT and M)
    CHROMOSOMES="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y MT"
    
    created_files=0
    
    for chr in \${CHROMOSOMES}; do
        echo "Processing chromosome \${chr}..." >> ${meta.id}.split.log
        
        # Create temp file
        touch temp_chr\${chr}.vcf
        
        # Extract chromosome variants
        if [ "\${chr}" = "MT" ]; then
            # For mitochondrial, try all possible names but output as MT only
            grep -E "^(chrM|chrMT|MT|M)\\s" ${vcf} | grep -v "^#" > temp_chr\${chr}.vcf || true
        else
            # For other chromosomes
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
    
    echo "" >> ${meta.id}.split.log
    echo "Created \${created_files} chromosome VCF files" >> ${meta.id}.split.log
    
    if [ \${created_files} -eq 0 ]; then
        echo "ERROR: No chromosome files created!" >> ${meta.id}.split.log
        exit 1
    else
        echo "SUCCESS: Chromosome splitting completed" >> ${meta.id}.split.log
    fi
    """
}