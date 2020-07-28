Prerequisites and usage
=======================

This software package is composed of 3 very simple scripts and a collection of files with functional annotation data. The only requirement is that you have an up to date installation (see below) of the Mummer package in your system and a copy of the reference genomic sequence, in fasta format. All the files (scripts, genomic sequences and accessory files) should be placed in the same folder. 

Mummer installation
-------------------

Please follow this link https://sourceforge.net/projects/mummer/files/ for detailed instruction on how to install and run Mummer.

Reference genome configuration
------------------------------

The reference genome of SARS-CoV-2 can be found `here <https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/GCF_009858895.2_ASM985889v3/GCF_009858895.2_ASM985889v3_genomic.fna.gz>`_.

On a unix system you can download this file using wget

::

  wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/GCF_009858895.2_ASM985889v3/GCF_009858895.2_ASM985889v3_genomic.fna.gz

followed by

::

  gunzip GCF_009858895.2_ASM985889v3_genomic.fna.gz

Please notice that however the *align.pl* utility is going to download the file for you, if a copy of the reference genome is not found in the current folder. However, since the ``wget`` command is required this is supposed to work only unix and unix alike systems.
