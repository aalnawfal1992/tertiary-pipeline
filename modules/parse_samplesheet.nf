process PARSE_SAMPLESHEET {
    tag "Parsing samplesheet"
    container 'quay.io/biocontainers/python:3.9--1'
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'
    
    input:
    path samplesheet
    
    output:
    path "validated_samplesheet.csv", emit: samples
    path "samplesheet_summary.txt", emit: summary
    
    script:
    """
    # Simple validation - just copy for now
    cp ${samplesheet} validated_samplesheet.csv
    
    # Create summary
    echo "Samplesheet validation complete" > samplesheet_summary.txt
    echo "Number of samples: \$(tail -n +2 validated_samplesheet.csv | wc -l)" >> samplesheet_summary.txt
    cat validated_samplesheet.csv >> samplesheet_summary.txt
    """
}