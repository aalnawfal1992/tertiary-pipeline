process MERGE_CHR_VCFS {
    tag "$meta.id"
    label 'process_low'
    container 'staphb/bcftools:1.22'
    publishDir "${params.outdir}/${meta.id}/annotations", mode: 'copy'
    
    input:
    tuple val(meta), path(compressed_vcfs), path(index_files)
    
    output:
    tuple val(meta), path("${meta.id}.dbnsfp.vcf"), emit: vcf
    path "${meta.id}.merge.log", emit: log
    
    script:
    """
    echo "Merging chromosome VCFs for ${meta.id}" > ${meta.id}.merge.log
    echo "Compressed files: ${compressed_vcfs}" >> ${meta.id}.merge.log
    echo "Index files: ${index_files}" >> ${meta.id}.merge.log
    
    # Verify all index files are present
    echo "" >> ${meta.id}.merge.log
    echo "Verifying index files..." >> ${meta.id}.merge.log
    for vcf_gz in *.vcf.gz; do
        if [ -f "\${vcf_gz}.tbi" ]; then
            echo "  ✓ \${vcf_gz} has index" >> ${meta.id}.merge.log
        else
            echo "  ✗ \${vcf_gz} missing index!" >> ${meta.id}.merge.log
        fi
    done
    
    # Create list in chromosome order
    > vcf_list.txt
    
    # Add files in proper order
    for chr in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y MT M; do
        for file in ${meta.id}.chr\${chr}.dbnsfp.vcf.gz; do
            if [ -f "\${file}" ] && [ -f "\${file}.tbi" ]; then
                echo "\${file}" >> vcf_list.txt
                break
            fi
        done
    done
    
    num_files=\$(cat vcf_list.txt | wc -l)
    echo "" >> ${meta.id}.merge.log
    echo "Found \${num_files} files to merge (with indexes)" >> ${meta.id}.merge.log
    
    if [ \${num_files} -eq 0 ]; then
        echo "ERROR: No files with indexes to merge!" >> ${meta.id}.merge.log
        exit 1
    else
        echo "Files to merge:" >> ${meta.id}.merge.log
        cat vcf_list.txt >> ${meta.id}.merge.log
        
        # Use bcftools concat
        bcftools concat \\
            --allow-overlaps \\
            --output-type v \\
            --output ${meta.id}.dbnsfp.vcf \\
            --file-list vcf_list.txt \\
            2>> ${meta.id}.merge.log
    fi
    
    # Verify output
    if [ -f ${meta.id}.dbnsfp.vcf ]; then
        total_variants=\$(grep -v "^#" ${meta.id}.dbnsfp.vcf | wc -l)
        echo "" >> ${meta.id}.merge.log
        echo "SUCCESS: Merged \${num_files} files" >> ${meta.id}.merge.log
        echo "Total variants: \${total_variants}" >> ${meta.id}.merge.log
    else
        echo "ERROR: Merge failed!" >> ${meta.id}.merge.log
        exit 1
    fi
    """
}