rule all:
    input:
        "variants.vcf"

# copy data from /home/ctbrown/data/ggg201b
rule copy_data:
    output: "SRR2584857_1.fastq.gz"
    shell:
        "ln -s /home/ctbrown/data/ggg201b/SRR2584857_1.fastq.gz ."

rule download_genome:
    output:
        "ecoli-rel606.fa.gz"
    shell:
        "wget https://osf.io/8sm92/download -O ecoli-rel606.fa.gz"

rule uncompress_genome:
    input: "ecoli-rel606.fa.gz"
    output: "ecoli-rel606.fa"
    shell:
        "gunzip ecoli-rel606.fa.gz"

rule index_genome_bwa:
    input: "ecoli-rel606.fa"
    output:
        "ecoli-rel606.fa.amb",
        "ecoli-rel606.fa.ann",
        "ecoli-rel606.fa.bwt",
        "ecoli-rel606.fa.pac",
        "ecoli-rel606.fa.sa"
    shell:
        "bwa index ecoli-rel606.fa"

rule map_reads:
    input:
        "ecoli-rel606.fa.amb",
        "{sample}.fastq.gz"
    output:
        "{sample}.sam"
    shell:
        "bwa mem -t 4 ecoli-rel606.fa {wildcards.sample}.fastq.gz > {wildcards.sample}.sam"

rule index_genome_samtools:
    input:
        "ecoli-rel606.fa"
    output:
        "ecoli-rel606.fa.fai"
    shell:
        "samtools faidx ecoli-rel606.fa"

rule samtools_import:
    input:
        "ecoli-rel606.fa.fai", "{sample5}.sam"
    output:
        "{sample5}.bam"
    shell:
        "samtools import ecoli-rel606.fa.fai {wildcards.sample5}.sam {wildcards.sample5}.bam"

rule samtools_sort:
    input:
        "SRR2584857.bam"
    output:
        "SRR2584857.sorted.bam"
    shell:
        "samtools sort SRR2584857.bam -o SRR2584857.sorted.bam"

rule samtools_index_sorted:
    input: "SRR2584857.sorted.bam"
    output: "SRR2584857.sorted.bam.bai"
    shell: "samtools index SRR2584857.sorted.bam"

rule samtools_mpileup:
    input: "ecoli-rel606.fa", "SRR2584857.sorted.bam.bai"
    output: "variants.raw.bcf"
    shell:
        """samtools mpileup -u -t DP -f ecoli-rel606.fa SRR2584857.sorted.bam | \
    bcftools call -mv -Ob -o - > variants.raw.bcf"""

rule make_vcf:
    input: "variants.raw.bcf"
    output: "variants.vcf"
    shell: "bcftools view variants.raw.bcf > variants.vcf"

## samtools tview -p ecoli:4202391 SRR2584857.sorted.bam ecoli-rel606.fa
