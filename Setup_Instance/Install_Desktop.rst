********************
Desktop Installation
********************

Instructions for setting up GNOME with VNC on OCI.

Install GNOME
-------------

.. code-block:: sh

    sudo yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
    sudo reboot
    sudo passwd opc

Connect to instance
-------------------

1. Add ssh key to OCI console under 'Console Connections'.
2. Copy VNC Connection into terminal
3. Connect by :code:`localhost:5900`
4. Start desktop :code:`sudo systemctl isolate graphical.target`



