Functional annotation: Important!
=================================

Please notice, that to work properly *annotate.pl* needs to have access (read) several annotation files which provide the different types of functional annotations. If these files are not available, the program will exit with an error, complaining that one or more of the files are missing.
These files that are **strictly required** and can be downloaded from the current github repository. The repository itself is updated on a 2 week basis. So it is **highly advised** that the latest version of the files should be downloaded **before** you perform functional annotation.
In the Galaxy and docker version, these files are updated automatically. All the files need to be (and normally are) in the **same folder** from which annotate.pl is executed.

The annotation files, all in simple text format include:
1. *genetic_code* -> 3 column file with the standard genetic code
2. *GCA_009858895.3_ASM985889v3_genomic.fna* -> the reference SARS-CoV-2 genome assembly sequence
3. *annot_table.pl* -> a 4 column tabular file with genomic coordinates of functional genomic elements
4. *af_data_new.csv* -> tabular file with allele frequency data
5. *MFE_annot.csv* -> tabular file with Mininum Free Energy predictions for all the possible Single Nucleotide substitutions in secondary structure elements
6. *epitopes_annot.csv* -> tabular file with annotation of predicted epitopes
7. *hyphy.csv* -> tabular file with aa residues under selection according to meme/fel

Please see below for a brief guide that will help you to define additional functional elements in *annot_table.pl*
