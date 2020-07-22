Functional annotation: adding functional elements!
==================================================

Functional genomic elements in the genome of SARS-CoV-2 are specified by a four columns tabular format file called annot_table.pl. This file can be used to specify additional functional elements and/or use a personalized annotation. The file has a very simple format: for every element, the first two columns specify the start and end coordinate on the genome. The third column defines the functional class. At the moment 2 different classes are supported: protein coding sequence (CDS) and non-coding (nc). The fourth column is optional and contains an additional comment/name for the functional elements.
Currently the Galaxy/dockerized versions do not allow the specification of additional annotations.

