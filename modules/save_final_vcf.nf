process SAVE_FINAL_VCF {
    tag "$meta.id"
    publishDir "${params.outdir}/${meta.id}/final", mode: 'copy'
    container 'staphb/snpeff:latest'
    
    input:
    tuple val(meta), path(annotated_vcf)
    
    output:
    tuple val(meta), path("${meta.id}.final.annotated.vcf"), emit: vcf
    
    script:
    """
    # Just copy the annotated VCF to final name
    cp ${annotated_vcf} ${meta.id}.final.annotated.vcf
    
    # Count variants for logging
    echo "==========================================="
    echo "Final annotated VCF for ${meta.id}"
    echo "==========================================="
    echo "Total variants: \$(grep -v "^#" ${meta.id}.final.annotated.vcf | wc -l)"
    echo "File: ${meta.id}.final.annotated.vcf"
    echo "==========================================="
    """
}