home_dir = "/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/Snakemake_pipeline2/git_metagenome_snakemake/1"
run = "S4_run13"
#ruleorder: bclconvert > fastqc > bowtie2_align > trimmomatic_trim > metaphlan_profile > parse_metaphlan
import pandas as pd

sample_sheet =  f"{home_dir}/sample_sheet_1.csv"
df = pd.read_csv(sample_sheet)

samples = df["Sample_ID"].tolist()


threads = 40
index_dir = "/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/Homo_sapiens_hg37_and_human_contamination_Bowtie2_v0.1/hg37dec_v0.1"
bowtie2db_dir = "/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/mpa_vJun23_CHOCOPhlAnSGB_202307" 
# Define the rule for generating the `all` target
rule all:
    input:
        expand(f"{home_dir}/{run}/raw_fastq/{run}/fastqc/{run}/{{sample}}", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Aligned/{{sample}}_HR.fastq.1.gz", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Aligned/{{sample}}_HR.fastq.2.gz", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R1_paired_trim.fastq.gz", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R1_unpaired_trim.fastq.gz", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R2_paired_trim.fastq.gz", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R2_unpaired_trim.fastq.gz", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_trimmomatic_summary.txt", sample=samples),
        expand(f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_trimmomatic_log.txt", sample=samples),
        expand(f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_bowtie_out/{{sample}}.bowtie2.bz2", sample=samples),
        expand(f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results/{{sample}}_profiled_mpa4.txt", sample=samples),
        expand(f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results_parsed/{{sample}}_profiled_mpa4.xlsx", sample=samples),
        expand(f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results_parsed/{{sample}}_Phylum_profiled_mpa4.xlsx", sample=samples),
        expand(f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results_parsed/{{sample}}_Species_profiled_mpa4.xlsx", sample=samples)
'''rule bclconvert:
    input:
        bcl = "/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/S4_run13/240901_A00804_0329_BHV2V2DSXC",
        sample_sheet = "/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/S4_run12/240901_A00804_0329_BHV2V2DSXC/S4_run12_sample_sheet.csv"
    output:
        fq = directory(f"{home_dir}/{run}/raw_fastq/{run}")
    log:
        f"{home_dir}/{run}/logs/bclconvert.log"
    priority: 1
    benchmark:
        f"{home_dir}/{run}/benchmark/bclconvert.tsv"
    message: "Executing bclconvert"
    shell:
        """
        bcl-convert --bcl-input-directory {input.bcl} --output-directory {output.fq} --no-lane-splitting true --sample-sheet {input.sample_sheet} --force
        """
'''
rule fastqc:
    input:
        fastq1 = f"/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/S4_run13/fastq/{{sample}}_R1_001.fastq.gz",
        fastq2 = f"/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/S4_run13/fastq/{{sample}}_R2_001.fastq.gz"
    output:
        outdir = directory(f"{home_dir}/{run}/raw_fastq/{run}/fastqc/{run}/{{sample}}")
    log:
        log = f"{home_dir}/{run}/logs/{{sample}}.fastqc.log"
    benchmark:
        f"{home_dir}/{run}/benchmark/{{sample}}_fastqc.tsv"
    message: "Executing fastqc on sample {wildcards.sample}."
    shell:
        """
        mkdir {home_dir}/{run}/raw_fastq/{run}/fastqc/{run}/{wildcards.sample}
        fastqc --outdir {output.outdir} {input.fastq1} {input.fastq2} > {log}
        """
rule bowtie2_align:
    input:
        fastq1 = f"/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/S4_run13/fastq/{{sample}}_R1_001.fastq.gz",
        fastq2 = f"/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/S4_run13/fastq/{{sample}}_R2_001.fastq.gz"
    output:
        unaligned1 = f"{home_dir}/{run}/Processed_fastq/{run}/Aligned/{{sample}}_HR.fastq.1.gz",
        unaligned2 = f"{home_dir}/{run}/Processed_fastq/{run}/Aligned/{{sample}}_HR.fastq.2.gz"
    params:
        index = index_dir,
        threads = threads,
        unaligned_dir = f"{home_dir}/{run}/Processed_fastq/{run}/Aligned"
    log:
        f"{home_dir}/{run}/logs/{{sample}}.bowtie2.log"
    benchmark:
        f"{home_dir}/{run}/benchmark/{{sample}}_bowtie2.tsv"
    shell:
        """
        bowtie2 -x {params.index} -1 {input.fastq1} -2 {input.fastq2} \
        --un-conc-gz {params.unaligned_dir}/{wildcards.sample}_HR.fastq.gz \
        --threads {params.threads} -q --time 2> {log}
        """

# Define the rule for trimming reads using Trimmomatic
rule trimmomatic_trim:
    input:
        fastq1 = f"{home_dir}/{run}/Processed_fastq/{run}/Aligned/{{sample}}_HR.fastq.1.gz",
        fastq2 = f"{home_dir}/{run}/Processed_fastq/{run}/Aligned/{{sample}}_HR.fastq.2.gz"
    output:
        paired1 = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R1_paired_trim.fastq.gz",
        unpaired1 = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R1_unpaired_trim.fastq.gz",
        paired2 = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R2_paired_trim.fastq.gz",
        unpaired2 = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R2_unpaired_trim.fastq.gz",
        summary = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_trimmomatic_summary.txt",
        trimlog = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_trimmomatic_log.txt"
    benchmark:
        f"{home_dir}/{run}/benchmark/{{sample}}_trimmomatic.tsv"
    params:
        threads = 40
    shell:
        """
        trimmomatic PE -phred33 {input.fastq1} {input.fastq2} \
        {output.paired1} {output.unpaired1} \
        {output.paired2} {output.unpaired2} \
        LEADING:30 TRAILING:30 SLIDINGWINDOW:4:20 MINLEN:70 \
        -threads {params.threads} \
        -summary {output.summary} \
        -trimlog {output.trimlog}
        """

rule metaphlan_profile:
    input:
        paired1 = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R1_paired_trim.fastq.gz",
        paired2 = f"{home_dir}/{run}/Processed_fastq/{run}/Trimmed/{{sample}}_R2_paired_trim.fastq.gz",
    output:
        bowtie2out = f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_bowtie_out/{{sample}}.bowtie2.bz2",
        profile = f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results/{{sample}}_profiled_mpa4.txt",
    params:
        bowtie2db = bowtie2db_dir,
        threads = 40
    log:
        f"{home_dir}/{run}/logs/{{sample}}.metaphlan.log"
    benchmark:
        f"{home_dir}/{run}/benchmark/{{sample}}_metaphlan.tsv"
    shell:
        """
        metaphlan {input.paired1},{input.paired2} \
        --input_type fastq \
        --add_viruses \
        --sample_id {wildcards.sample}\
        --bowtie2out {output.bowtie2out} \
        --nproc {params.threads} \
        -o {output.profile} \
        --bowtie2db {params.bowtie2db} \
        > {log} 2>&1
        """

rule parse_metaphlan:
    input:
        profile = f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results/{{sample}}_profiled_mpa4.txt",
    output:
        out= f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results_parsed/{{sample}}_profiled_mpa4.xlsx",
        out1 = f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results_parsed/{{sample}}_Phylum_profiled_mpa4.xlsx",
        out2 = f"{home_dir}/{run}/mpa4_profiles/{run}/mpa4_results_parsed/{{sample}}_Species_profiled_mpa4.xlsx",
    benchmark:
        f"{home_dir}/{run}/benchmark/{{sample}}_parse_metaphlan.tsv"
    script:
        "/lustre/rohan.b/Gut_Mcrobiome_sequencing_runs/Snakemake_pipeline2/git_metagenome_snakemake/parse_metaphlan.py"
