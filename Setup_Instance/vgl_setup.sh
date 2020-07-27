wget https://objectstorage.us-ashburn-1.oraclecloud.com/n/hpc/b/grid-drivers/o/NVIDIA-Linux-x86_64-440.56-grid.run
sudo yum -y install gcc
chmod a+x NVIDIA-Linux-x86_64-440.56-grid.run
#sudo yum -y install kernel-devel
sudo yum -y install kernel-devel-$(uname -r)
sudo yum -y install xorg-x11-drivers.x86_64
#
# Disable nouveau
#sudo vim /etc/default/grub
# add  rd.driver.blacklist=nouveau nouveau.modeset=0"'
echo blacklist nouveau | sudo tee /etc/modprobe.d/blacklist.conf
sudo grub2-mkconfig -o /boot/grub2/grub.cfg # BIOS
sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg # UEFI <--- this one
sudo reboot
# check by lshw -numeric -C display
#
#
# Install grid nvidia
sudo ./NVIDIA-Linux-x86_64-440.56-grid.run
# get license
sudo mv /etc/nvidia/gridd.conf.template  /etc/nvidia/gridd.conf
# sudo vim /etc/nvidia/gridd.conf
# Sever = grid.oci-hpc.com
# FeatureType = 2
sudo reboot
#
# Set up vnc
sudo yum -y groupinstall "X Window System"
sudo yum -y install gdm
sudo yum -y groupinstall "MATE Desktop"
sudo yum -y install https://downloads.sourceforge.net/project/virtualgl/2.6.3/VirtualGL-2.6.3.x86_64.rpm
sudo yum -y install https://downloads.sourceforge.net/project/turbovnc/2.2.4/turbovnc-2.2.4.x86_64.rpm
sudo nvidia-xconfig --busid=PCI:4:0:0 --use-display-device=none
sudo systemctl restart gdm
sudo passwd opc
systemctl enable gdm --now
/opt/TurboVNC/bin/vncserver -wm mate-session -vgl -otp # /opt/TurboVNC/bin/vncserver -kill :1

sudo yum -y groupinstall "X Window System"
sudo yum -y install gdm
sudo yum -y groupinstall "Xfce"
sudo nvidia-xconfig --busid=PCI:4:0:0 --use-display-device=none
sudo vglserver_config -config +s +f -t
# turn on OTP
# sudo vim /etc/turbovncserver-security.conf
# permitted-security-types = OTP
sudo systemctl restart gdm
export DISPLAY=:1
/opt/TurboVNC/bin/vncserver -vgl -otp -wm xfce4-session
#
# firewall
sudo firewall-cmd --zone=public --permanent --add-port=5901/tcp
sudo firewall-cmd --reload
#sudo systemctl firewall restart <- ? not needed
#sudo firewall-cmd --reload <- ? not needed

# to kill
/opt/TurboVNC/bin/vncserver -kill :1

#
#
#Actuall worked with...
ls
cd nvidia/
wget https://objectstorage.us-ashburn-1.oraclecloud.com/n/hpc/b/grid-drivers/o/NVIDIA-Linux-x86_64-440.56-grid.run
sudo yum -y install gcc
chmod a+x NVIDIA-Linux-x86_64-440.56-grid.run
sudo yum -y install kernel-devel-$(uname -r)
sudo yum -y install xorg-x11-drivers.x86_64
mkdir nvidia
cd nvidia/
ls
sudo vim /etc/default/grub
sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
sudo reboot
sudo lshw -numeric -C display
sudo ./NVIDIA-Linux-x86_64-440.56-grid.run
cd nvidia/
sudo ./NVIDIA-Linux-x86_64-440.56-grid.run
sudo mv /etc/nvidia/gridd.conf.template  /etc/nvidia/gridd.conf
sudo vim /etc/nvidia/gridd.conf
sudo reboot
init 3
sudo init 3
su
sudo passwd su
sudo passwd sudo
sudo passwd
su
passwd
sudo passwd opc
sudo yum -y install https://downloads.sourceforge.net/project/virtualgl/2.6.3/VirtualGL-2.6.3.x86_64.rpm
sudo yum -y install gdm
sudo yum -y install https://downloads.sourceforge.net/project/turbovnc/2.2.4/turbovnc-2.2.4.x86_64.rpm
sudo yum -y groupinstall "X Window System"
sudo yum -y groupinstall "Xfce"
nvidia-xconfig --query-gpu-info
nvidia-smi
sudo nvidia-xconfig -a --allow-empty-initial-configuration --use-display-device=None \
sudo nvidia-xconfig -a --allow-empty-initial-configuration --virtual=1920x1200 --busid PCI:0:4:0
sudo vim /etc/X11/xorg.conf
vglserver_config --help
vglserver_config -config +s +f -t
sudo vglserver_config -config +s +f -t
sudo systemctl restart gdm
export DISPLAY=:1
/opt/TurboVNC/bin/vncserver --help
/opt/TurboVNC/bin/vncserver -vgl -wm xfce4-session
sudo firewall-cmd --zone=public --permanent --add-port=5901/tcp
sudo firewall-cmd --reload
exit
# made an image
# turboVNC stopped working with openGL (had input/output error)
# fix with
sudo nvidia-xconfig -a --allow-empty-initial-configuration --virtual=1920x1200 --busid PCI:0:4:0
export DISPLAY=:1
sudo systemctl restart gdm
/opt/TurboVNC/bin/vncserver -kill :1
/opt/TurboVNC/bin/vncserver -vgl -wm xfce4-session

