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
There are two Primitives shown in this repository.

1. Box (OptiXBox)
2. Sphere (OptiXSphere)
3. Cylinder (OptiXCylinder)
4. Disc (OptiXDisc)

Run scripts are in the directories

OptiXBox
~~~~~~~~
This has been copied from Opticks (TODO: add link).

The expected output is OptiXBox.ppm

OptiXSphere
~~~~~~~~~~~
Uses sphere.cu defined in OptiX tests

OptiXCylinder
~~~~~~~~~~~~~
Has two versions; simple and complete.

Simple: Has as little defined as possible to see the cylinder

Complete: Has the complete interception maths of the cylinder.

In both cases the colours are set so that the sides of the cylinder are set to one colour and the top/bottom another.

OptiXDisc
~~~~~~~~~
Will have several version but currently only has one.
This primitive is for a simplification of Cylinders -> when they can be 2D.
Aim is to have Disc with multiple holes in it.
