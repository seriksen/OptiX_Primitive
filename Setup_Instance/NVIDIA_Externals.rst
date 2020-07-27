***********************
NVIDIA GPU Setup
***********************

This page contains information on how to set up a system with an NVIDIA GPU with OptiX.
These instructions are written for and tested on remote (namely, oracle cloud computing instance) CentOS7 systems
but an adapted version has also worked on Ubuntu.

These instructions are for Cuda 10.1 and OptiX 6.0


.. contents:: Contents

Nvidia Driver
-------------
This section lists the steps required to install and verify an Nvidia driver.
A good starting point for this is the
`NVIDIA Driver Installation Quickstart Guide <https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html#pre-install>`_

First, check the GPU you have.
On this machine, it is a Tesla P100.

.. code-block::

    [opc@bristollz ~]$ lspci | grep NVIDIA
    00:04.0 3D controller: NVIDIA Corporation GP100GL [Tesla P100 SXM2 16GB] (rev a1)

Now check what driver is installed and being used by the GPU.
We can see that `nouveau` is the driver.
We must disable this and use the NVidia one.

.. code-block::

    [opc@bristollz ~]$ sudo lshw -numeric -C display
    *-display:0
        description: VGA compatible controller
        product: [1234:1111]
        vendor: [1234]
        physical id: 2
        bus info: pci@0000:00:02.0
        version: 02
        width: 32 bits
        clock: 33MHz
        capabilities: vga_controller bus_master rom
        configuration: driver=bochs-drm latency=0
        resources: irq:0 memory:c0000000-c0ffffff memory:c2001000-c2001fff memory:c2010000-c201ffff
    *-display:1
        description: 3D controller
        product: GP100GL [Tesla P100 SXM2 16GB] [10DE:15F9]
        vendor: NVIDIA Corporation [10DE]
        physical id: 4
        bus info: pci@0000:00:04.0
        version: a1
        width: 64 bits
        clock: 33MHz
        capabilities: bus_master cap_list
        configuration: driver=nouveau latency=0
        resources: iomemory:200-1ff iomemory:240-23f irq:32 memory:c1000000-c1ffffff memory:2000000000-23ffffffff memory:2400000000-2401ffffff

Before downloading and installing the driver, do some CUDA related things

.. code-block:: sh

    sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sudo yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)
    sudo yum install gcc
    sudo yum -y upgrade


The NVidia driver for your GPU can be acquired from the
`Nvidia website <https://www.nvidia.co.uk/Download/index.aspx?lang=uk>`_.

.. code-block:: sh

    sudo rpm -i ${nvidia_driver} # .rpm file
    sudo yum clean all
    sudo yum install cuda-drivers
    sudo reboot
    nvidia-smi # tests to see if installed correctly output will be GPU information

After this we can see that the driver has installed correctly

.. code-block:: sh

    [opc@bristollz ~]$ sudo lshw -numeric -C display
    *-display:0
        description: VGA compatible controller
        product: [1234:1111]
        vendor: [1234]
        physical id: 2
        bus info: pci@0000:00:02.0
        version: 02
        width: 32 bits
        clock: 33MHz
        capabilities: vga_controller bus_master rom
        configuration: driver=bochs-drm latency=0
        resources: irq:0 memory:c0000000-c0ffffff memory:c2001000-c2001fff memory:c2010000-c201ffff
    *-display:1
        description: 3D controller
        product: GP100GL [Tesla P100 SXM2 16GB] [10DE:15F9]
        vendor: NVIDIA Corporation [10DE]
        physical id: 4
        bus info: pci@0000:00:04.0
        version: a1
        width: 64 bits
        clock: 33MHz
        capabilities: pm msi pciexpress bus_master cap_list
        configuration: driver=nvidia latency=0
        resources: iomemory:200-1ff iomemory:240-23f irq:10 memory:c1000000-c1ffffff memory:2000000000-23ffffffff memory:2400000000-2401ffffff

Troubleshooting
~~~~~~~~~~~~~~~
It is possible you will see the error;

.. code-block:: sh

    [opc@lz-gpu NVIDIA]$ nvidia-smi
    NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.

If this fails, do :code:`sudo yum install kernel-devel kernel-headers`, and reinstall the driver.


Nvidia Cuda
-----------
These instructions are taken from
`CUDA documentation <https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#ubuntu-installation>`_.
and the cuda `download instructions <https://developer.nvidia.com/cuda-downloads>`_.
More guidance is available from `Nvidia post-installation actions <https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions>`_.
Use these links to get the cuda rpm and key for the version you want.
The versions listed here are for Cuda 10.2

.. code-block:: sh

    sudo yum install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
    sudo yum install epel-release # enable EPEL
    wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-10.1.168-1.x86_64.rpm
    wget -O ~/cuda_key "http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub"
    sudo rpm --import ~/cuda_key.pub
    sudo rpm -i cuda-repo-rhel7-10.1.168-1.x86_64.rpm
    sudo yum clean all
    sudo yum install cuda
    sudo reboot # reboot

Now follow the post-installation instructions

.. code-block:: sh

    # Add cuda path
    export PATH=/usr/local/cuda-10.1/bin:/usr/local/cuda-10.1/NsightCompute-2019.3${PATH:+:${PATH}}
    export LD_LIBRARY_PATH=/usr/local/cuda-10.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

    sudo yum install freeglut-devel libX11-devel libXi-devel libXmu-devel make mesa-libGLU-devel

    # Verify CUDA
    mkdir cuda-samples && cd cuda-samples
    cuda-install-samples-10.1.sh .

Check the installation

.. code-block:: sh

    [opc@bristollz cuda-samples]$ nvcc --version
    nvcc: NVIDIA (R) Cuda compiler driver
    Copyright (c) 2005-2019 NVIDIA Corporation
    Built on Wed_Apr_24_19:10:27_PDT_2019
    Cuda compilation tools, release 10.1, V10.1.168

Make the simple assertion test

.. code-block:: sh

    cd /home/opc/cuda-samples/NVIDIA_CUDA-10.1_Samples/0_Simple/simpleAssert
    make

Run the test

.. code-block:: sh

    [opc@bristollz simpleAssert]$ ./simpleAssert
    simpleAssert starting...
    OS_System_Type.release = 3.10.0-957.21.3.el7.x86_64
    OS Info: <#1 SMP Tue Jun 18 16:35:19 UTC 2019>

    GPU Device 0: "Tesla P100-SXM2-16GB" with compute capability 6.0

    Launch kernel to generate assertion failures

    -- Begin assert output

    simpleAssert.cu:47: void testKernel(int): block: [1,0,0], thread: [28,0,0] Assertion `gtid < N` failed.
    simpleAssert.cu:47: void testKernel(int): block: [1,0,0], thread: [29,0,0] Assertion `gtid < N` failed.
    simpleAssert.cu:47: void testKernel(int): block: [1,0,0], thread: [30,0,0] Assertion `gtid < N` failed.
    simpleAssert.cu:47: void testKernel(int): block: [1,0,0], thread: [31,0,0] Assertion `gtid < N` failed.

    -- End assert output

    Device assert failed as expected, CUDA error message is: device-side assert triggered

    simpleAssert completed, returned OK


Nvidia OptiX
------------
To get OptiX requires an account with the NVIDIA developer program https://developer.nvidia.com/optix.
An account is free.
Once you have an account, download the bash script from the address above.
Here are the instructions for OptiX 6.0.

Then prepare for the installation;

.. code-block:: sh

    # Prepare instance
    mkdir OptiX && cd OptiX

    # Upload to if on remote machine
    # scp~/Downloads$ scp NVIDIA-OptiX-SDK-6.0.0-linux64-25650775.sh opc@132.145.219.8:/home/opc/OptiX/

Now run the script to install the instance

.. code-block:: sh

    # Install OptiX
    [opc@bristollz OptiX]$ sh NVIDIA-OptiX-SDK-6.0.0-linux64-25650775.sh
    Do you accept the license? [yN]:
    y
    By default the NVIDIA OptiX will be installed in:
    "/home/ubuntu/OptiX/NVIDIA-OptiX-SDK-6.0.0-linux64"
    Do you want to include the subdirectory NVIDIA-OptiX-SDK-6.0.0-linux64?
    Saying no will install in: "/home/opc/OptiX" [Yn]:
    y

    Using target directory: /home/opc/OptiX/NVIDIA-OptiX-SDK-6.0.0-linux64
    Extracting, please wait...

    Unpacking finished successfully

Now verify the installation

.. code-block:: sh

    # Verify OptiX
    cd NVIDIA-OptiX-SDK-6.0.0-linux64/SDK-precompiled-samples/
    export LD_LIBRARY_PATH=${PWD}:+:${LD_LIBRARY_PATH}
    ./optixHello --file hello.pbm
    sudo yum install ImageMagick ImageMagick-devel -y
    display hello.pbm

Then restart the system :code:`sudo reboot`



Notes on Nvidia OptiX tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~
On ubuntu running just ./optixHello just works and nopbo isn't an option.
It's an option on most distributions but not RHEL7/Centos7.
See https://devtalk.nvidia.com/default/topic/1046459/optix/optixmotionblur-unknown-error/

To run some of the other tests, see what commands they have ie. `./optixHello --help`
Many will be able to write out to a file which can then be viewed as above `display <pbm file>`

If on a remote machine, X11 forwarding will need to be setup

.. code-block:: sh

    # Update the packages
    sudo yum -y update
    sudo yum install -y xorg-x11-apps.x86_64 xauth

    # Now log in using -X for X11 forwarding
    ssh -AX user@address
    # Verify
    xclock





For Opticks visuals

[opc@instance-20200630-1205 opticks]$ hg diff
diff -r 9495708d9b9d cmake/Modules/FindOptiX.cmake
--- a/cmake/Modules/FindOptiX.cmake	Fri Dec 06 21:12:14 2019 +0800
+++ b/cmake/Modules/FindOptiX.cmake	Wed Jul 01 04:34:37 2020 +0000
@@ -39,6 +39,10 @@
   set(bit_dest "")
 endif()

+if (DEFINED ENV{OptiX_INSTALL_DIR})
+  set(OptiX_INSTALL_DIR $ENV{OptiX_INSTALL_DIR})
+endif()
+
 macro(OPTIX_find_api_library name version)
   find_library(${name}_LIBRARY
     NAMES ${name}.${version} ${name}
diff -r 9495708d9b9d cmake/Modules/FindOpticksGLEW.cmake
--- a/cmake/Modules/FindOpticksGLEW.cmake	Fri Dec 06 21:12:14 2019 +0800
+++ b/cmake/Modules/FindOpticksGLEW.cmake	Wed Jul 01 04:34:37 2020 +0000
@@ -17,7 +17,7 @@
 )
 find_library( OpticksGLEW_LIBRARY
               NAMES glew GLEW libglew32 glew32
-              PATHS ${OpticksGLEW_PREFIX}/lib )
+              PATHS ${OpticksGLEW_PREFIX}/lib64 )

 if(OpticksGLEW_VERBOSE)
   message(STATUS "OpticksGLEW_MODULE      : ${OpticksGLEW_MODULE}")
diff -r 9495708d9b9d externals/openmesh.bash
--- a/externals/openmesh.bash	Fri Dec 06 21:12:14 2019 +0800
+++ b/externals/openmesh.bash	Wed Jul 01 04:34:37 2020 +0000
@@ -1090,7 +1090,7 @@

 openmesh-env(){  olocal- ; opticks- ; }
 #openmesh-vers(){ echo 4.1 ; }
-openmesh-vers(){ echo 6.3 ; }
+openmesh-vers(){ echo 7.1 ; }

 openmesh-info(){ cat << EOI

diff -r 9495708d9b9d oglrap/OpticksViz.cc
--- a/oglrap/OpticksViz.cc	Fri Dec 06 21:12:14 2019 +0800
+++ b/oglrap/OpticksViz.cc	Wed Jul 01 04:34:37 2020 +0000
@@ -533,11 +533,11 @@

 void OpticksViz::renderLoop()
 {
-    if(m_interactivity == 0 )
-    {
-        LOG(LEVEL) << "early exit due to InteractivityLevel 0  " ;
-        return ;
-    }
+   // if(m_interactivity == 0 )
+   // {
+   //     LOG(LEVEL) << "early exit due to InteractivityLevel 0  " ;
+   //     return ;
+   // }
     LOG(LEVEL) << "enter runloop ";

     //m_frame->toggleFullscreen(true); causing blankscreen then segv
diff -r 9495708d9b9d optickscore/OpticksMode.cc
--- a/optickscore/OpticksMode.cc	Fri Dec 06 21:12:14 2019 +0800
+++ b/optickscore/OpticksMode.cc	Wed Jul 01 04:34:37 2020 +0000
@@ -98,15 +98,15 @@
     m_noviz(ok->hasArg(NOVIZ_ARG_)),
     m_forced_compute(false)
 {
-    if(SSys::IsRemoteSession())
-    {
-        m_mode = COMPUTE_MODE ;
-        m_forced_compute = true ;
-    }
-    else
-    {
+   // if(SSys::IsRemoteSession())
+   // {
+   //     m_mode = COMPUTE_MODE ;
+   //     m_forced_compute = true ;
+   // }
+   // else
+   // {
         m_mode = m_compute_requested ? COMPUTE_MODE : INTEROP_MODE ;
-    }
+   // }
 }

 void OpticksMode::setOverride(unsigned int mode)
diff -r 9495708d9b9d opticksgeo/OpticksHub.cc
--- a/opticksgeo/OpticksHub.cc	Fri Dec 06 21:12:14 2019 +0800
+++ b/opticksgeo/OpticksHub.cc	Wed Jul 01 04:34:37 2020 +0000
@@ -326,8 +326,8 @@
     //assert( m_ok->isTracer() ) ;


-    bool compute = m_ok->isCompute();
-    bool compute_opt = hasOpt("compute") ;
+    bool compute = false; //m_ok->isCompute();
+    bool compute_opt = true; //hasOpt("compute") ;
     if(compute && !compute_opt)
         LOG(error) << "FORCED COMPUTE MODE : as remote session detected " ;




bash_history for virtualGL


