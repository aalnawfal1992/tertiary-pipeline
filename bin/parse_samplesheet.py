#!/usr/bin/env python3

import csv
import sys
import os
from pathlib import Path

def validate_samplesheet(samplesheet_file):
    """Validate and parse the samplesheet."""
    
    required_columns = ['sample_id', 'vcf_path', 'assembly']
    optional_columns = ['hpo_terms']
    
    samples = []
    
    with open(samplesheet_file, 'r') as f:
        reader = csv.DictReader(f)
        
        # Check required columns
        missing_cols = [col for col in required_columns if col not in reader.fieldnames]
        if missing_cols:
            print(f"ERROR: Missing required columns: {missing_cols}")
            sys.exit(1)
        
        for row_num, row in enumerate(reader, start=2):
            # Validate sample_id
            if not row['sample_id']:
                print(f"ERROR: Line {row_num}: sample_id cannot be empty")
                sys.exit(1)
            
            # Validate VCF path
            vcf_path = Path(row['vcf_path'])
            if not vcf_path.exists():
                print(f"ERROR: Line {row_num}: VCF file not found: {vcf_path}")
                sys.exit(1)
            
            # Validate assembly
            if row['assembly'] not in ['19', '37', '38']:
                print(f"ERROR: Line {row_num}: assembly must be 19, 37, or 38 (got: {row['assembly']})")
                sys.exit(1)
            
            # Normalize assembly (19 -> 37)
            assembly = '37' if row['assembly'] == '19' else row['assembly']
            
            # Process HPO terms
            hpo_terms = row.get('hpo_terms', '').strip()
            if hpo_terms:
                # Validate HPO format
                hpo_list = [term.strip() for term in hpo_terms.split(',')]
                for term in hpo_list:
                    if not term.startswith('HP:') or len(term) != 10:
                        print(f"WARNING: Line {row_num}: Invalid HPO term format: {term}")
            
            samples.append({
                'sample_id': row['sample_id'],
                'vcf_path': str(vcf_path.absolute()),
                'assembly': assembly,
                'hpo_terms': hpo_terms
            })
    
    return samples

def write_validated_samplesheet(samples, output_file):
    """Write validated samplesheet."""
    
    with open(output_file, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=['sample_id', 'vcf_path', 'assembly', 'hpo_terms'])
        writer.writeheader()
        writer.writerows(samples)
    
    print(f"Validated {len(samples)} samples")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: parse_samplesheet.py <input_samplesheet> <output_samplesheet>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    samples = validate_samplesheet(input_file)
    write_validated_samplesheet(samples, output_file)
