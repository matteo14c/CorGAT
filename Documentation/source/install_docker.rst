Installing the CorGAT Galaxy
============================

See here: `CorGAT flavor <https://github.com/matteo14c/CorGAT/tree/Revision_V1>`_ for the Github repository

How to use
==========


* To install Docker follow this `procedure <https://docs.docker.com/engine/install//>`_.

* Run the container (i.e CorGAT)
  `docker run -d --privileged -p 8080:80 -p 8021:21 -p 8022:22 laniakeacloud/galaxy_corgat:19.01`
  
* Log into Galaxy at http://localhost:8080 username: `admin@galaxy.org` passwd: `admin`

What to do next:
================
::

Now you have a local copy of the CorGAT Galaxy instance. Please refer to the CorGAT Galaxy `manual <https://corgat.readthedocs.io/en/latest/>`_. for tips and instructions on how to execute your analyses  

Galaxy dockers 
==============

::

For a more detailed refence on the usage and configuration of Docker based Galaxy instances see: https://github.com/bgruening/docker-galaxy-stable
