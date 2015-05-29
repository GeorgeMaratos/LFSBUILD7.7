set +e
#third compilation step after execing the new shell

#bc

tar xf bc-1.06.95.tar.bz2

cd bc-1.06.95

patch -Np1 -i ../bc-1.06.95-memory_leak-1.patch

./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info

make

make install

cd ..
rm -rf bc-1.06.95

#libtool

tar xf libtool-2.4.6.tar.xz

cd libtool-2.4.6

./configure --prefix=/usr

make -j8

make install

cd ..

rm -rf libtool-2.4.6


#gdbm-1.11.tar.gz

tar xf gdbm-1.11.tar.gz

cd gdbm-1.11

./configure --prefix=/usr --enable-libgdbm-compat
make
make install

cd ..
rm -rf gdbm-1.11

#expat-2.1.0.tar.gz

tar xf expat-2.1.0.tar.gz

cd expat-2.1.0

./configure --prefix=/usr
make
make install

install -v -dm755 /usr/share/doc/expat-2.1.0
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.1.0

cd ..
rm -rf expat-2.1.0


#ineutils

tar xf inetutils-1.9.2.tar.gz

cd inetutils-1.9.2

echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 

./configure --prefix=/usr  \
            --localstatedir=/var   \
            --disable-logger       \
            --disable-whois        \
            --disable-servers

make

make install

mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin

cd ..
rm -rf inetutils-1.9.2



#perl

tar xf perl-5.20.2.tar.bz2

cd perl-5.20.2

echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib

make

make install

unset BUILD_ZLIB BUILD_BZIP2

cd ..
rm -rf perl-5.20.2


#XML-Parser-2.44.tar.gz

tar xf XML-Parser-2.44.tar.gz

cd XML-Parser-2.44

perl Makefile.PL
make
make install

cd ..
rm -rf XML-Parser-2.44



#autoconf-2.69.tar.xz

tar xf autoconf-2.69.tar.xz

cd autoconf-2.69

./configure --prefix=/usr
make
make install

cd ..
rm -rf autoconf-2.69

#automake-1.15.tar.xz

tar xf automake-1.15.tar.xz

cd automake-1.15

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.15
make
make install

cd ..
rm -rf automake-1.15

#diffutils

tar xf diffutils-3.3.tar.xz

cd diffutils-3.3

sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
./configure --prefix=/usr
make
make install

cd ..
rm -rf diffutils-3.3

#gawk-4.1.1.tar.xz

tar xf gawk-4.1.1.tar.xz

cd gawk-4.1.1

./configure --prefix=/usr
make
make install

mkdir -v /usr/share/doc/gawk-4.1.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.1.1

cd ..
rm -rf gawk-4.1.1

#findutils-4.4.2.tar.gz

tar xf findutils-4.4.2.tar.gz

cd findutils-4.4.2

./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make install

mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb

cd ..
rm -rf findutils-4.4.2

#gettext

tar xf gettext-0.19.4.tar.xz

cd gettext-0.19.4

./configure --prefix=/usr --docdir=/usr/share/doc/gettext-0.19.4

make -j8

make install

cd ..
rm -rf gettext-0.19.4

#intltool-0.50.2.tar.gz

tar xf intltool-0.50.2.tar.gz

cd intltool-0.50.2

./configure --prefix=/usr
make
make install

install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.50.2/I18N-HOWTO

cd ..
rm -rf intltool-0.50.2

#gperf

tar xf gperf-3.0.4.tar.gz

cd gperf-3.0.4

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4
make
make install

cd ..
rm -rf gperf-3.0.4

#groff

tar xf groff-1.22.3.tar.gz

cd groff-1.22.3

PAGE=letter ./configure --prefix=/usr

make
make install

cd ..
rm -rf groff-1.22.3

#xz

tar xf xz-5.2.0.tar.xz

cd xz-5.2.0

./configure --prefix=/usr --docdir=/usr/share/doc/xz-5.2.0

make
make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

cd ..
rm -rf xz-5.2.0


#grub-2.02~beta2.tar.xz

tar xf grub-2.02~beta2.tar.xz

cd grub-2.02~beta2

./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-grub-emu-usb \
            --disable-efiemu       \
            --disable-werror

make

make install

cd ..
rm -rf grub-2.02~beta2


#less

tar xf less-458.tar.gz

cd less-458

./configure --prefix=/usr --sysconfdir=/etc
make
make install

cd ..
rm -rf less-458


#gzip

tar xf gzip-1.6.tar.xz

cd gzip-1.6

./configure --prefix=/usr --bindir=/bin
make
make install
mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin

cd ..
rm -rf gzip-1.6



#iproute2-3.19.0.tar.xz

tar xf iproute2-3.19.0.tar.xz

cd iproute2-3.19.0

sed -i '/^TARGETS/s@arpd@@g' misc/Makefile
sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile
make
make DOCDIR=/usr/share/doc/iproute2-3.19.0 install

cd ..
rm -rf iproute2-3.19.0


#kbd-2.0.2.tar.gz

tar xf kbd-2.0.2.tar.gz

cd kbd-2.0.2

patch -Np1 -i ../kbd-2.0.2-backspace-1.patch

sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock

make
make install

mkdir -v       /usr/share/doc/kbd-2.0.2
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.2

cd ..
rm -rf kbd-2.0.2

#kmod-19.tar.xz

tar xf kmod-19.tar.xz

cd kmod-19

./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib

make

make install

for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sv ../bin/kmod /sbin/$target
done

ln -sv kmod /bin/lsmod


cd ..
rm -rf kmod-19


#libpipeline-1.4.0.tar.gz

tar xf libpipeline-1.4.0.tar.gz

cd libpipeline-1.4.0

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr

make
make install

cd ..
rm -rf libpipeline-1.4.0


#make-4.1.tar.bz2

tar xf make-4.1.tar.bz2

cd make-4.1

./configure --prefix=/usr

make
make install

cd ..
rm -rf make-4.1



#patch-2.7.4.tar.xz

tar xf patch-2.7.4.tar.xz

cd patch-2.7.4

./configure --prefix=/usr
make
make install

cd ..
rm -rf patch-2.7.4



#sysklogd-1.5.1.tar.gz

tar xf sysklogd-1.5.1.tar.gz

cd sysklogd-1.5.1

sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
make
make BINDIR=/sbin install


cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF

cd ..
rm -rf sysklogd-1.5.1



#sysvinit-2.88dsf.tar.bz2

tar xf sysvinit-2.88dsf.tar.bz2

cd sysvinit-2.88dsf

patch -Np1 -i ../sysvinit-2.88dsf-consolidated-1.patch
make -C src
make -C src install

cd ..
rm -rf sysvinit-2.88dsf



#tar-1.28.tar.xz

tar xf tar-1.28.tar.xz

cd tar-1.28

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin


make
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.28

cd ..
rm -rf tar-1.28



#texinfo-5.2.tar.xz

tar xf texinfo-5.2.tar.xz

cd texinfo-5.2

./configure --prefix=/usr
make
make install

make TEXMF=/usr/share/texmf install-tex

cd ..
rm -rf texinfo-5.2



#eudev-2.1.1.tar.gz
tar xf eudev-2.1.1.tar.gz

cd eudev-2.1.1

sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl
BLKID_CFLAGS=-I/tools/include       \
BLKID_LIBS='-L/tools/lib -lblkid'   \
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-split-usr      \
            --enable-libkmod        \
            --enable-rule_generator \
            --enable-keymap         \
            --disable-introspection \
            --disable-gudev         \
            --disable-gtk-doc-html

make
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d

make install

tar -xvf ../eudev-2.1.1-manpages.tar.bz2 -C /usr/share



tar -xvf ../udev-lfs-20140408.tar.bz2
make -f udev-lfs-20140408/Makefile.lfs install

udevadm hwdb --update


cd ..
rm -rf eudev-2.1.1


#util-linux-2.26.tar.xz

tar xf util-linux-2.26.tar.xz

cd util-linux-2.26

mkdir -pv /var/lib/hwclock

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.26 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir

make

make install

cd ..
rm -rf util-linux-2.26

#man-db-2.7.1.tar.xz

tar xf man-db-2.7.1.tar.xz

cd man-db-2.7.1

./configure --prefix=/usr                          \
            --docdir=/usr/share/doc/man-db-2.7.1 \
            --sysconfdir=/etc                      \
            --disable-setuid                       \
            --with-browser=/usr/bin/lynx           \
            --with-vgrind=/usr/bin/vgrind          \
            --with-grap=/usr/bin/grap

make

make install

cd ..
rm -rf man-db-2.7.1


#vim 

tar xf vim-7.4.tar.bz2

cd vim-7.4

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make

make install

ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim74/doc /usr/share/doc/vim-7.4

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

cd ..
rm -rf vim-7.4



