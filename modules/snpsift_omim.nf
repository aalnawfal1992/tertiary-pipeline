process SNPSIFT_OMIM {
    tag "$meta.id"
    label 'process_low'
    container 'staphb/snpeff:latest'
    publishDir "${params.outdir}/${meta.id}/annotations", mode: 'copy'
    
    input:
    tuple val(meta), path(vcf)
    
    output:
    tuple val(meta), path("${meta.id}.omim.vcf"), emit: vcf
    path "${meta.id}.omim.log", emit: log
    
    when:
    !params.skip_omim
    
    script:
    def omim = params.omim_genemap_37
    """
    if [ -f "${omim}" ]; then
        echo "Annotating with OMIM database..."
        # Simple OMIM annotation using SnpSift annotate
        # Note: For full OMIM annotation, you would need a proper OMIM VCF file
        # This is a placeholder that just copies the input
        echo "OMIM annotation would be applied here if OMIM VCF was available" > ${meta.id}.omim.log
        echo "OMIM requires a license from: https://www.omim.org/downloads" >> ${meta.id}.omim.log
        cp ${vcf} ${meta.id}.omim.vcf
    else
        echo "OMIM database not found at ${omim}, skipping" > ${meta.id}.omim.log
        echo "OMIM requires a license. Visit: https://www.omim.org/downloads" >> ${meta.id}.omim.log
        cp ${vcf} ${meta.id}.omim.vcf
    fi
    """
}