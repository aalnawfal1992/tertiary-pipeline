#!/bin/bash
# File: bin/check_dbnsfp_fields.sh
# Script to check which fields exist in your dbNSFP database

DB_PATH="/home/abudllah/Desktop/tertiary-pipeline/databases/dbnsfp/dbNSFP5.2c_grch37.gz"

echo "Checking available fields in your dbNSFP database..."
echo "=================================================="

# Get header line
HEADER=$(zcat "$DB_PATH" | head -1)

# List of fields we want to check
FIELDS_TO_CHECK="clinvar_id clinvar_clnsig clinvar_trait clinvar_review clinvar_hgvs
clinvar_var_source clinvar_MedGen_id clinvar_OMIM_id
SIFT_pred SIFT_score SIFT4G_pred SIFT4G_score
MutationTaster_pred MutationTaster_score MutationTaster_model
MutationAssessor_pred MutationAssessor_score
PROVEAN_pred PROVEAN_score
MetaSVM_pred MetaSVM_score MetaSVM_rankscore
MetaLR_pred MetaLR_score MetaLR_rankscore
MetaRNN_pred MetaRNN_score
REVEL_score REVEL_rankscore
MutPred2_score MutPred2_pred MutPred2_rankscore
MVP_score MVP_rankscore
MPC_score MPC_rankscore
PrimateAI_pred PrimateAI_score
DEOGEN2_pred DEOGEN2_score
BayesDel_addAF_pred BayesDel_addAF_score
BayesDel_noAF_pred BayesDel_noAF_score
ClinPred_pred ClinPred_score
LIST-S2_pred LIST-S2_score
VARITY_R_score VARITY_ER_score
AlphaMissense_pred AlphaMissense_score
ESM1b_pred ESM1b_score
DANN_score DANN_rankscore
fathmm-XF_coding_pred fathmm-XF_coding_score
Eigen-phred_coding Eigen-PC-phred_coding
GERP++_NR GERP++_RS
phyloP100way_vertebrate phyloP470way_mammalian phyloP17way_primate
phastCons100way_vertebrate phastCons470way_mammalian phastCons17way_primate
bStatistic
1000Gp3_AC 1000Gp3_AF
1000Gp3_EUR_AC 1000Gp3_EUR_AF
1000Gp3_EAS_AC 1000Gp3_EAS_AF
1000Gp3_AFR_AC 1000Gp3_AFR_AF
1000Gp3_AMR_AC 1000Gp3_AMR_AF
1000Gp3_SAS_AC 1000Gp3_SAS_AF
gnomAD4.1_joint_AF gnomAD4.1_joint_AC
gnomAD4.1_joint_POPMAX_AF gnomAD4.1_joint_POPMAX_AC
gnomAD4.1_joint_AFR_AF gnomAD4.1_joint_AMR_AF
gnomAD4.1_joint_ASJ_AF gnomAD4.1_joint_EAS_AF
gnomAD4.1_joint_FIN_AF gnomAD4.1_joint_NFE_AF
gnomAD4.1_joint_SAS_AF
AllofUs_ALL_AF AllofUs_ALL_AC
AllofUs_POPMAX_AF AllofUs_POPMAX_AC
AllofUs_AFR_AF AllofUs_AMR_AF AllofUs_EAS_AF
AllofUs_EUR_AF AllofUs_SAS_AF
TOPMed_frz8_AF TOPMed_frz8_AC
ALFA_Total_AF ALFA_European_AF ALFA_African_AF ALFA_Asian_AF
Interpro_domain genename Ensembl_geneid
HGVSc_VEP HGVSp_VEP
Ancestral_allele
Aloft_pred Aloft_prob_Tolerant Aloft_prob_Recessive Aloft_prob_Dominant"

echo "Fields found in database:"
echo ""
for field in $FIELDS_TO_CHECK; do
    if echo "$HEADER" | grep -q "\b${field}\b"; then
        echo "✓ $field"
    else
        echo "✗ $field (NOT FOUND)"
    fi
done