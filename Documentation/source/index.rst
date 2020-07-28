.. CorGAT documentation master file, created by
   sphinx-quickstart on Mon Jul 20 20:13:11 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to CorGAT's documentation!
==================================

`CorGAT <https://github.com/matteo14c/CorGAT>`_ is a collection of simple Perl scripts that can be used to align complete assemblies of SARS-CoV-2 genomes wih the reference genomic sequence, to obtain a list of polymorphic positions and to **annotate** genetic variants according to the method described in *Chiara et al 2020*  to be published soon (hopefully). The manuscript is currently submitted and undergoing peer review.

This software package is composed of 3 very simple scripts and a collection of files with functional annotation data. The only requirement is that you have an up to date installation (see below) of the Mummer package in your system and a copy of the reference genomic sequence, in fasta format. All the files (scripts, genomic sequences and accessory files) should be placed in the same folder. If you do not feel comfortable in installing/running these utilities from the command line, you can find a Galaxy running the software at http://corgat.ba.infn.it/galaxy , or download a dockerized version of the Galaxy, with all the tools at XXX.


.. toctree::
   :maxdepth: 2
   :caption: Command line version

   prerequisites.rst
   align_to_refdata.rst
   consolidate_variants.rst
   func_annotation.rst
   func_annotation_important.rst
   func_annotation_adds.rst
   impatient_people.rst

.. toctree::
   :maxdepth: 2
   :caption: Galaxy version

   import_data.rst
   analyse_data.rst

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
