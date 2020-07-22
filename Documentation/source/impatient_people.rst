For impatient people
====================

To do all of the above: 
1. put fasta files of genome sequences in one folder. 1 sequence per file. all the files must have the *.fasta* extension
2. download this repo
3. run `perl align.pl`
4. run `perl consolidate.pl > consolidated_variant_calls`
5. run `perl annotate.pl consolidated_variant_calls > funct_annot_output_file`
6. open the output file, and read the annotations
