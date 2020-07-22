Functional annotation
=====================

The *annotate.pl* utility is used to perform functional annotation of SARS-CoV-2 variants. The program can be executed very easily, by running:
`perl annotate.pl consolidated_variant_calls > <funct_annot_output_file.csv>`

Similar to *consolidate.pl* the output is printed directly to your screen (standard output). Again, to save everything into a file you need to redirect (*>* symbol). My personal suggestion is to add a *.csv* or a *.tsv* extension to the name of the output file. So that it can be opened directly by a spreadsheet editor software, like for example MS excel or OpenOffice Calc. If/when the docker or Galaxy version of this software are used, the output can be visualized directly in your browser.

The output consists in a simple table, delineated by <tab> (tabulations) and formatted as follows:
Genomic position | Ref allele| Alt allele | Funct Elem annot| Allele Frequency | Epitopes annot | Selection annot | MFE annot | 
---------------- |-----------|------------|-----------------|------------------|----------------|-----------------|-----------|
376|G|T|nsp1:c.111G>T,p.E37D,missense;orf1ab:c.111G>T,p.E37D,missense;|0.166|FGDSVEEVL,1,HLA-C\*08:01|fel:true;meme:true;kind:positive|NA
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
