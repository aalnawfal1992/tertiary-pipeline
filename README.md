cat > README.md <<'EOF'
# Clinical VCF Annotation Pipeline

A **Nextflow DSL2 pipeline** for clinical variant annotation.  
This project automates annotation of VCF files using multiple public and licensed databases, producing both annotated VCFs and tabular reports.

---

## 🚀 Features

- **Modular DSL2 workflow** with reusable annotation modules  
- **Supported annotations**:
  - [SnpEff](https://pcingola.github.io/SnpEff/) (functional effects)  
  - [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/)  
  - [dbNSFP](https://sites.google.com/site/jpopgen/dbNSFP)  
  - HGMD (*licensed, not included*)  
  - OMIM (*licensed, not included*)  
- **Sample management** via CSV (`samplesheet.csv`)  
- **Python helpers** for parsing and reporting  
- **Configurable resources** (see `conf/`)  
- **Outputs**: annotated VCFs and TSV summaries  

---

## 📋 Quick Start

### Prerequisites
- Nextflow ≥ 25.04  
- Java 11+  
- Docker or Singularity/Apptainer  
- Databases: ClinVar, dbNSFP, SnpEff, HGMD\*, OMIM\*  
  (\* licensed databases must be obtained separately)

### Run
```bash
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --outdir results \
  -profile docker
````
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


###🔒 Notes on Databases

- HGMD and OMIM require valid licenses and must not be redistributed.
- Paths to local VCFs/databases should be configured in nextflow.config or via --databases parameter.

### 👨‍💻 Author/s
- Abdullah Al-Nawfal
- Dr. Touati 