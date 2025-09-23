/*
========================================================================================
    ANNOTATION WORKFLOW - Sequential Annotation Order
========================================================================================
*/

include { SNPEFF_ANNOTATE } from '../modules/snpeff_annotate'
include { SNPSIFT_CLINVAR } from '../modules/snpsift_clinvar'
include { SNPSIFT_HGMD } from '../modules/snpsift_hgmd'
include { SNPSIFT_DBNSFP } from '../modules/snpsift_dbnsfp'
include { SNPSIFT_OMIM } from '../modules/snpsift_omim'

workflow ANNOTATION {
    take:
    ch_vcf  // channel: [ meta, vcf ]
    
    main:
    // Step 1: SnpEff annotation (ALWAYS RUN)
    SNPEFF_ANNOTATE(ch_vcf)
    ch_annotated = SNPEFF_ANNOTATE.out.vcf
    
    // Step 2: ClinVar annotation
    if (!params.skip_clinvar && file(params.clinvar_vcf_37).exists()) {
        SNPSIFT_CLINVAR(ch_annotated)
        ch_annotated = SNPSIFT_CLINVAR.out.vcf
    }
    
    // Step 3: HGMD annotation
    if (!params.skip_hgmd) {
        SNPSIFT_HGMD(ch_annotated)
        ch_annotated = SNPSIFT_HGMD.out.vcf
    }
    
    // Step 4: dbNSFP annotation
    if (!params.skip_dbnsfp) {
        SNPSIFT_DBNSFP(ch_annotated)
        ch_annotated = SNPSIFT_DBNSFP.out.vcf
    }
    
    // Step 5: OMIM annotation
    if (!params.skip_omim) {
        SNPSIFT_OMIM(ch_annotated)
        ch_annotated = SNPSIFT_OMIM.out.vcf
    }
    
    emit:
    annotated_vcf = ch_annotated
    genes = SNPEFF_ANNOTATE.out.genes
    snpeff_report = SNPEFF_ANNOTATE.out.report
    snpeff_csv = SNPEFF_ANNOTATE.out.csv_report
}