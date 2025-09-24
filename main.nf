#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
========================================================================================
    Clinical VCF Annotation Pipeline with Exomiser
========================================================================================
    Author: Bioinformatics team @ Liferaomics
    Version: 1.1.0
    Description: Sequential annotation pipeline for clinical VCF files with phenotype analysis
    
    Annotations applied in order:
    1. SnpEff - Gene/transcript functional effects
    2. ClinVar - Clinical significance
    3. HGMD - Human Gene Mutation Database
    4. dbNSFP - Pathogenicity scores and population frequencies
    5. OMIM - Online Mendelian Inheritance in Man (optional)
    6. Exomiser - Phenotype-driven variant prioritization
========================================================================================
*/

// Pipeline version
version = '1.1.0_Beta'

// Import workflows
include { ANNOTATION } from './workflows/annotation'

// Import modules
include { PARSE_SAMPLESHEET } from './modules/parse_samplesheet'
include { SAVE_FINAL_VCF } from './modules/save_final_vcf'
include { EXTRACT_TSV } from './modules/extract_tsv'
include { EXOMISER_ANALYSIS } from './modules/exomiser_analysis'

// Print pipeline header
log.info """
====================================
Clinical VCF Annotation Pipeline "We call it Tertiary Pipeline"
====================================
Version      : ${version}
Samplesheet  : ${params.samplesheet}
Output dir   : ${params.outdir}
------------------------------------
Annotation Order:
1. SnpEff     : Always run
2. ClinVar    : ${params.skip_clinvar ? 'SKIP' : 'RUN'}
3. HGMD       : ${params.skip_hgmd ? 'SKIP' : 'RUN'}
4. dbNSFP     : ${params.skip_dbnsfp ? 'SKIP' : 'RUN'}
5. OMIM       : ${params.skip_omim ? 'SKIP' : 'RUN'}
------------------------------------
6. Exomiser     : ${params.skip_exomiser ? 'SKIP' : 'RUN on ' + params.exomiser_run_on + ' VCF'}
7. Extract TSV  : ${params.skip_tsv ? 'SKIP' : 'RUN'}
====================================
This pipeline still under validation
====================================
To Do:
1. fix dbnsfp processing botelnick
2. Test on AWS "assigned to Waleed Osman"
3. Add more annotation information
====================================
"""

// Validate inputs
if (!params.samplesheet) {
    error "ERROR: Please provide a samplesheet with --samplesheet"
}

if (!file(params.samplesheet).exists()) {
    error "ERROR: Samplesheet file not found: ${params.samplesheet}"
}

// Check Exomiser configuration if enabled
if (!params.skip_exomiser) {
    if (!file(params.exomiser_jar).exists()) {
        error "ERROR: Exomiser JAR not found: ${params.exomiser_jar}"
    }
    if (!file(params.exomiser_data_dir).exists()) {
        error "ERROR: Exomiser data directory not found: ${params.exomiser_data_dir}"
    }
}

// Main workflow
workflow {
    
    // Parse and validate samplesheet
    Channel
        .fromPath(params.samplesheet, checkIfExists: true)
        .set { ch_samplesheet }
    
    PARSE_SAMPLESHEET(ch_samplesheet)
    
    // Create samples channel from validated samplesheet
    PARSE_SAMPLESHEET.out.samples
        .splitCsv(header: true)
        .map { row ->
            // Create metadata map
            def meta = [:]
            meta.id = row.sample_id
            meta.assembly = row.assembly
            meta.hpo_terms = row.hpo_terms ?: ""  // HPO terms for Exomiser
            
            // Validate assembly version
            if (meta.assembly != "37" && meta.assembly != "38") {
                error "ERROR: Assembly must be 37 or 38, got: ${meta.assembly} for sample ${meta.id}"
            }
            
            // Check VCF file exists
            def vcf_file = file(row.vcf_path)
            if (!vcf_file.exists()) {
                error "ERROR: VCF file not found: ${row.vcf_path} for sample ${meta.id}"
            }
            
            tuple(meta, vcf_file)
        }
        .set { ch_samples }
    
    // Run Exomiser on raw VCF if configured
    if (!params.skip_exomiser && params.exomiser_run_on == 'raw') {
        EXOMISER_ANALYSIS(ch_samples)
    }
    
    // Run sequential annotation workflow
    // Order: SnpEff -> ClinVar -> HGMD -> dbNSFP -> OMIM
    ANNOTATION(ch_samples)
    
    // Save final annotated VCF with simple naming
    SAVE_FINAL_VCF(ANNOTATION.out.annotated_vcf)
    
    // Run Exomiser on annotated VCF if configured
    if (!params.skip_exomiser && params.exomiser_run_on == 'annotated') {
        EXOMISER_ANALYSIS(SAVE_FINAL_VCF.out.vcf)
    }
    
    // Extract TSV tables from annotated VCF if not skipped
    if (!params.skip_tsv) {
        EXTRACT_TSV(SAVE_FINAL_VCF.out.vcf)
    }
}

// Workflow completion handler
workflow.onComplete {
    def status = workflow.success ? 'SUCCESS ✓' : 'FAILED ✗'
    def color = workflow.success ? '\033[0;32m' : '\033[0;31m'
    def reset = '\033[0m'
    
    log.info """
    ${color}
    ========================================
    Pipeline completed!
    ========================================
    ${reset}
    Execution status : ${status}
    Duration         : ${workflow.duration}
    Output directory : ${params.outdir}
    
    Output files:
    - Final VCFs     : ${params.outdir}/[sample_id]/final/
    - TSV tables     : ${params.outdir}/[sample_id]/tables/
    - SnpEff reports : ${params.outdir}/[sample_id]/snpeff/
    - Annotations    : ${params.outdir}/[sample_id]/annotations/
    - Exomiser       : ${params.outdir}/[sample_id]/exomiser/
    - Pipeline info  : ${params.outdir}/pipeline_info/
    ========================================
    """.stripIndent()
    
    if (!workflow.success) {
        log.error "Pipeline failed. Please check the logs for details."
    }
}

// Workflow error handler
workflow.onError {
    log.error """
    ========================================
    Pipeline execution error!
    ========================================
    Error message: ${workflow.errorMessage}
    Error report: ${workflow.errorReport}
    
    Please check:
    1. Input files exist and are readable
    2. Database files are properly configured
    3. Docker/Singularity is running (for annotation modules)
    4. Exomiser is properly installed (if enabled)
    5. Sufficient memory is available
    ========================================
    After identifing the issue do:
    1. Try to fix it 
    2. Google it
    3. Use chatGPT
    4. Lastly, Contact one of Bioinformatics member "#Be_Independent"
    """.stripIndent()
}