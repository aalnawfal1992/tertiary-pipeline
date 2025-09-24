// File: modules/compress_vcfs.nf (FIXED VERSION)

process COMPRESS_VCFS {
    tag "$meta.id"
    label 'process_low'
    container 'quay.io/biocontainers/samtools:1.14--hb421002_0'
    
    input:
    tuple val(meta), path(chr_vcfs)
    
    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: compressed_vcfs_with_index
    path "${meta.id}.compress.log", emit: log
    
    script:
    """
    echo "Compressing VCF files for ${meta.id}" > ${meta.id}.compress.log
    
    for vcf in ${chr_vcfs}; do
        echo "Compressing \${vcf}..." >> ${meta.id}.compress.log
        
        # Compress with bgzip
        bgzip -c "\${vcf}" > "\${vcf}.gz"
        
        # Create tabix index
        tabix -p vcf "\${vcf}.gz"
        
        # Verify index was created
        if [ -f "\${vcf}.gz.tbi" ]; then
            echo "  Created \${vcf}.gz and index" >> ${meta.id}.compress.log
        else
            echo "  ERROR: Failed to create index for \${vcf}.gz" >> ${meta.id}.compress.log
        fi
    done
    
    echo "" >> ${meta.id}.compress.log
    echo "Compressed files:" >> ${meta.id}.compress.log
    ls -la *.vcf.gz >> ${meta.id}.compress.log
    echo "" >> ${meta.id}.compress.log
    echo "Index files:" >> ${meta.id}.compress.log
    ls -la *.vcf.gz.tbi >> ${meta.id}.compress.log
    
    echo "Compression complete" >> ${meta.id}.compress.log
    """
}