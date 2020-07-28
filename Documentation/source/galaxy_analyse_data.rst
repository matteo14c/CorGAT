Analysing your data
===================

.. warning::

   Please notice, this manual provide just a quick and simple reference for the usage of the Galaxy version of CorGAT. Please refer to https://galaxyproject.org/learn/ for a complete and accurate reference on how to use Galaxy.

Once all the files have been imported, the analysis with CorGAT is very straightforward.

If everything was done according to the instruction provided in the first part of this manual, you should see something like this:

.. figure:: _static/img/corgat6.png
   :scale: 50%
   :align: center

The first operation that you are required to do, is the alignment between your genome assemblies and the reference genome. This can be done by means of the “nucmer_snp” which is found under the “Coronavirus Annotation Tool” menu. Simply click on the tool.

The interface is very simple: you are only required to indicate the reference (form on the top) and the “target” genome (form on the bottom). Multiple target genomes can be provided by clicking on the “multiple datasets icon”. Once all the “target genomes” have been selected, to run the analysis you can simply hit “Execute” (the blue button).

See below for an example:

.. figure:: _static/img/corgat7.png
   :scale: 50%
   :align: center

After a brief while, you should obtain an output file for every input genome. These file need to be merged before performing the functional annotation of the variants. This operation is performed by applying the ``join_nucmer`` utility, again under ``Coronavirus Annotation Tool``. The interface of the tool is again very simple. All you need to do is to select the files that need to be merged from the form. And once ready, again hit execute.

.. figure:: _static/img/corgat8.png
   :scale: 50%
   :align: center

The output will be a single file called ``consolidate_variants``.  This last file, will provide the input of the functional annotation tool, ``FunAnn`` which is found under the ``Coronavirus Annotation Tool`` menu. FunAnn takes only a single file as its input. This is the file created by ``join_nucmer``. To execute the functional annotation of the variants in your genome,  click on the ``FunAnn`` tool and provide the input file. Then hit execute. You should obtain 2 output files. A log file (hopefully empty) which reports possible errors encountered in the execution of the software, and a tabular file with the annotations. If no errors files were encountered, you should see an output file that reads like this:

.. figure:: _static/img/corgat9.png
   :scale: 50%
   :align: center

Congrats! If you have reached this point you should now be able to use CorGAT to annotate genomic variants in your SARS-CoV-2 genomes.

Please refer to the paper or this documentation for a more complete description of the functional annotations provided by CorGAT.
