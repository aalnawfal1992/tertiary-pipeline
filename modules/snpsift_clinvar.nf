process SNPSIFT_CLINVAR {
    tag "$meta.id"
    label 'process_low'
    container 'staphb/snpeff:latest'
    publishDir "${params.outdir}/${meta.id}/annotations", mode: 'copy'
    
    input:
    tuple val(meta), path(vcf)
    
    output:
    tuple val(meta), path("${meta.id}.clinvar.vcf"), emit: vcf
    path "${meta.id}.clinvar.log", emit: log
    
    when:
    !params.skip_clinvar
    
    script:
    def clinvar = "${projectDir}/databases/clinvar/clinvar_GRCh37.vcf.gz"
    """
    # Use the correct path to SnpSift.jar
    java -Xmx4g -jar /snpEff/SnpSift.jar annotate \\
        -id \\
        -info CLNSIG,CLNDN,CLNREVSTAT,CLNHGVS \\
        ${clinvar} \\
        ${vcf} \\
        > ${meta.id}.clinvar.vcf 2> ${meta.id}.clinvar.log
    
    echo "ClinVar annotation completed" >> ${meta.id}.clinvar.log
    """
}