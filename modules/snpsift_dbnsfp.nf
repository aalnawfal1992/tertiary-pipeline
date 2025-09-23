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
    !params.skip_dbnsfp

    // this module is a bit slove took 26 mins to annoatte the vcf file of NA12878, i was doing 12g RAM 
    
    script:
    def dbnsfp = params.dbnsfp_db_37
    """
    # Check if dbNSFP file exists
    if [ -f "${dbnsfp}" ]; then
        echo "Starting dbNSFP annotation..." > ${meta.id}.dbnsfp.log
        echo "Database: ${dbnsfp}" >> ${meta.id}.dbnsfp.log
        echo "Input VCF: ${vcf}" >> ${meta.id}.dbnsfp.log
        
        # Annotate with ALL fields (no -f parameter = use all)
        # This is the simplest and most comprehensive approach
        java -Xmx24g -jar /snpEff/SnpSift.jar dbnsfp \\
            -v \\
            -db ${dbnsfp} \\
            ${vcf} \\
            > ${meta.id}.dbnsfp.vcf 2>> ${meta.id}.dbnsfp.log
        
        # Check if annotation worked
        if [ -s "${meta.id}.dbnsfp.vcf" ]; then
            echo "dbNSFP annotation completed successfully" >> ${meta.id}.dbnsfp.log
            echo "Output variants: \$(grep -v '^#' ${meta.id}.dbnsfp.vcf | wc -l)" >> ${meta.id}.dbnsfp.log
            
            # Show which dbNSFP fields were added
            echo "" >> ${meta.id}.dbnsfp.log
            echo "dbNSFP fields added to VCF:" >> ${meta.id}.dbnsfp.log
            grep "^##INFO=<ID=dbNSFP_" ${meta.id}.dbnsfp.vcf | head -20 >> ${meta.id}.dbnsfp.log
        else
            echo "ERROR: dbNSFP annotation failed - output file is empty" >> ${meta.id}.dbnsfp.log
            cp ${vcf} ${meta.id}.dbnsfp.vcf
        fi
    else
        echo "ERROR: dbNSFP database not found at ${dbnsfp}" > ${meta.id}.dbnsfp.log
        cp ${vcf} ${meta.id}.dbnsfp.vcf
    fi
    
    # Output the log for debugging
    cat ${meta.id}.dbnsfp.log
    """
}