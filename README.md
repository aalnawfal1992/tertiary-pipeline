tertaryPipeline/
├── main.nf
├── nextflow.config
├── README.md
├── setup.sh
├── requirements.txt
├── samplesheet.csv
├── bin/
│   ├── parse_samplesheet.py
│   ├── extract_scores.py
│   ├── generate_report.py
│   ├── prepare_exomiser_config.py
│   └── annotate_omim.py
├── conf/
│   ├── base.config
│   ├── compute.config
│   ├── modules.config
│   ├── resources_grch37.config
│   └── resources_grch38.config
├── modules/
│   ├── snpeff_annotate.nf
│   ├── snpsift_clinvar.nf
│   ├── snpsift_hgmd.nf
│   ├── snpsift_dbnsfp.nf
│   ├── snpsift_omim.nf
│   ├── exomiser_run.nf
│   ├── parse_samplesheet.nf
│   ├── prepare_exomiser.nf
│   ├── extract_scores.nf
│   └── generate_report.nf
├── workflows/
│   ├── annotation.nf
│   └── exomiser_analysis.nf
├── tools/
│   └── snpEff/
└── databases/
    ├── clinvar/
    ├── hgmd/
    ├── dbnsfp/
    └── omim/


nextflow run main.nf     --samplesheet samplesheet.csv     --outdir results     --skip_hgmd     --skip_dbnsfp     --skip_omim     -profile docker 