# gut_metagenome_snakemake
This is a git repo for the human gut microbiome illumina seq data analysis

The pipeline takes the fastq.gz files as input and gives the microbial profile of the sample's gut.

To run the pipeline first install the conda environment using the gut_snakemake_env.yml file.

Then create a sample sheet. The sample sheet should have at least 1 column with sample names.

If you want to run the pipeline in HPC system use the given bash script to run the pipeline.

If you want to run it on aws, then first create s3 bucket with all your sample fastq files and snakefile. Then connect the s3 bucket to fsx file system for better performance. After this create a EC2 instance based on the requirement. Connect the fsx with EC2 instance. install the conda environment and run the pipeline directly using command.


