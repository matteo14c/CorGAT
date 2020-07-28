Quickstart
==========

To do all of the above: 

#. Put fasta files of genome sequences in one folder. 1 sequence per file. all the files must have the *.fasta* extension.

#. download this `repository <https://github.com/matteo14c/CorGAT>`_.

#. run ``perl align.pl``.

#. run ``perl consolidate.pl > consolidated_variant_calls``.

#. run ``perl annotate.pl consolidated_variant_calls > funct_annot_output_file``.

#. open the output file, and read the annotations.
