process SNPSIFT_DBNSFP {
    tag "$meta.id"
    label 'process_medium'
    container 'staphb/snpeff:latest'
    publishDir "${params.outdir}/${meta.id}/annotations", mode: 'copy'
    
    input:
    tuple val(meta), path(vcf)
    
    output:
    tuple val(meta), path("${meta.id}.dbnsfp.vcf"), emit: vcf
    path "${meta.id}.dbnsfp.log", emit: log
    
    when:
    !params.skip_dbnsfp && !params.split_dbnsfp_by_chr
    
    script:
    def dbnsfp = params.dbnsfp_db_37
    """
    # This is the original single-file processing
    # Only runs if split_dbnsfp_by_chr is false
    
    if [ -f "${dbnsfp}" ]; then
        echo "Starting dbNSFP annotation (single file mode)..." > ${meta.id}.dbnsfp.log
        echo "Database: ${dbnsfp}" >> ${meta.id}.dbnsfp.log
        echo "Input VCF: ${vcf}" >> ${meta.id}.dbnsfp.log
        
        java -Xmx24g -jar /snpEff/SnpSift.jar dbnsfp \\
            -v \\
            -db ${dbnsfp} \\
            ${vcf} \\
            > ${meta.id}.dbnsfp.vcf 2>> ${meta.id}.dbnsfp.log
        
        if [ -s "${meta.id}.dbnsfp.vcf" ]; then
            echo "dbNSFP annotation completed successfully" >> ${meta.id}.dbnsfp.log
            echo "Output variants: \$(grep -v '^#' ${meta.id}.dbnsfp.vcf | wc -l)" >> ${meta.id}.dbnsfp.log
        else
            echo "ERROR: dbNSFP annotation failed - output file is empty" >> ${meta.id}.dbnsfp.log
            cp ${vcf} ${meta.id}.dbnsfp.vcf
        fi
    else
        echo "ERROR: dbNSFP database not found at ${dbnsfp}" > ${meta.id}.dbnsfp.log
        cp ${vcf} ${meta.id}.dbnsfp.vcf
    fi
    
    cat ${meta.id}.dbnsfp.log
    """
}