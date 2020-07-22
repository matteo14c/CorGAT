Align to the reference genome
=============================

The helper script *align.pl* can be used to align a collection of genomic sequences to the reference assembly of SARS-CoV-2 and obtain a list of polymorphic positions. The script automates all the required steps. 

The only prerequisite is that all the genomic sequences that should be aligned to the reference **MUST** be in the **same folder** from which the program is executed. The program is very simple, and can detect only files with a **.fasta** extensions. Please name your files accordingly. 

Please see above for how to obtain the reference genome sequence file. This file also needs to be in the same folder from which the program is executed (and yes **the same** where you have all the files). If the reference genome file is missing, *aling.pl* will try to download it from Genbank. Although this is supposed to work only for unix and unix alike systems (the *wget* command is required)

Once you have everything in place, you can simply run:
`perl align.pl`

For every genome fasta file you will obtain a file with the extension .snps which will contain all the polymorphic positions identified by nucmer.
