# SARS-CoV-2_annot
Collection of Perl script for the alignment of SARS-CoV-2 genomes and the functional annotation of genetic variants
## Prerequisites and usage

This repository contains a collection of simple Perl scripts that can be used to align complete assemblies of SARS-CoV-2 genomes wih the reference genomic sequence, to obtain a list of polymorphic positions and to **annotate** genetic variants according to the method described in *Chiara et al 2020*  to be published (hopefully) 
The manuscript is currently submitted and undergoing peer review.

This software package is composed of 3 very simple scripts and a collection of files with functional annotation data. The only requirement is that you have an up to date installation (see below) of the Mummer package in your system and a copy of the reference genomic sequence, in fasta format. All the files (scripts, genomic sequences and accessory files) should be placed in the same folder. If you do not feel comfortable in installing/running these utilities from the command line, you can find a Galaxy running the software at http://90.147.102.237/galaxy , or download a dockerized version of the Galaxy, with all the tools at XXX.

Please follow this link https://sourceforge.net/projects/mummer/files/ for detailed instruction on how to install and run Mummer.

The reference genome of SARS-CoV-2 can be obtained from:
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/GCF_009858895.2_ASM985889v3/GCF_009858895.2_ASM985889v3_genomic.fna.gz
on a unix system you can download this file, by

`wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/GCF_009858895.2_ASM985889v3/GCF_009858895.2_ASM985889v3_genomic.fna.gz`

followed by

`gunzip GCF_009858895.2_ASM985889v3_genomic.fna.gz`

Please notice that however the *align.pl* utility is going to download the file for you, if a copy of the reference genome is not found in the current folder. However, since the "wget" command is required this is supposed to work only unix and unix alike systems.

Should you find any of this software useful for your work, please cite:
>**Chiara M, Horner DS, Gissi C, Pesole G. Comparative genomics provides an operational classification system and reveals early emergence and biased spatio-temporal distribution of SARS-CoV-2 bioRxiv 2020.06.26.172924; doi: https://doi.org/10.1101/2020.06.26.172924**
and
>**Other paper**

Should you find any issue with the software, please contact me at matteo.chiara@unimi.it, or here on github

## Align to the reference genome

The helper script *align.pl* can be used to align a collection of genomic sequences to the reference assembly of SARS-CoV-2 and obtain a list of polymorphic positions. The script automates all the required steps. 

The only prerequisite is that all the genomic sequences that should be aligned to the reference **MUST** be in the **same folder** from which the program is executed. The program is very simple, and can detect only files with a **.fasta** extensions. Please name your files accordingly. 

Please see above for how to obtain the reference genome sequence file. This file also needs to be in the same folder from which the program is executed (and yes **the same** where you have all the files). If the reference genome file is missing, *aling.pl* will try to download it from Genbank. Although this is supposed to work only for unix and unix alike systems (the *wget* command is required)

Once you have everything in place, you can simply run:
`perl align.pl`

For every genome fasta file you will obtain a file with the extension .snps which will contain all the polymorphic positions identified by nucmer

## Consolidate variants into a single pseudo-vcf file

Prior to variant annotation, mummer's output files are converted in a pseudo vcf format. This step is required also to consolidate all variant calls in a single file. This file will constitute the input for variant annotation.  Please notice that this operation is required even if/when a single genome is analysed.

The *consolidate.pl* program, as available from this repository, is used to merge a collection of mummer output files and to convert them in the appropriate format for variant annotation. To execute this operation all you need to do is to issue the following command, from the *same* directory from where the *align.pl* program was executed:

`perl consolidate.pl > <consolidated_variant_calls>`

Please notice that *consolidate.pl* will print its output directly to the standard output. The *>* symbol is required to capture the output and redirect it to a file. In the example the name of the output file is *consolidated_variant_calls* as indicated by the angular parentheses (<>).  

## Functional annotation

The *annotate.pl* utility is used to perform functional annotation of SARS-CoV-2 variants. The program can be executed very easily, by running:
`perl annotate.pl consolidated_variant_calls > <funct_annot_output_file.csv>`

Similar to *consolidate.pl* the output is printed directly to your screen (standard output). Again, to save everything into a file you need to redirect (*>* symbol). My personal suggestion is to add a *.csv* or a *.tsv* extension to the name of the output file. So that it can be opened directly by a spreadsheet editor software, like for example MS excel or OpenOffice Calc. If/when the docker or Galaxy version of this software are used, the output can be visualized directly in your browser.

The output consists in a simple table, delineated by <tab> (tabulations) and formatted as follows:
Genomic position | Ref allele| Alt allele | Allele frequency| Funct Elem annot | Epitopes annot | Selection annot | MFE annot | 
---------------- |-----------|------------|-----------------|------------------|----------------|-----------------|-----------|
376|G|T|nsp1:c.111G>T,p.E37D,missense;orf1ab:c.111G>T,p.E37D,missense;||FGDSVEEVL,1,HLA-C\*08:01|fel:true;meme:true;kind:positive|NA
29742|G|T|3'UTR:nc.G68T,NA,NA,NA;sl5:nc.G15T,NA,NA,NA;|0.735|NA|NA|mfe:-5.6;-4.76;-10.93;

Annotation of functional genomic elements, consists of 4 fields, separated by commas (**,**):
1. name of the element, followed by ":"
2. relative position (c.= coding, nc.=non coding)
3. amino acid change (NA if a non coding element)
4. predicted effect on protein (NA if a non coding element)

When a variant is overlapped by more than one element, multiple annotations are reported, separated by semicolumns (**;**)

Annotation of epitopes is according to XX et al. The sequence of the epitope/epitopes is reported followed by the number and by the names of the HLAs that are predicted to recognize the epitope.  Multiple annotations are separated by semicolumns (**;**).  For example in *FGDSVEEVL,1,HLA-C\*08:01*, **FGDSVEEVL** is the sequence of the predicted epitope/epitopes, **1** and **HLA-C\*08:01** indicate that the sequence is recognized by just 1 HLA, that is **HLA-C\*08:01**.

Annotation of sites under selection is very simple: **fel:** is used to indicate if the site is under selection according to fel. Possible values are *true* or *false*. **meme** is the equivalent, but for the meme method. The **kind:** field indicates the type of selection: *positive* or *negative*.

The MFE annot column reports **predicted changes** in MFE (minimum free energy) for variants associated with secondary structure elements. Please notice that this annotation does not report the predicted MFE, but the **difference** between the MFE of the element based on the reference genome sequence, with the MFE calculated on the alternative sequence. Negative values indicate a descrease in MFE (a more stable structure). Positive values are suggestive of a less stable structure (increase in MFE). Three values are reported, representing respectively MFE of: *optimal secondary structure*, *the thermodynamic ensemble* and *the centroid secondary structure* .  Obviusly there is no absolute cut-off for interpreting these results, however high shifts (>1 or <-1) in MFE might be suggestive of functional implications.

## Functional annotation: Important!

Please notice, that to work properly *annotate.pl* needs to have access (read) several annotation files which provide the different types of functional annotations. If these files are not available, the program will exit with an error, complaining that one or more of the files are missing.
These files that are **strictly required** and can be downloaded from the current github repository. The repository itself is updated on a 2 week basis. So it is **highly advised** that the latest version of the files should be downloaded **before** you perform functional annotation.
The Galaxy and docker version of this software are updated automatically. All the files need to be (and normally are) in the **same folder** from which annotate.pl is executed.

The annotation files, all in simple text format include:
1. *genetic_code* -> 3 column file with the standard genetic code
2. *GCA_009858895.3_ASM985889v3_genomic.fna* -> the reference SARS-CoV-2 genome assembly sequence
3. *annot_table.pl* -> a 4 column tabular file with genomic coordinates of functional genomic elements
4. *af_data_new.csv* -> tabular file with allele frequency data
5. *MFE_annot.csv* -> tabular file with Mininum Free Energy predictions for all the possible Single Nucleotide substitutions in secondary structure elements
6. *epitopes_annot.csv* -> tabular file with annotation of predicted epitopes
7. *hyphy.csv* -> tabular file with aa residues under selection according to meme/fel

Please see below for a brief guide that will help you to define additional functional elements in *annot_table.pl*

## Functional annotation: adding functional elements!

Functional genomic elements in the genome of SARS-CoV-2 are specified by a four columns tabular format file called annot_table.pl. This file can be used to specify additional functional elements and/or use a personalized annotation. The file has a very simple format: for every element, the first two columns specify the start and end coordinate on the genome. The third column defines the functional class. At the moment 2 different classes are supported: protein coding sequence (CDS) and non-coding (nc). The fourth column is optional and contains an additional comment/name for the functional elements.

## For impatient people

To do all of the above: 
1. put fasta files of genome sequences in one folder. 1 sequence per file. all the files must have the *.fasta* extension
2. download this repo
3. run `perl align.pl`
4. run `perl consolidate.pl > consolidated_variant_calls`
5. run `perl annotate.pl consolidated_variant_calls > funct_annot_output_file`
6. open the output file, and read the annotations
