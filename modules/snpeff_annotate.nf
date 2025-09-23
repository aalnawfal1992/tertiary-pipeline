process SNPEFF_ANNOTATE {
    tag "$meta.id"
    label 'process_medium'
    container 'staphb/snpeff:latest'
    publishDir "${params.outdir}/${meta.id}/snpeff", mode: 'copy'
    
    input:
    tuple val(meta), path(vcf)
    
    output:
    tuple val(meta), path("${meta.id}.snpeff.vcf"), emit: vcf
    path "${meta.id}.snpeff.html", emit: report
    path "${meta.id}.snpeff.csv", emit: csv_report
    path "${meta.id}.snpeff.genes.txt", emit: genes
    
    script:
    def db_version = "GRCh37.87"
    def db_path = "${projectDir}/databases/snpeff_data"
    """
    echo "Running SnpEff annotation for ${meta.id}"
    
    # Run SnpEff with local database
    java -Xmx8g -jar /snpEff/snpEff.jar \\
        -dataDir ${db_path} \\
        ${db_version} \\
        -canon \\
        -nodownload \\
        -stats ${meta.id}.snpeff.html \\
        -csvStats ${meta.id}.snpeff.csv \\
        ${vcf} \\
        > ${meta.id}.snpeff.vcf
    
    # Extract gene list using SnpSift
    java -jar /snpEff/SnpSift.jar extractFields \\
        ${meta.id}.snpeff.vcf \\
        "ANN[0].GENE" \\
        | grep -v "^#" \\
        | sort -u > ${meta.id}.snpeff.genes.txt || touch ${meta.id}.snpeff.genes.txt
    """
}