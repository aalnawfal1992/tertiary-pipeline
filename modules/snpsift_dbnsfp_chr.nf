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
    
    // Pre-defined complete field list for dbNSFP 5.2c
    def all_fields_list = "aaref,aaalt,rs_dbSNP,hg19_chr,hg19_pos(1-based),hg18_chr,hg18_pos(1-based),aapos,genename,Ensembl_geneid,Ensembl_transcriptid,Ensembl_proteinid,Uniprot_acc,Uniprot_entry,HGVSc_snpEff,HGVSp_snpEff,HGVSc_VEP,HGVSp_VEP,APPRIS,GENCODE_basic,TSL,VEP_canonical,MANE,cds_strand,refcodon,codonpos,codon_degeneracy,Ancestral_allele,AltaiNeandertal,Denisova,VindijiaNeandertal,ChagyrskayaNeandertal,clinvar_id,clinvar_clnsig,clinvar_trait,clinvar_review,clinvar_hgvs,clinvar_var_source,clinvar_MedGen_id,clinvar_OMIM_id,clinvar_Orphanet_id,Interpro_domain,SIFT_score,SIFT_converted_rankscore,SIFT_pred,SIFT4G_score,SIFT4G_converted_rankscore,SIFT4G_pred,MutationTaster_score,MutationTaster_rankscore,MutationTaster_pred,MutationTaster_model,MutationTaster_trees_benign,MutationTaster_trees_deleterious,MutationAssessor_score,MutationAssessor_rankscore,MutationAssessor_pred,PROVEAN_score,PROVEAN_converted_rankscore,PROVEAN_pred,MetaSVM_score,MetaSVM_rankscore,MetaSVM_pred,MetaLR_score,MetaLR_rankscore,MetaLR_pred,Reliability_index,MetaRNN_score,MetaRNN_rankscore,MetaRNN_pred,REVEL_score,REVEL_rankscore,MutPred2_score,MutPred2_rankscore,MutPred2_pred,MutPred2_top5_mechanisms,MVP_score,MVP_rankscore,gMVP_score,gMVP_rankscore,MPC_score,MPC_rankscore,PrimateAI_score,PrimateAI_rankscore,PrimateAI_pred,DEOGEN2_score,DEOGEN2_rankscore,DEOGEN2_pred,BayesDel_addAF_score,BayesDel_addAF_rankscore,BayesDel_addAF_pred,BayesDel_noAF_score,BayesDel_noAF_rankscore,BayesDel_noAF_pred,ClinPred_score,ClinPred_rankscore,ClinPred_pred,LIST-S2_score,LIST-S2_rankscore,LIST-S2_pred,VARITY_R_score,VARITY_R_rankscore,VARITY_ER_score,VARITY_ER_rankscore,VARITY_R_LOO_score,VARITY_R_LOO_rankscore,VARITY_ER_LOO_score,VARITY_ER_LOO_rankscore,ESM1b_score,ESM1b_converted_rankscore,ESM1b_pred,AlphaMissense_score,AlphaMissense_rankscore,AlphaMissense_pred,PHACTboost_score,PHACTboost_rankscore,MutFormer_score,MutFormer_rankscore,Aloft_Fraction_transcripts_affected,Aloft_prob_Tolerant,Aloft_prob_Recessive,Aloft_prob_Dominant,Aloft_pred,Aloft_Confidence,DANN_score,DANN_rankscore,fathmm-XF_coding_score,fathmm-XF_coding_rankscore,fathmm-XF_coding_pred,Eigen-raw_coding,Eigen-raw_coding_rankscore,Eigen-phred_coding,Eigen-PC-raw_coding,Eigen-PC-raw_coding_rankscore,Eigen-PC-phred_coding,GERP++_NR,GERP++_RS,GERP++_RS_rankscore,GERP_91_mammals,GERP_91_mammals_rankscore,phyloP100way_vertebrate,phyloP100way_vertebrate_rankscore,phyloP470way_mammalian,phyloP470way_mammalian_rankscore,phyloP17way_primate,phyloP17way_primate_rankscore,phastCons100way_vertebrate,phastCons100way_vertebrate_rankscore,phastCons470way_mammalian,phastCons470way_mammalian_rankscore,phastCons17way_primate,phastCons17way_primate_rankscore,bStatistic,bStatistic_converted_rankscore,1000Gp3_AC,1000Gp3_AF,1000Gp3_AFR_AC,1000Gp3_AFR_AF,1000Gp3_EUR_AC,1000Gp3_EUR_AF,1000Gp3_AMR_AC,1000Gp3_AMR_AF,1000Gp3_EAS_AC,1000Gp3_EAS_AF,1000Gp3_SAS_AC,1000Gp3_SAS_AF,TOPMed_frz8_AC,TOPMed_frz8_AN,TOPMed_frz8_AF,AllofUs_ALL_AC,AllofUs_ALL_AN,AllofUs_ALL_AF,AllofUs_AFR_AC,AllofUs_AFR_AN,AllofUs_AFR_AF,AllofUs_AMR_AC,AllofUs_AMR_AN,AllofUs_AMR_AF,AllofUs_EAS_AC,AllofUs_EAS_AN,AllofUs_EAS_AF,AllofUs_EUR_AC,AllofUs_EUR_AN,AllofUs_EUR_AF,AllofUs_MID_AC,AllofUs_MID_AN,AllofUs_MID_AF,AllofUs_SAS_AC,AllofUs_SAS_AN,AllofUs_SAS_AF,AllofUs_OTH_AC,AllofUs_OTH_AN,AllofUs_OTH_AF,AllofUs_POPMAX_AF,AllofUs_POPMAX_AC,AllofUs_POPMAX_AN,AllofUs_POPMAX_POP,gnomAD2.1.1_exomes_flag,gnomAD2.1.1_exomes_controls_AC,gnomAD2.1.1_exomes_controls_AN,gnomAD2.1.1_exomes_controls_AF,gnomAD2.1.1_exomes_controls_nhomalt,gnomAD2.1.1_exomes_non_neuro_AC,gnomAD2.1.1_exomes_non_neuro_AN,gnomAD2.1.1_exomes_non_neuro_AF,gnomAD2.1.1_exomes_non_neuro_nhomalt,gnomAD2.1.1_exomes_non_cancer_AC,gnomAD2.1.1_exomes_non_cancer_AN,gnomAD2.1.1_exomes_non_cancer_AF,gnomAD2.1.1_exomes_non_cancer_nhomalt,gnomAD2.1.1_exomes_controls_AFR_AC,gnomAD2.1.1_exomes_controls_AFR_AN,gnomAD2.1.1_exomes_controls_AFR_AF,gnomAD2.1.1_exomes_controls_AFR_nhomalt,gnomAD2.1.1_exomes_controls_AMR_AC,gnomAD2.1.1_exomes_controls_AMR_AN,gnomAD2.1.1_exomes_controls_AMR_AF,gnomAD2.1.1_exomes_controls_AMR_nhomalt,gnomAD2.1.1_exomes_controls_ASJ_AC,gnomAD2.1.1_exomes_controls_ASJ_AN,gnomAD2.1.1_exomes_controls_ASJ_AF,gnomAD2.1.1_exomes_controls_ASJ_nhomalt,gnomAD2.1.1_exomes_controls_EAS_AC,gnomAD2.1.1_exomes_controls_EAS_AN,gnomAD2.1.1_exomes_controls_EAS_AF,gnomAD2.1.1_exomes_controls_EAS_nhomalt,gnomAD2.1.1_exomes_controls_FIN_AC,gnomAD2.1.1_exomes_controls_FIN_AN,gnomAD2.1.1_exomes_controls_FIN_AF,gnomAD2.1.1_exomes_controls_FIN_nhomalt,gnomAD2.1.1_exomes_controls_NFE_AC,gnomAD2.1.1_exomes_controls_NFE_AN,gnomAD2.1.1_exomes_controls_NFE_AF,gnomAD2.1.1_exomes_controls_NFE_nhomalt,gnomAD2.1.1_exomes_controls_SAS_AC,gnomAD2.1.1_exomes_controls_SAS_AN,gnomAD2.1.1_exomes_controls_SAS_AF,gnomAD2.1.1_exomes_controls_SAS_nhomalt,gnomAD2.1.1_exomes_controls_POPMAX_AC,gnomAD2.1.1_exomes_controls_POPMAX_AN,gnomAD2.1.1_exomes_controls_POPMAX_AF,gnomAD2.1.1_exomes_controls_POPMAX_nhomalt,gnomAD2.1.1_exomes_non_neuro_AFR_AC,gnomAD2.1.1_exomes_non_neuro_AFR_AN,gnomAD2.1.1_exomes_non_neuro_AFR_AF,gnomAD2.1.1_exomes_non_neuro_AFR_nhomalt,gnomAD2.1.1_exomes_non_neuro_AMR_AC,gnomAD2.1.1_exomes_non_neuro_AMR_AN,gnomAD2.1.1_exomes_non_neuro_AMR_AF,gnomAD2.1.1_exomes_non_neuro_AMR_nhomalt,gnomAD2.1.1_exomes_non_neuro_ASJ_AC,gnomAD2.1.1_exomes_non_neuro_ASJ_AN,gnomAD2.1.1_exomes_non_neuro_ASJ_AF,gnomAD2.1.1_exomes_non_neuro_ASJ_nhomalt,gnomAD2.1.1_exomes_non_neuro_EAS_AC,gnomAD2.1.1_exomes_non_neuro_EAS_AN,gnomAD2.1.1_exomes_non_neuro_EAS_AF,gnomAD2.1.1_exomes_non_neuro_EAS_nhomalt,gnomAD2.1.1_exomes_non_neuro_FIN_AC,gnomAD2.1.1_exomes_non_neuro_FIN_AN,gnomAD2.1.1_exomes_non_neuro_FIN_AF,gnomAD2.1.1_exomes_non_neuro_FIN_nhomalt,gnomAD2.1.1_exomes_non_neuro_NFE_AC,gnomAD2.1.1_exomes_non_neuro_NFE_AN,gnomAD2.1.1_exomes_non_neuro_NFE_AF,gnomAD2.1.1_exomes_non_neuro_NFE_nhomalt,gnomAD2.1.1_exomes_non_neuro_SAS_AC,gnomAD2.1.1_exomes_non_neuro_SAS_AN,gnomAD2.1.1_exomes_non_neuro_SAS_AF,gnomAD2.1.1_exomes_non_neuro_SAS_nhomalt,gnomAD2.1.1_exomes_non_neuro_POPMAX_AC,gnomAD2.1.1_exomes_non_neuro_POPMAX_AN,gnomAD2.1.1_exomes_non_neuro_POPMAX_AF,gnomAD2.1.1_exomes_non_neuro_POPMAX_nhomalt,gnomAD2.1.1_exomes_non_cancer_AFR_AC,gnomAD2.1.1_exomes_non_cancer_AFR_AN,gnomAD2.1.1_exomes_non_cancer_AFR_AF,gnomAD2.1.1_exomes_non_cancer_AFR_nhomalt,gnomAD2.1.1_exomes_non_cancer_AMR_AC,gnomAD2.1.1_exomes_non_cancer_AMR_AN,gnomAD2.1.1_exomes_non_cancer_AMR_AF,gnomAD2.1.1_exomes_non_cancer_AMR_nhomalt,gnomAD2.1.1_exomes_non_cancer_ASJ_AC,gnomAD2.1.1_exomes_non_cancer_ASJ_AN,gnomAD2.1.1_exomes_non_cancer_ASJ_AF,gnomAD2.1.1_exomes_non_cancer_ASJ_nhomalt,gnomAD2.1.1_exomes_non_cancer_EAS_AC,gnomAD2.1.1_exomes_non_cancer_EAS_AN,gnomAD2.1.1_exomes_non_cancer_EAS_AF,gnomAD2.1.1_exomes_non_cancer_EAS_nhomalt,gnomAD2.1.1_exomes_non_cancer_FIN_AC,gnomAD2.1.1_exomes_non_cancer_FIN_AN,gnomAD2.1.1_exomes_non_cancer_FIN_AF,gnomAD2.1.1_exomes_non_cancer_FIN_nhomalt,gnomAD2.1.1_exomes_non_cancer_NFE_AC,gnomAD2.1.1_exomes_non_cancer_NFE_AN,gnomAD2.1.1_exomes_non_cancer_NFE_AF,gnomAD2.1.1_exomes_non_cancer_NFE_nhomalt,gnomAD2.1.1_exomes_non_cancer_SAS_AC,gnomAD2.1.1_exomes_non_cancer_SAS_AN,gnomAD2.1.1_exomes_non_cancer_SAS_AF,gnomAD2.1.1_exomes_non_cancer_SAS_nhomalt,gnomAD2.1.1_exomes_non_cancer_POPMAX_AC,gnomAD2.1.1_exomes_non_cancer_POPMAX_AN,gnomAD2.1.1_exomes_non_cancer_POPMAX_AF,gnomAD2.1.1_exomes_non_cancer_POPMAX_nhomalt,gnomAD4.1_joint_flag,gnomAD4.1_joint_AC,gnomAD4.1_joint_AN,gnomAD4.1_joint_AF,gnomAD4.1_joint_nhomalt,gnomAD4.1_joint_POPMAX_AC,gnomAD4.1_joint_POPMAX_AN,gnomAD4.1_joint_POPMAX_AF,gnomAD4.1_joint_POPMAX_nhomalt,gnomAD4.1_joint_AFR_AC,gnomAD4.1_joint_AFR_AN,gnomAD4.1_joint_AFR_AF,gnomAD4.1_joint_AFR_nhomalt,gnomAD4.1_joint_AMI_AC,gnomAD4.1_joint_AMI_AN,gnomAD4.1_joint_AMI_AF,gnomAD4.1_joint_AMI_nhomalt,gnomAD4.1_joint_AMR_AC,gnomAD4.1_joint_AMR_AN,gnomAD4.1_joint_AMR_AF,gnomAD4.1_joint_AMR_nhomalt,gnomAD4.1_joint_ASJ_AC,gnomAD4.1_joint_ASJ_AN,gnomAD4.1_joint_ASJ_AF,gnomAD4.1_joint_ASJ_nhomalt,gnomAD4.1_joint_EAS_AC,gnomAD4.1_joint_EAS_AN,gnomAD4.1_joint_EAS_AF,gnomAD4.1_joint_EAS_nhomalt,gnomAD4.1_joint_FIN_AC,gnomAD4.1_joint_FIN_AN,gnomAD4.1_joint_FIN_AF,gnomAD4.1_joint_FIN_nhomalt,gnomAD4.1_joint_MID_AC,gnomAD4.1_joint_MID_AN,gnomAD4.1_joint_MID_AF,gnomAD4.1_joint_MID_nhomalt,gnomAD4.1_joint_NFE_AC,gnomAD4.1_joint_NFE_AN,gnomAD4.1_joint_NFE_AF,gnomAD4.1_joint_NFE_nhomalt,gnomAD4.1_joint_SAS_AC,gnomAD4.1_joint_SAS_AN,gnomAD4.1_joint_SAS_AF,gnomAD4.1_joint_SAS_nhomalt,ALFA_European_AC,ALFA_European_AN,ALFA_European_AF,ALFA_African_Others_AC,ALFA_African_Others_AN,ALFA_African_Others_AF,ALFA_East_Asian_AC,ALFA_East_Asian_AN,ALFA_East_Asian_AF,ALFA_African_American_AC,ALFA_African_American_AN,ALFA_African_American_AF,ALFA_Latin_American_1_AC,ALFA_Latin_American_1_AN,ALFA_Latin_American_1_AF,ALFA_Latin_American_2_AC,ALFA_Latin_American_2_AN,ALFA_Latin_American_2_AF,ALFA_Other_Asian_AC,ALFA_Other_Asian_AN,ALFA_Other_Asian_AF,ALFA_South_Asian_AC,ALFA_South_Asian_AN,ALFA_South_Asian_AF,ALFA_Other_AC,ALFA_Other_AN,ALFA_Other_AF,ALFA_African_AC,ALFA_African_AN,ALFA_African_AF,ALFA_Asian_AC,ALFA_Asian_AN,ALFA_Asian_AF,ALFA_Total_AC,ALFA_Total_AN,ALFA_Total_AF,dbNSFP_POPMAX_AF,dbNSFP_POPMAX_AC,dbNSFP_POPMAX_POP"
    
    // Define fields based on selection level
    def fields = ""
    if (params.dbnsfp_fields_level == "minimal") {
        fields = "clinvar_id,clinvar_clnsig,clinvar_trait,SIFT_pred,REVEL_score,AlphaMissense_pred,gnomAD4.1_joint_AF"
        
    } else if (params.dbnsfp_fields_level == "standard") {
        fields = "clinvar_id,clinvar_clnsig,clinvar_trait,clinvar_review,SIFT_pred,SIFT_score,MutationTaster_pred,MutationTaster_score,PROVEAN_pred,MetaSVM_pred,MetaLR_pred,REVEL_score,AlphaMissense_pred,AlphaMissense_score,DEOGEN2_pred,BayesDel_addAF_pred,ClinPred_pred,GERP++_RS,phyloP100way_vertebrate,phastCons100way_vertebrate,1000Gp3_AF,1000Gp3_EUR_AF,1000Gp3_EAS_AF,1000Gp3_AFR_AF,gnomAD4.1_joint_AF,gnomAD4.1_joint_POPMAX_AF,AllofUs_ALL_AF,TOPMed_frz8_AF,Interpro_domain,genename"
        
    } else if (params.dbnsfp_fields_level == "comprehensive") {
        fields = "clinvar_id,clinvar_clnsig,clinvar_trait,clinvar_review,clinvar_hgvs,clinvar_var_source,clinvar_MedGen_id,clinvar_OMIM_id,SIFT_pred,SIFT_score,SIFT4G_pred,SIFT4G_score,MutationTaster_pred,MutationTaster_score,MutationTaster_model,MutationAssessor_pred,MutationAssessor_score,PROVEAN_pred,PROVEAN_score,MetaSVM_pred,MetaSVM_score,MetaSVM_rankscore,MetaLR_pred,MetaLR_score,MetaLR_rankscore,MetaRNN_pred,MetaRNN_score,REVEL_score,REVEL_rankscore,MutPred2_score,MutPred2_pred,MutPred2_rankscore,MVP_score,MVP_rankscore,MPC_score,MPC_rankscore,PrimateAI_pred,PrimateAI_score,DEOGEN2_pred,DEOGEN2_score,BayesDel_addAF_pred,BayesDel_addAF_score,BayesDel_noAF_pred,BayesDel_noAF_score,ClinPred_pred,ClinPred_score,LIST-S2_pred,LIST-S2_score,VARITY_R_score,VARITY_ER_score,AlphaMissense_pred,AlphaMissense_score,ESM1b_pred,ESM1b_score,DANN_score,DANN_rankscore,fathmm-XF_coding_pred,fathmm-XF_coding_score,Eigen-phred_coding,Eigen-PC-phred_coding,GERP++_NR,GERP++_RS,phyloP100way_vertebrate,phyloP470way_mammalian,phyloP17way_primate,phastCons100way_vertebrate,phastCons470way_mammalian,phastCons17way_primate,bStatistic,1000Gp3_AC,1000Gp3_AF,1000Gp3_EUR_AC,1000Gp3_EUR_AF,1000Gp3_EAS_AC,1000Gp3_EAS_AF,1000Gp3_AFR_AC,1000Gp3_AFR_AF,1000Gp3_AMR_AC,1000Gp3_AMR_AF,1000Gp3_SAS_AC,1000Gp3_SAS_AF,gnomAD4.1_joint_AF,gnomAD4.1_joint_AC,gnomAD4.1_joint_POPMAX_AF,gnomAD4.1_joint_POPMAX_AC,gnomAD4.1_joint_AFR_AF,gnomAD4.1_joint_AMR_AF,gnomAD4.1_joint_ASJ_AF,gnomAD4.1_joint_EAS_AF,gnomAD4.1_joint_FIN_AF,gnomAD4.1_joint_NFE_AF,gnomAD4.1_joint_SAS_AF,AllofUs_ALL_AF,AllofUs_ALL_AC,AllofUs_POPMAX_AF,AllofUs_POPMAX_AC,AllofUs_AFR_AF,AllofUs_AMR_AF,AllofUs_EAS_AF,AllofUs_EUR_AF,AllofUs_SAS_AF,TOPMed_frz8_AF,TOPMed_frz8_AC,ALFA_Total_AF,ALFA_European_AF,ALFA_African_AF,ALFA_Asian_AF,Interpro_domain,genename,Ensembl_geneid,HGVSc_VEP,HGVSp_VEP,Ancestral_allele,Aloft_pred,Aloft_prob_Tolerant,Aloft_prob_Recessive,Aloft_prob_Dominant"
        
    } else if (params.dbnsfp_fields_level == "all") {
        // Use the pre-defined complete list
        fields = all_fields_list
    } else {
        fields = "clinvar_clnsig,SIFT_pred,REVEL_score,AlphaMissense_pred,gnomAD4.1_joint_AF"
    }
    
    """
    if [ -f "${dbnsfp}" ]; then
        echo "Starting dbNSFP annotation for ${chr_name}..." > ${chr_vcf.baseName}.dbnsfp.log
        echo "Database: ${dbnsfp}" >> ${chr_vcf.baseName}.dbnsfp.log
        echo "Input VCF: ${chr_vcf}" >> ${chr_vcf.baseName}.dbnsfp.log
        echo "Field selection level: ${params.dbnsfp_fields_level}" >> ${chr_vcf.baseName}.dbnsfp.log
        
        input_vars=\$(grep -v '^#' ${chr_vcf} | wc -l)
        echo "Input variants: \${input_vars}" >> ${chr_vcf.baseName}.dbnsfp.log
        
        if [ -n "${fields}" ]; then
            num_fields=\$(echo "${fields}" | tr ',' '\\n' | wc -l)
            echo "Number of fields to annotate: \${num_fields}" >> ${chr_vcf.baseName}.dbnsfp.log
            
            java ${memory} -jar /snpEff/SnpSift.jar dbnsfp \\
                -v \\
                -f "${fields}" \\
                -db ${dbnsfp} \\
                ${chr_vcf} \\
                > ${chr_vcf.baseName}.dbnsfp.vcf 2>> ${chr_vcf.baseName}.dbnsfp.log
        else
            echo "ERROR: No fields specified" >> ${chr_vcf.baseName}.dbnsfp.log
            cp ${chr_vcf} ${chr_vcf.baseName}.dbnsfp.vcf
        fi
        
        # Verify annotation
        if [ -s "${chr_vcf.baseName}.dbnsfp.vcf" ]; then
            output_vars=\$(grep -v '^#' ${chr_vcf.baseName}.dbnsfp.vcf | wc -l)
            echo "Output variants: \${output_vars}" >> ${chr_vcf.baseName}.dbnsfp.log
            
            # Count dbNSFP fields added
            dbnsfo_fields=\$(grep "^##INFO=<ID=dbNSFP_" ${chr_vcf.baseName}.dbnsfp.vcf | wc -l)
            echo "dbNSFP fields added: \${dbnsfo_fields}" >> ${chr_vcf.baseName}.dbnsfp.log
        else
            echo "ERROR: Output file is empty" >> ${chr_vcf.baseName}.dbnsfp.log
            cp ${chr_vcf} ${chr_vcf.baseName}.dbnsfp.vcf
        fi
    else
        echo "ERROR: dbNSFP database not found" > ${chr_vcf.baseName}.dbnsfp.log
        cp ${chr_vcf} ${chr_vcf.baseName}.dbnsfp.vcf
    fi
    """
}