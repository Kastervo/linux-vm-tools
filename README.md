# Repo Overview
This repository is the home of a set of bash scripts that enable and configure an enhanced session mode on Linux VMs (Ubuntu, arch, Debian) for Hyper-V.

# Details
This project is a fork of Microsoft's linux-vm-tools repository: https://github.com/microsoft/linux-vm-tools
We have added support for Debian 11.

# How to use

1) Clone the repo:

```git clone https://github.com/Kastervo/linux-vm-tools.git```

2) Navigate inside the debian folder:

```cd linux-vm-tools/debian/11```

3) Make the install script excecutable:

```sudo chmod +x install.sh```

4) Install the script:

```sudo ./install.sh```

5) On your host, open an elevated PowerShell and execute the following:

```Set-VM "(YOUR VM NAME HERE)" -EnhancedSessionTransportType HVSocket```

# Issues

1) If you get a black screen with cursor, make sure you haven't log in prior the enhanced session mode in the VM. Logout and login from enhanced session mode.

2) Audio displays dummy output, open a terminal from enhanced session mode and type ```pulseaudio -k```.