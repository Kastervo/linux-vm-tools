#!/bin/bash

#
# This script is for Debian 11 Bullseye to download and install XRDP+XORGXRDP via
# source.
#
# Major thanks to: http://c-nergy.be/blog/?p=11336 for the tips.
#

###############################################################################
# Update our machine to the latest code if we need to.
#

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

sudo apt update && apt upgrade -y
sudo apt install libx11-dev libxfixes-dev libssl-dev libpam0g-dev libtool libjpeg-dev flex bison gettext autoconf libxml-parser-perl libfuse-dev xsltproc libxrandr-dev python3-libxml2 nasm fuse pkg-config git intltool checkinstall -y

if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

###############################################################################
# XRDP
#

sudo mkdir /usr/local/lib/xrdp/

cd /tmp

git clone https://github.com/neutrinolabs/xorgxrdp.git
git clone https://github.com/neutrinolabs/xrdp.git

cd /tmp/xrdp

sudo ./bootstrap
sudo make
sudo ./configure --enable-fuse --enable-jpeg --enable-rfxcodec

sudo checkinstall --pkgname=xrdp --pkgversion=$pkgver --pkgrelease=1 --default

cd /tmp/xorgxrdp

sudo ./bootstrap
sudo make
sudo ./configure XRDP_CFLAGS=-I/tmp/xrdp/common

sudo checkinstall --pkgname=xorgxrdp --pkgversion=1:$pkgver --pkgrelease=1 --default

# Configure the installed XRDP ini files.
# use vsock transport.
sed -i_orig -e 's/use_vsock=true/use_vsock=false/g' /etc/xrdp/xrdp.ini
# change the port
sed -i_orig -e 's@port=3389@port=vsock://-1:3389@g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# Add script to setup the debian session properly
if [ ! -e /etc/xrdp/startdebian.sh ]; then
cat >> /etc/xrdp/startdebian.sh << EOF
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=debian
export XDG_CURRENT_DESKTOP=debian:GNOME
exec /etc/xrdp/startwm.sh
EOF
chmod a+x /etc/xrdp/startdebian.sh
fi

# use the script to setup the debian session
sed -i_orig -e 's/startwm/startdebian/g' /etc/xrdp/sesman.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Changed the allowed_users
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist the vmw module
if [ ! -e /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf ]; then
cat >> /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf <<EOF
blacklist vmw_vsock_vmci_transport
EOF
fi

#Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure the policy xrdp session
cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# reconfigure the service
systemctl daemon-reload
systemctl start xrdp

#
# End XRDP
###############################################################################

echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
