process SNPSIFT_HGMD {
    tag "$meta.id"
    label 'process_low'
    container 'staphb/snpeff:latest'
    publishDir "${params.outdir}/${meta.id}/annotations", mode: 'copy'
    
    input:
    tuple val(meta), path(vcf)
    
    output:
    tuple val(meta), path("${meta.id}.hgmd.vcf"), emit: vcf
    path "${meta.id}.hgmd.log", emit: log
    
    when:
    !params.skip_hgmd
    
    script:
    def hgmd = params.hgmd_vcf_37
    """
    if [ -f "${hgmd}" ]; then
        echo "Annotating with HGMD database..."
        java -Xmx4g -jar /snpEff/SnpSift.jar annotate \\
            -id \\
            -info CLASS,MUT,DISEASE \\
            ${hgmd} \\
            ${vcf} \\
            > ${meta.id}.hgmd.vcf 2> ${meta.id}.hgmd.log
        echo "HGMD annotation completed" >> ${meta.id}.hgmd.log
    else
        echo "HGMD database not found at ${hgmd}, skipping" > ${meta.id}.hgmd.log
        cp ${vcf} ${meta.id}.hgmd.vcf
    fi
    """
}