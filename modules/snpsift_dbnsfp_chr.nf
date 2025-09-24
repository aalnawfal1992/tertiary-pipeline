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
    # Check if dbNSFP file exists
    if [ -f "${dbnsfp}" ]; then
        echo "Starting dbNSFP annotation for ${chr_name}..." > ${chr_vcf.baseName}.dbnsfp.log
        echo "Database: ${dbnsfp}" >> ${chr_vcf.baseName}.dbnsfp.log
        echo "Input VCF: ${chr_vcf}" >> ${chr_vcf.baseName}.dbnsfp.log
        
        # Count input variants
        input_vars=\$(grep -v '^#' ${chr_vcf} | wc -l)
        echo "Input variants: \${input_vars}" >> ${chr_vcf.baseName}.dbnsfp.log
        
        # Annotate with dbNSFP
        java ${memory} -jar /snpEff/SnpSift.jar dbnsfp \\
            -v \\
            -db ${dbnsfp} \\
            ${chr_vcf} \\
            > ${chr_vcf.baseName}.dbnsfp.vcf 2>> ${chr_vcf.baseName}.dbnsfp.log
        
        # Check if annotation worked
        if [ -s "${chr_vcf.baseName}.dbnsfp.vcf" ]; then
            output_vars=\$(grep -v '^#' ${chr_vcf.baseName}.dbnsfp.vcf | wc -l)
            echo "dbNSFP annotation completed successfully" >> ${chr_vcf.baseName}.dbnsfp.log
            echo "Output variants: \${output_vars}" >> ${chr_vcf.baseName}.dbnsfp.log
        else
            echo "ERROR: dbNSFP annotation failed - output file is empty" >> ${chr_vcf.baseName}.dbnsfp.log
            cp ${chr_vcf} ${chr_vcf.baseName}.dbnsfp.vcf
        fi
    else
        echo "ERROR: dbNSFP database not found at ${dbnsfp}" > ${chr_vcf.baseName}.dbnsfp.log
        cp ${chr_vcf} ${chr_vcf.baseName}.dbnsfp.vcf
    fi
    """
}