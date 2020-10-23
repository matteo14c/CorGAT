Align to the reference genome
=============================

The helper script *align.pl* can be used to align a collection of genomic sequences to the reference assembly of SARS-CoV-2 and obtain a list of polymorphic positions. The script automates all the required steps. align.pl currently allows 3 different distinct methods to provide input files/sequences.
::

Inputs, alternatives:

  * ``Through a multifasta file: option --multi;``
  * ``Through a multifasta file: option --multi;``
  * ``By specifying a "suffix" that is common to all the names of the files that should be analyses: option --suffix;``

::

All input files *MUST*  be in the *same folder* from which the program is executed. A temporary directory will be created to store all the intermediate files and the alingment results for every file. The name of this temporary directory can be specified using the **--tmpdir option**. Please notice that this temporary directory, normally, will be deleted after the execution of align.pl. The **--clean option**, can be used to alter this behavior. If set to **F=FALSE** the temporary directory will not be deleted.

::

Finally the name of the output file can be specified by using the **--out option**. This defaults to **ALIGN_out.tsv**. 

Once you have everything in place, you can simply run:
::
  
  perl align.pl --multi <multifasta>` to align all the genomes contained in a multifasta file or
  
  perl align.pl --suffix <fasta>` to align all the .fasta files contained in the current folder or
  
  perl align.pl --filelist <list>` to align all the files specified in a list of file names.One file per line. Again, all files need to be in the current folder
::

For every genome fasta file you will obtain a file with the extension .snps which will contain all the polymorphic positions identified by nucmer. These files will be stored in the temporary directory, as specified by the --tmpdir option (default align.tmp). If the --clean option is set to **T (TRUE) however, this directory will be removed** after the execution of the program.

::

The final output consists in a simple tabular file (default name **ALIGN_out.tsv**) that lists genetic variants on the rows, and reports their presence (1) or absence (0) in the different genomes included in your analysis in the columns. 

Please check the section :doc:`prerequisites` to obtain the reference genome sequence file. This file also needs to be in the same folder from which the program is executed (and yes **the same** where you have all the files). If the reference genome file is missing, *aling.pl* will try to download it from Genbank. Although this is supposed to work only for unix and unix alike systems (the *wget* command is required)

Once you have everything in place you can simply run, To check if everything works:

::

  perl align.pl

The help message, should be self-explanatory. You can try all the 3 different commands under the EXAMPLE section to test align.pl . Example input files are also provided in the main repository of CorGAT
