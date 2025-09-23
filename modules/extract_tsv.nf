process EXTRACT_TSV {
    tag "$meta.id"
    publishDir "${params.outdir}/${meta.id}/final", mode: 'copy'
    container 'staphb/snpeff:latest'
    
    input:
    tuple val(meta), path(vcf)
    
    output:
    path "${meta.id}.final.annotated.tsv", emit: tsv
    path "${meta.id}.extraction.log", emit: log
    
    script:
    """
    # Use the exact command that worked for you, adapted for the pipeline
    java -jar /snpEff/SnpSift.jar extractFields \\
        -e "." \\
        -s "," \\
        ${vcf} \\
        CHROM POS ID REF ALT QUAL FILTER \\
        "ANN[*].ALLELE" "ANN[*].EFFECT" "ANN[*].IMPACT" "ANN[*].GENE" "ANN[*].GENEID" \\
        "ANN[*].FEATURE" "ANN[*].FEATUREID" "ANN[*].BIOTYPE" "ANN[*].RANK" \\
        "ANN[*].HGVS_C" "ANN[*].HGVS_P" "ANN[*].CDNA_POS" "ANN[*].CDS_POS" "ANN[*].AA_POS" "ANN[*].DISTANCE" \\
        CLNSIG CLNREVSTAT CLNDN CLNHGVS CLASS MUT \\
        dbNSFP_GERP___RS dbNSFP_GERP___NR dbNSFP_1000Gp3_AF dbNSFP_1000Gp3_EUR_AF dbNSFP_1000Gp3_AFR_AF \\
        dbNSFP_1000Gp3_EAS_AF dbNSFP_1000Gp3_SAS_AF dbNSFP_SIFT_pred dbNSFP_PROVEAN_pred \\
        GT DP AD \\
        > ${meta.id}.final.annotated.tsv 2> ${meta.id}.extraction.log || true
    
    # Check if file was created successfully
    if [ -f "${meta.id}.final.annotated.tsv" ]; then
        lines=\$(wc -l < ${meta.id}.final.annotated.tsv)
        echo "Successfully created TSV with \$lines lines" >> ${meta.id}.extraction.log
    else
        echo "Failed to create TSV file" >> ${meta.id}.extraction.log
        exit 1
    fi
    """
}