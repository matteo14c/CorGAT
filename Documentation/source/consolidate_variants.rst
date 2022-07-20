Consolidate variants into a single pseudo-vcf file
==================================================

Prior to variant annotation, mummer's output files are converted in a pseudo vcf format. This step is required also to consolidate all variant calls in a single file. This file will constitute the input for variant annotation. Please notice that this operation is required even if/when a single genome is analysed.

The ``consolidate.pl`` program, as available from this repository, is used to merge a collection of mummer output files and to convert them in the appropriate format for variant annotation. To execute this operation all you need to do is to issue the following command, from the *same* directory from where the *align.pl* program was executed:

::

  perl consolidate.pl > <consolidated_variant_calls>

Please notice that ``consolidate.pl`` will print its output directly to the standard output. 

.. warning::

   The ``>`` symbol is required to capture the output and redirect it to a file.

.. warning::

   In the example the name of the output file is ``consolidated_variant_calls`` as indicated by the angular parentheses (<>).

