#!/bin/bash
# LFS 11.0 Systemd Build Script
# Final steps to configure the system(chapter 9,10)
set -e

# 9.2.1. Network Interface Configuration Files
# 9.2.1.3. DHCP Configuration
cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=enp5s0

[Network]
DHCP=yes
EOF

# 9.2.2. Creating the /etc/resolv.conf File
# 9.2.2.2. Static resolv.conf Configuration
echo "nameserver 119.29.29.29" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# 9.2.3. Configuring the system hostname
echo "<lfs>" > /etc/hostname

# 9.2.4. Customizing the /etc/hosts File
cat > /etc/hosts << "EOF"
127.0.0.1 localhost.localdomain localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF

# 9.5.1. Network Time Synchronization
systemctl disable systemd-timesyncd

# 9.7. Configuring the System Locale
cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
EOF

# 9.8. Creating the /etc/inputrc File
cat > /etc/inputrc << "EOF"
# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line
EOF

# 9.9. Creating the /etc/shells File
cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

# 10.2. Creating the /etc/fstab File
cat > /etc/fstab << "EOF"
# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/<xxx>     /            <fff>    defaults            1     1
/dev/<yyy>     swap         swap     pri=1               0     0
EOF

# 10.3. Linux-5.13.12
cp -v /sources/linux-5.13.12.tar.xz /usr/src
cd /usr/src
tar -xf linux-5.13.12.tar.xz
cd linux-5.13.12
make mrproper
make menuconfig
make && make modules_install
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.13.12-lfs-11.0-systemd
cp -iv System.map /boot/System.map-5.13.12
cp -iv .config /boot/config-5.13.12
install -d /usr/share/doc/linux-5.13.12
cp -r Documentation/* /usr/share/doc/linux-5.13.12
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true
EOF

# 11.1. The End
echo "11.0-systemd" > /etc/lfs-release

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="11.0-systemd"
DISTRIB_CODENAME="dragon"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="11.0-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 11.0-systemd"
VERSION_CODENAME="dragon"
EOF
