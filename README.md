#  processing botelnick

A **Nextflow DSL2 pipeline** for clinical variant annotation.  
This project automates annotation of VCF files using multiple public and licensed databases, producing both annotated VCFs and tabular reports using snpEff, snpSIFT, and Exomiser.

---

## 🚀 Features

- **Modular DSL2 workflow** with reusable annotation modules  
- **Supported annotations**:
  - [SnpEff](https://pcingola.github.io/SnpEff/) (functional effects)  
  - [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/)  
  - [dbNSFP](https://sites.google.com/site/jpopgen/dbNSFP/)  
  - [Exomiser](https://exomiser.readthedocs.io/en/latest/index.html/)
    - (Due to unconcistinacy of Exomiser project. Exomiser Version 14.0.0 used for this pipeline)
  - HGMD (*licensed, not included*)  
  - OMIM (*licensed, not included*)  
- **Sample management** via CSV (`samplesheet.csv`)  
- **Python helpers** for parsing
- **Python helpers** for auto-generate yml file for Exomiser
- **Configurable resources** (see `conf/`)  
- **Outputs**: annotated VCFs and TSV summaries  

---

## 📋 Quick Start

### Prerequisites
- Nextflow ≥ 25.04  
- Java 11+  
- Docker or Singularity/Apptainer
- Exomiser "Version 14.0.0" in the nextflow.config
- Databases: ClinVar, dbNSFP, SnpEff, HGMD\*, OMIM\*  
  (\* licensed databases must be obtained separately)

### Run
```bash
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --outdir results \
  -profile docker
````
- **By defaults HGMD, dbNSFP, OMIM are disabiled and clinvar and Exomiser are enabled**:
  - To change that use --skip_<DB_NAME> false 
  - Example --skip_dbnsfp false
## 📁 Project Structure

```
Tertiary_Pipeline/
├── bin/                        # Helper scripts
│   └── parse_samplesheet.py    # Python script to parse the input samplesheet
├── conf/                       # Pipeline configuration files
│   ├── base.config             # Base configuration with shared defaults
│   └── resources_grch37.config # Resource allocation for GRCh37 genome build
├── databases/                  # Reference and annotation databases
│   ├── clinvar/                # ClinVar variant database (VCF + index)
│   ├── dbnsfp/                 # dbNSFP functional predictions (compressed + index)
│   ├── hgmd/                   # HGMD licensed data (VCFs + index)
│   ├── omim/                   # OMIM gene–disease mapping (genemap2.txt)
│   ├── snpEff/                 # SnpEff installation with genome builds, scripts, and examples
│   └── snpeff_data/            # Local copy of SnpEff GRCh37.87 data directory
├── main.nf                     # Main Nextflow pipeline entrypoint
├── modules/                    # Modular Nextflow DSL2 processes
│   ├── annotate.nf             # Master annotation module orchestrating multiple tools
│   ├── extract_tsv.nf          # Extract annotations into TSV format
│   ├── parse_samplesheet.nf    # Parse input samplesheet into workflow variables
│   ├── save_final_vcf.nf       # Save and collect final annotated VCF results
│   ├── snpeff_annotate.nf      # Run SnpEff variant effect annotation
│   ├── snpsift_clinvar.nf      # Annotate with ClinVar using SnpSift
│   ├── snpsift_dbnsfp.nf       # Annotate with dbNSFP using SnpSift
│   ├── snpsift_hgmd.nf         # Annotate with HGMD using SnpSift
│   └── snpsift_omim.nf         # Annotate with OMIM using SnpSift
├── nextflow.config             # Top-level Nextflow configuration
├── README.md                   # Project documentation and usage instructions
├── samplesheet.csv             # Input sample metadata for the pipeline
├── tools/                      # Additional external tools or wrappers
│   └── snpEff/                 # Local copy or wrapper scripts for SnpEff
└── workflows/                  # High-level workflow definitions
    └── annotation.nf           # Annotation workflow chaining modules
```

### Usage Examples

```bash
# Run the pipeline with example samplesheet
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --outdir results \
  -profile docker

# Skip HGMD and OMIM (licensed databases not available)
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --outdir results \
  --skip_hgmd true \
  --skip_omim true \
  -profile docker

# Enable dbNSFP annotation
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --outdir results \
  --skip_dbnsfp false \
  -profile docker

# Resume from last run (useful if execution stopped)
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --outdir results \
  -profile docker \
  -resume
```

### Last working run output

```bash
(base) abudllah@abudllah:~/Desktop/tertiary-pipeline$ nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --outdir results \
  --skip_hgmd false \
  --skip_dbnsfp false \
  --skip_omim true \
  -profile docker

 N E X T F L O W   ~  version 25.04.6

Launching `main.nf` [voluminous_rutherford] DSL2 - revision: 6a986071ca


====================================
Clinical VCF Annotation Pipeline "We call it Tertiary Pipeline"
====================================
Version      : 1.1.0_Beta
Samplesheet  : samplesheet.csv
Output dir   : results
------------------------------------
Annotation Order:
1. SnpEff     : Always run
2. ClinVar    : RUN
3. HGMD       : RUN
4. dbNSFP     : RUN
5. OMIM       : SKIP
------------------------------------
6. Exomiser     : RUN on raw VCF
7. Extract TSV  : RUN
====================================
This pipeline still under validation
====================================
To Do:
1. fix dbnsfp processing botelnick
2. Test on AWS "assigned to Waleed Osman"
3. Add more annotation information
====================================

executor >  local (8)
executor >  local (8)
[09/ac98d4] process > PARSE_SAMPLESHEET (Parsing samplesheet) [100%] 1 of 1 ✔
[4c/8c250e] process > EXOMISER_ANALYSIS (NA12878)             [100%] 1 of 1 ✔
[0d/f5b8cf] process > ANNOTATION:SNPEFF_ANNOTATE (NA12878)    [100%] 1 of 1 ✔
[1d/125090] process > ANNOTATION:SNPSIFT_CLINVAR (NA12878)    [100%] 1 of 1 ✔
[76/fdce91] process > ANNOTATION:SNPSIFT_HGMD (NA12878)       [100%] 1 of 1 ✔
[ce/c3fa87] process > ANNOTATION:SNPSIFT_DBNSFP (NA12878)     [100%] 1 of 1 ✔
[8c/d5c75b] process > SAVE_FINAL_VCF (NA12878)                [100%] 1 of 1 ✔
[55/09540b] process > EXTRACT_TSV (NA12878)                   [100%] 1 of 1 ✔


========================================
Pipeline completed!
========================================

Execution status : SUCCESS ✓
Duration         : 29m 4s
Output directory : results

Output files:
- Final VCFs     : results/[sample_id]/final/
- TSV tables     : results/[sample_id]/tables/
- SnpEff reports : results/[sample_id]/snpeff/
- Annotations    : results/[sample_id]/annotations/
- Exomiser       : results/[sample_id]/exomiser/
- Pipeline info  : results/pipeline_info/
========================================

Completed at: 24-Sep-2025 08:21:37
Duration    : 29m 5s
CPU hours   : 2.0
Succeeded   : 8


(base) abudllah@abudllah:~/Desktop/tertiary-pipeline$ 
```

###🔒 Notes on Databases

- HGMD and OMIM require valid licenses and must not be redistributed.
- Paths to local VCFs/databases should be configured in nextflow.config or via --databases parameter.

### 👨‍💻 Author/s
- Dr. Wail Baalawi
  - Bioinformatics Department Head  
  - wbaalawi@liferaomics.com.sa
- Dr. Touati Bin Benoukraf
  - Consultanat Bioinformatician 
  - tbenoukraf@liferaomics.com.sa
- Abdullah Alnawfal
  - Bioinformatician 
  - aalnawfal@Liferaomics.com.sa
- Waleed Osman
  - Bioinformatician
  - wosman@liferaomics.com.sa


