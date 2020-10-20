# SARS-CoV-2_annot
Collection of Perl script for the alignment of SARS-CoV-2 genomes and the functional annotation of genetic variants
## Prerequisites and usage

This repository contains a collection of simple Perl scripts that can be used to align complete assemblies of SARS-CoV-2 genomes wih the reference genomic sequence, to obtain a list of polymorphic positions and to **annotate** genetic variants according to the method described in *Chiara et al 2020*  to be published soon (hopefully). The manuscript is currently submitted and undergoing peer review.

This software package is composed of 2 very simple scripts and a collection of files with functional annotation data. The only requirement is that you have an up to date installation (see below) of the Mummer package in your system and a copy of the reference genomic sequence, in fasta format. All the files (scripts, genomic sequences and accessory files) should be placed in the same folder. If you do not feel comfortable in installing/running these utilities from the command line, you can find a Galaxy running the software at http://corgat.cloud.ba.infn.it/galaxy , or download a dockerized version of the Galaxy, with all the tools at https://hub.docker.com/r/pmandreoli/galaxy_corgat.

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

>**Chiara M, Zambelli F, Tangaro MA, Mandreoli P, Horner DS, Pesole G. CorGAT: a tool for the functional annotation of SARS-CoV-2 genomes. Under peer review**

Should you find any issue with the software, please contact me at matteo.chiara@unimi.it, or here on github

## Align to the reference genome

The helper script *align.pl* can be used to align a collection of genomic sequences to the reference assembly of SARS-CoV-2 and obtain a list of polymorphic positions. The script automates all the required steps. align.pl currently allows 3 different distinct methods to provide input files/sequences:
* Through a multifasta file: **option --multi**
* Through a file containing a list of file names: **option --filelists**
* By specifying a "suffix" that is common to all the names of the files that should be analyses: **option --suffix**

All input files **MUST** be in the **same folder** from which the program is executed. A temporary directory will be created to store all the intermediate files and the alingment results for every file. The name of this temporary directory can be specified using the **--tmpdir option**. Please notice that this temporary directory, normally, will be deleted after the execution of align.pl. The **--clean option**, can be used to alter this behavior. If set to **F=FALSE** the temporary directory will not be deleted.

Finally the name of the output file can be specified by using the **--out option**. This defaults to **<<ALIGN_out.tsv>>**. 

Please see above for how to obtain the reference genome sequence file. This file also needs to be in the same folder from which the program is executed (and yes **the same** where you have all the files). If the reference genome file is missing, *aling.pl* will try to download it from Genbank. Although this is supposed to work only for unix and unix alike systems (the *wget* command is required)

Once you have everything in place, you can simply run:
>* `perl align.pl --multi <multifasta>` to align all the genomes contained in a multifasta file or
>* `perl align.pl --suffix <fasta>` to align all the .fasta files contained in the current folder or
>* `perl align.pl --filelist <list>` to align all the files specified in a list of file names.One file per line. Again, all files need to be in the current folder

For every genome fasta file you will obtain a file with the extension .snps which will contain all the polymorphic positions identified by nucmer. These files will be stored in the temporary directory, as specified by the --tmpdir option (default align.tmp). If the --clean option is set to **T (TRUE) however, this directory will be removed** after the execution of the program.

The final output consists in a simple tabular file (default name **ALIGN_out.tsv**) that lists genetic variants on the rows, and reports their presence (1) or absence (0) in the different genomes included in your analysis in the columns. 

The apollo.fa file in the current repository provides an example of a valid multifasta. Similarly, the file called lfile is a valid example of a list file. Both gn.fa and gn1.fa, the file included in the list, are incorporated in the CorGAT Github repository. The repository also contains a couple of files with the extension .fasta: g1.fasta and g2.fasta . These can be used to test the "--suffix" input mode. 
To check if everything works, just run:
>`perl align.pl`

The help message, should be self-explanatory. You can try all the 3 different commands under the EXAMPLE section to test align.pl
  

## Functional annotation

The *annotate.pl* utility is used to perform functional annotation of SARS-CoV-2 variants. The program can be executed very easily, by running:
>`perl annotate.pl --in inputFile`

This script is very simple to use. Only 3 parameters are accepted in input: 
* **--in** to specify the input file;
* **--out** to set the name of the output file; 
* and **--conf** to provide a configuration file. 

The configuration file, is nothing but a simple table that contains the name of the files that should be used to provide different types of functional annotations. A valid example of a configuration file is provided by **corgat.conf**  ad included in the current repo.(See below)

**Configuration file**
The configuration file, is nothing but a simple table, which provides the name of several files that are used for the functional annotations of the genome. Each of this file is associated with a keyword (first column), to which the name of the file that should be used follows (second column). In particular:
* genetic -> specifies the name of the file with the genetic code
* genome  -> the name of the file with the reference genome sequence
* annot   -> a table, with the coordinates of functional genomic elements (see below)
* hyphy   -> the file used to provide annotation of variants under selection according to hyphy
* AF      -> the file with allele frequency data
* EPI     -> the files with annotations of predicted epitopes

Since the number of publicly available genome sequences is constantly increased over times, some of these files are updated on a monthly basis. In particular the **hyphy** and **AF** files. The corgat.conf file as provided in this repo, is set to use the most up to date version of these files, each denoted by the **current.csv** suffix. Older versions of each file are stored in the **hyphy** and **AF** folders respectively. Should you need to use an older version of these files for any specific reason, you can simply modify your copy of corgat.conf accordingly. Average users however, should not need to modify this file. 


**Output**

The output consists in a simple table, delineated by <tab> (tabulations) and formatted as follows:
Genomic position | Ref allele| Alt allele | Funct Elem annot| Allele Frequency | Epitopes annot | Selection annot | MFE annot | 
---------------- |-----------|------------|-----------------|------------------|----------------|-----------------|-----------|
376|G|T|nsp1:c.111G>T,p.E37D,missense;orf1ab:c.111G>T,p.E37D,missense;|0.166|FGDSVEEVL,1,HLA-C\*08:01|fel:true;meme:true;kind:positive|NA
29742|G|T|3'UTR:nc.G68T,NA,NA,NA;sl5:nc.G15T,NA,NA,NA;|0.735|NA|NA|mfe:-5.6;-4.76;-10.93;

So that it can be opened directly by a spreadsheet editor software, like for example MS excel or OpenOffice Calc. If/when the docker or Galaxy version of this software are used, the output can be visualized directly in your browser.

Annotation of functional genomic elements, consists of 4 fields, separated by commas (**,**):
1. name of the element, followed by ":"
2. relative position (c.= coding, nc.=non coding)
3. amino acid change (NA if a non coding element)
4. predicted effect on protein (NA if a non coding element)

When a variant is overlapped by more than one element, multiple annotations are reported, separated by semicolumns (**;**)

Annotation of epitopes is according to Kiyotani et al 2020. The sequence of the epitope/epitopes is reported followed by the number and by the names of the HLAs that are predicted to recognize the epitope.  Multiple annotations are separated by semicolumns (**;**).  For example in *FGDSVEEVL,1,HLA-C\*08:01*, **FGDSVEEVL** is the sequence of the predicted epitope/epitopes, **1** and **HLA-C\*08:01** indicate that the sequence is recognized by just 1 HLA, that is **HLA-C\*08:01**.

Annotation of sites under selection is very simple: **fel:** is used to indicate if the site is under selection according to fel. Possible values are *true* or *false*. **meme** is the equivalent, but for the meme method. The **kind:** field indicates the type of selection: *positive* or *negative*.

The MFE annot column reports **predicted changes** in MFE (minimum free energy) for variants associated with secondary structure elements. Please notice that this annotation does not report the predicted MFE, but the **difference** between the MFE of the element based on the reference genome sequence, with the MFE calculated on the alternative sequence. Negative values indicate a descrease in MFE (a more stable structure). Positive values are suggestive of a less stable structure (increase in MFE). Three values are reported, representing respectively MFE of: *optimal secondary structure*, *the thermodynamic ensemble* and *the centroid secondary structure* .  Obviusly there is no absolute cut-off for interpreting these results, however high shifts (>1 or <-1) in MFE might be suggestive of functional implications.

## Functional annotation: Important!

Please notice, that to work properly *annotate.pl* needs to have access (read) several annotation files which provide the different types of functional annotations. If these files are not available, the program will exit with an error, complaining that one or more of the files are missing.
These files that are **strictly required** and can be downloaded from the current github repository. The repository itself is updated on a monthly basis. So it is **highly advised** that the latest version of the files should be downloaded **before** you perform functional annotation.
In the Galaxy and docker version, these files are updated automatically. All the files need to be (and normally are) in the **same folder** from which annotate.pl is executed.

The annotation files, all in simple text format include:
1. *genetic_code* -> 3 column file with the standard genetic code
2. *GCA_009858895.3_ASM985889v3_genomic.fna* -> the reference SARS-CoV-2 genome assembly sequence
3. *annot_table.pl* -> a 4 column tabular file with genomic coordinates of functional genomic elements
4. *af_data_current.csv* -> tabular file with allele frequency data
5. *MFE_annot.csv* -> tabular file with Mininum Free Energy predictions for all the possible Single Nucleotide substitutions in secondary structure elements
6. *epitopes_annot.csv* -> tabular file with annotation of predicted epitopes
7. *hyphy_current.csv* -> tabular file with aa residues under selection according to meme/fel

Please see below for a brief guide that will help you to define additional functional elements in *annot_table.pl*

## Functional annotation: adding functional elements!

Functional genomic elements in the genome of SARS-CoV-2 are specified by a four columns tabular format file called annot_table.pl. This file can be used to specify additional functional elements and/or use a personalized annotation. The file has a very simple format: for every element, the first two columns specify the start and end coordinate on the genome. The third column defines the functional class. At the moment 2 different classes are supported: protein coding sequence (CDS) and non-coding (nc). The fourth column is optional and contains an additional comment/name for the functional elements.
Currently the Galaxy/dockerized versions do not allow the specification of additional annotations.

## For impatient people

To do all of the above: 
1. put any valid input file for CorGAT (multifasta in the example) in the current folder. 
2. download this repo
3. run `perl align.pl --multi <multifasta>`
5. run `perl annotate.pl --in ALIGN_out.tsv`
6. open the output file **CorGAT_out.tsv**, and read the annotations with your favourite program
