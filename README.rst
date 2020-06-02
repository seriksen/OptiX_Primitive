***************
OptiX_Primitive
***************
Learning and Development of OptiX primitives

.. contents::

System Setup
------------

Development Machine
~~~~~~~~~~~~~~~~~~~
Using Oracle Cloud Instance with;

* VM.GPU2.1
* CentOS7
* OptiX 6.0.0
* Tesla P100 GPU
* CUDA 10.1.168
* GPU Driver 418.67-1.0-1

Requirements Setup
~~~~~~~~~~~~~~~~~~
Follow the instructions in Setup_Instance;

1. Setup_Instance/NVIDIA_Externals.rst
2. Setup_Instance/Install_Desktop.rst (not actually needed but sometimes it's nice to have, everything does work without)
3. Setup_Instance/Install_NonNVIDIAExternals.rst
4. Add custom_setup.sh to .bashrc (add so worked when bash is called with -l)

OptiX Primitives
----------------

.. image:: ./OptiXBox/Output/ppm/OptiXBox.ppm
  :width: 400
  :alt: Alternative text
