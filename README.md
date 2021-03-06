# Toil MarginPhase #

This is a Toil workflow designed to run MarginPhase by chunking an input BAM, running MarginPhase on each chunk in parallel, and then merging the output.

## Using Toil MarginPhase ##

### Docker Initialization ###

The Toil script needs two docker images to run: marginPhase (the core of the workflow), and cPecan (for realignment preprocessing)

#### Quick Start ####

```
cd docker
ls | xargs -n1 -I{} bash -c "cd {} &amp;&amp; make"
```

#### Under the Hood ####

The images are tagged with the current git version of the toil-marginPhase repository (so the state of the docker file can be determined through git history).  As such, it is recommended that you only publish docker images which were created from an unmodified (or fully committed) repository.

To gather memory statistics, there are custom entrypoints which store the executable's output in a log file as well as resource usage debugging information.  These require that the current working directory is mounted onto '/data'

### Toil ###

#### Requirements ###

* Python2.7
    * pip
    * virtualenv
* Docker

#### Quick Start ####

```
# environment prep
virtualenv -p python2 venv
. venv/bin/activate
pip install -e .

# toil prep
toil-marginphase generate
vim manifest-toil-marginphase.tsv
vim config-toil-marginphase.yaml

# run toil-marginphase
toil-marginphase run --workDir /your/work/directory /your/jobstore/directory
# ..or:
time toil-marginphase run --workDir /your/work/directory /your/jobstore/directory 2>&amp;1 | tee -a toil-marginPhase.log
```

#### Configuration ###

The default config and manifest file (created by running 'toil-marginphase generate') need to be modified to fit the marginPhase run.  The files generated give descriptions of the values and requirements.

Each sample needs a unique UUID and sample location (and must be from a single contig).  Each sample also needs a reference FASTA, a marginPhase parameters file, and must have the contig name specified.  If all samples in a run share any of these, default values can be specified in the configuration (this is optional).  If a reference FASTA, params file, and/or contig name are specified in the manifest, that value will be used during the run.

#### Output ####

The output for a sample is compressed in a tarball.  This tarball contains all output from each chunk's marginPhase run, two SAM files and a VCF for each merged chunk, and a single VCF created by merging the output from all chunks.

The output from each chunk's marginPhase run includes all standard output (notably the two haplotype SAM files and the VCF), the log of the run's output, and the input BAM.

The output tarball is named $UUID.tar.gz, the marginPhase output is named $UUID.$CHUNK_IDX.out.* (input BAM is named $UUID.$CHUNK_IDX.in.bam), the merged output is named $UUID.merged.$MERGE_IDX.*, and the VCF generated by merging all output VCFs is named $UUID.merged.full.vcf.

## Chunking Algorithm ##

### Introduction ###

The idea here is that it is prohibitively memory-intensive to run marginPhase on chromosome-scale BAMs.  So we break apart the BAMs into smaller (manageable) chunks and run marginPhase on these in parallel.  Then the output of these is stitched back together to get an approximation of the true result.

This process requires these parameters:
1. CHUNK_SIZE: Size of the chunk
1. CHUNK_MARGIN: The distance on each side of the chunks boundaries to include. This is for forcing overlap, and is used in stitching chunks back together
1. MERGE_RATIO: This value (.5, 1] is used to determine whether two adjacent chunks should be merged

### Dividing into Chunks ###

1. Get the range of reference positions covered by the reads.
    * To find this we inspect the position of the first and last read in the sorted BAM file
    * Def: START_POS, END_POS
1. Find chunk boundaries.
    * Def: CHUNKS = []
    * CHUNK_START = START_POS
    * CHUNK_END = CHUNK_START + CHUNK_SIZE
    * CHUNK = (CHUNK_START - CHUNK_MARGIN, CHUNK_END + CHUNK_MARGIN)
    * CHUNKS.append(CHUNK)
    * CHUNK_START = CHUNK_END
    * Iterate until CHUNK_END > END_POS
1. Divide BAM into chunks
    * We use a Samtools docker image for this.
    * This means that all reads which cover the ends of the chunk (with the margins for overlap) are included in each chunk.  So there would still be read overlap across adjacent chunks if CHUNK_MARGIN was 0.
    * Any chunk which has no reads is discarded

Once chunks have been divided, marginPhase is run on each chunk.  The output (of significance) of this is a bipartition of reads into two SAM files (Haplotype1 and Haplotype2) and a phased VCF where the left phase refers to calls made in Haplotype1 and the right phase refers to calls from Haplotype2.

### Merging Chunks ###

TODO

For now, the code is self-documenting.
