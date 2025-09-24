#!/usr/bin/env python3
"""
Generate Exomiser YAML configuration files from samplesheet
"""

import csv
import sys
import yaml
from pathlib import Path

def generate_exomiser_config(sample_data, output_file):
    """Generate Exomiser YAML configuration for a sample."""
    
    # Convert assembly to genome build
    genome_assembly = 'hg19' if sample_data['assembly'] == '37' else 'hg38'
    
    # Parse HPO terms
    hpo_ids = []
    if sample_data.get('hpo_terms'):
        hpo_ids = [term.strip() for term in sample_data['hpo_terms'].split(',')]
    else:
        # Default HPO term if none provided
        hpo_ids = ['HP:0001156']  # Brachydactyly as generic phenotype
    
    # Build configuration dictionary
    config = {
        'analysis': {
            'genomeAssembly': genome_assembly,
            'vcf': sample_data['vcf_path'],
            'proband': sample_data['sample_id'],
            'hpoIds': hpo_ids,
            'inheritanceModes': {
                'AUTOSOMAL_DOMINANT': 0.1,
                'AUTOSOMAL_RECESSIVE_HOM_ALT': 0.1,
                'AUTOSOMAL_RECESSIVE_COMP_HET': 2.0,
                'X_RECESSIVE_HOM_ALT': 0.1,
                'X_RECESSIVE_COMP_HET': 2.0
            },
            'analysisMode': 'PASS_ONLY',
            'frequencySources': [
                'THOUSAND_GENOMES', 'TOPMED', 'UK10K',
                'ESP_AFRICAN_AMERICAN', 'ESP_EUROPEAN_AMERICAN', 'ESP_ALL',
                'EXAC_AFRICAN_INC_AFRICAN_AMERICAN', 'EXAC_AMERICAN', 
                'EXAC_EAST_ASIAN', 'EXAC_NON_FINNISH_EUROPEAN', 'EXAC_SOUTH_ASIAN',
                'GNOMAD_E_AFR', 'GNOMAD_E_AMR', 'GNOMAD_E_EAS', 
                'GNOMAD_E_NFE', 'GNOMAD_E_SAS',
                'GNOMAD_G_AFR', 'GNOMAD_G_AMR', 'GNOMAD_G_EAS', 
                'GNOMAD_G_NFE', 'GNOMAD_G_SAS'
            ],
            'pathogenicitySources': ['REVEL', 'MVP'],
            'steps': [
                {'failedVariantFilter': {}},
                {
                    'variantEffectFilter': {
                        'remove': [
                            'FIVE_PRIME_UTR_EXON_VARIANT',
                            'FIVE_PRIME_UTR_INTRON_VARIANT',
                            'THREE_PRIME_UTR_EXON_VARIANT',
                            'THREE_PRIME_UTR_INTRON_VARIANT',
                            'NON_CODING_TRANSCRIPT_EXON_VARIANT',
                            'NON_CODING_TRANSCRIPT_INTRON_VARIANT',
                            'CODING_TRANSCRIPT_INTRON_VARIANT',
                            'UPSTREAM_GENE_VARIANT',
                            'DOWNSTREAM_GENE_VARIANT',
                            'INTERGENIC_VARIANT',
                            'REGULATORY_REGION_VARIANT'
                        ]
                    }
                },
                {'frequencyFilter': {'maxFrequency': 2.0}},
                {'pathogenicityFilter': {'keepNonPathogenic': True}},
                {'inheritanceFilter': {}},
                {'omimPrioritiser': {}},
                {'hiPhivePrioritiser': {}}
            ]
        },
        'outputOptions': {
            'outputContributingVariantsOnly': False,
            'numGenes': 0,
            'outputFormats': ['HTML', 'JSON', 'TSV_GENE', 'TSV_VARIANT', 'VCF']
        }
    }
    
    # Write YAML file
    with open(output_file, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)
    
    print(f"Generated Exomiser config: {output_file}")
    return config

def process_samplesheet(samplesheet_file, output_dir):
    """Process samplesheet and generate Exomiser configs for all samples."""
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    configs_generated = []
    
    with open(samplesheet_file, 'r') as f:
        reader = csv.DictReader(f)
        
        for row in reader:
            # Generate config filename
            config_file = output_dir / f"{row['sample_id']}_exomiser.yml"
            
            # Generate configuration
            config = generate_exomiser_config(row, config_file)
            configs_generated.append({
                'sample': row['sample_id'],
                'config_file': str(config_file),
                'hpo_terms': config['analysis']['hpoIds']
            })
    
    # Write summary
    summary_file = output_dir / 'exomiser_configs_summary.txt'
    with open(summary_file, 'w') as f:
        f.write(f"Generated {len(configs_generated)} Exomiser configurations\n")
        f.write("=" * 50 + "\n")
        for cfg in configs_generated:
            f.write(f"Sample: {cfg['sample']}\n")
            f.write(f"  Config: {cfg['config_file']}\n")
            f.write(f"  HPO terms: {', '.join(cfg['hpo_terms'])}\n")
            f.write("-" * 30 + "\n")
    
    print(f"\nSummary written to: {summary_file}")
    print(f"Generated {len(configs_generated)} Exomiser configuration files")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: generate_exomiser_yaml.py <samplesheet> <output_dir>")
        print("\nThis script generates Exomiser YAML configuration files from a samplesheet")
        sys.exit(1)
    
    samplesheet = sys.argv[1]
    output_dir = sys.argv[2]
    
    if not Path(samplesheet).exists():
        print(f"ERROR: Samplesheet not found: {samplesheet}")
        sys.exit(1)
    
    process_samplesheet(samplesheet, output_dir)