## Linux From Scratch 11.0 Systemd Build Scripts

(需配合[Linux From Scratch 11.0 Systemd官方文档](https://www.linuxfromscratch.org/lfs/downloads/11.0-systemd/)食用)

0.前置说明

- lfs-cross.sh：编译交叉工具链，由宿主机的lfs用户执行。
- lfs-chroot.sh：编译临时工具，由chroot环境中的root执行。
- lfs-build.sh：构建LFS系统，由chroot环境中的root执行。
- lfs-config.sh：配置LFS系统并编译内核，请根据硬件配置自行修改。

1.检查宿主机上软件的版本

```bash
# any user
bash version-check.sh
```

2.新建LFS分区并挂载

```bash
# root
cfdisk /dev/? # ?表示磁盘名，例如sda、nvme0n1
mkfs.ext4 -v /dev/?N # N表示磁盘上第几个分区
export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v /dev/?N $LFS # 其他目录不单独分区，只有根目录
```

3.将下载的[lfs-packages-11.0.tar](https://mirrors.ustc.edu.cn/lfs/lfs-packages/lfs-packages-11.0.tar)解压在$LFS/sources目录

```bash
# root
export LFS=/mnt/lfs
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
tar -xf ~/Downloads/lfs-packages-11.0.tar -C $LFS/sources
mv -v $LFS/sources/11.0/* $LFS/sources
rm -rf $LFS/sources/11.0
pushd $LFS/sources
  md5sum -c md5sums
popd
```

4.为LFS创建目录

```bash
# root
export LFS=/mnt/lfs
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
mkdir -pv $LFS/tools
```

5.添加一个专门编译LFS临时工具链的用户并配置环境变量

```bash
# root
export LFS=/mnt/lfs
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
chown -v lfs $LFS/sources
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
su - lfs

# lfs
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

source ~/.bash_profile
```

6.编译交叉编译工具链（5-6章）

```bash
# lfs
set # 编译前检查环境变量是否正确
export MAKEFLAGS="-j9" # 编译线程数
./lfs-cross.sh
```

7.将LFS目录权限修改回root

```bash
# root
export LFS=/mnt/lfs
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac
```

8.为LFS建立文件系统并挂载

```bash
# root
export LFS=/mnt/lfs
mkdir -pv $LFS/{dev,proc,sys,run}
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
```

9.进入chroot环境

```bash
# root
export LFS=/mnt/lfs
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login +h
```

10.创建必要的目录和文件

```bash
# (chroot) root
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

ln -sv /proc/self/mounts /etc/mtab
cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:81:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

exec /bin/bash --login +h # "I have no name!" -> root

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
```

11.在chroot环境中编译临时工具

```bash
# (chroot) root
export MAKEFLAGS="-j9"
./lfs-chroot.sh
```

12.清理

```bash
# (chroot) root
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools
exit

# root
export LFS=/mnt/lfs
umount $LFS/dev{/pts,}
umount $LFS/{sys,proc,run}
```

13.重新挂载文件系统，接下来进入chroot环境并构建整个系统

```bash
# root
export LFS=/mnt/lfs
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login +h

# (chroot) root
export MAKEFLAGS="-j9"
./lfs-build.sh
```

14.剥离调试符号及清理

```bash
# (chroot) root
save_usrlib="$(cd /usr/lib; ls ld-linux*)
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0 
             libstdc++.so.6.0.29
             libitm.so.1.0.0 
             libatomic.so.1.2.0" 
cd /usr/lib
for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done
online_usrbin="bash find strip"
online_usrlib="libbfd-2.37.so
               libhistory.so.8.1
               libncursesw.so.6.2
               libm.so.6
               libreadline.so.8.1
               libz.so.1.2.11
               $(cd /usr/lib; find libnss*.so* -type f)"
for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done
for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done
for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* ) 
            ;;
        * ) strip --strip-unneeded $i 
            ;;
    esac
done
unset BIN LIB save_usrlib online_usrbin online_usrlib
rm -rf /tmp/*
logout

# root
export LFS=/mnt/lfs
chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/usr/bin:/usr/sbin            \
    /bin/bash --login

# (chroot) root
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
```

15.配置LFS系统和编译内核（运行脚本之前请仔细阅读脚本内容并根据硬件配置进行修改，避免出现错误；运行之前需要把终端最大化，不然内核参数选项会报错窗口太小！！！）

```bash
# (chroot) root
export MAKEFLAGS="-j9"
./lfs-config.sh

passwd # 设置root密码
vim /etc/fstab # 配置开机挂载选项
```

16.使用宿主机的GRUB2引导LFS系统。宿主机安装`os-prober`，生成grub.cfg文件

```bash
# root
grub-mkconfig -o /boot/grub/grub.cfg
```

17.完成
