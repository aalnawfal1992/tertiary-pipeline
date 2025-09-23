/*
========================================================================================
    ANNOTATION WORKFLOW - Fixed
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
    // SnpEff annotation
    SNPEFF_ANNOTATE(ch_vcf)
    
    // Start with SnpEff output
    ch_annotated = SNPEFF_ANNOTATE.out.vcf
    
    // Skip other annotations for now since they're optional
    
    emit:
    annotated_vcf = ch_annotated
    genes = SNPEFF_ANNOTATE.out.genes
}