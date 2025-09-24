/*
========================================================================================
    ANNOTATION WORKFLOW - With Chromosome Splitting for dbNSFP
========================================================================================
*/

include { SNPEFF_ANNOTATE } from '../modules/snpeff_annotate'
include { SNPSIFT_CLINVAR } from '../modules/snpsift_clinvar'
include { SNPSIFT_HGMD } from '../modules/snpsift_hgmd'
include { SNPSIFT_DBNSFP } from '../modules/snpsift_dbnsfp'
include { SNPSIFT_OMIM } from '../modules/snpsift_omim'
// New modules for chromosome splitting
include { SPLIT_VCF_BY_CHR } from '../modules/split_vcf_by_chr'
include { SNPSIFT_DBNSFP_CHR } from '../modules/snpsift_dbnsfp_chr'
include { COMPRESS_VCFS } from '../modules/compress_vcfs'
include { MERGE_CHR_VCFS } from '../modules/merge_chr_vcfs'

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
    
    // Step 4: dbNSFP annotation (with optional chromosome splitting)
    if (!params.skip_dbnsfp) {
        if (params.split_dbnsfp_by_chr) {
            // Split VCF by chromosome
            SPLIT_VCF_BY_CHR(ch_annotated)
            
            // Process each chromosome separately
            ch_chr_vcfs = SPLIT_VCF_BY_CHR.out.chr_vcfs
                .transpose()  // Convert to individual chromosome files
                .map { meta, chr_vcf ->
                    // Extract chromosome name from filename
                    def chr_name = chr_vcf.name.replaceAll(/.*\.chr([^.]+)\.vcf/, '$1')
                    tuple(meta, chr_vcf, chr_name)
                }
            
            // Run dbNSFP on each chromosome in parallel
            SNPSIFT_DBNSFP_CHR(ch_chr_vcfs)
            
            // Collect all annotated chromosome VCFs
            ch_annotated_chrs = SNPSIFT_DBNSFP_CHR.out.vcf
                .groupTuple()  // Group by meta (sample)
            
            // Compress the VCFs with indexes
            COMPRESS_VCFS(ch_annotated_chrs)
            
            // Merge using both compressed files and indexes
            // IMPORTANT: Use compressed_vcfs_with_index, not just compressed_vcfs
            MERGE_CHR_VCFS(COMPRESS_VCFS.out.compressed_vcfs_with_index)
            ch_annotated = MERGE_CHR_VCFS.out.vcf
        } else {
            // Original single-file processing
            SNPSIFT_DBNSFP(ch_annotated)
            ch_annotated = SNPSIFT_DBNSFP.out.vcf
        }
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