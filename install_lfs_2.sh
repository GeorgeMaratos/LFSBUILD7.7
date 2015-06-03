#!/bin/bash

set -e

touch /var/log/{btmp,lastlog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

#now we build lfs

#api headers
tar xf linux-3.19.tar.xz

cd linux-3.19

make -j8 mrproper

make -j8 INSTALL_HDR_PATH=dest headers_install

find dest/include \( -name .install -o -name ..install.cmd \) -delete

cp -rv dest/include/* /usr/include

cd ..

rm -rf linux-3.19

#man pages

tar xf man-pages-3.79.tar.xz

cd man-pages-3.79

make -j8 install

cd ..
rm -rf man-pages-3.79

#glibc

tar xf glibc-2.21.tar.xz

cd glibc-2.21

patch -Np1 -i ../glibc-2.21-fhs-1.patch

sed -e '/ia32/s/^/1:/' \
    -e '/SSE2/s/^1://' \
    -i  sysdeps/i386/i686/multiarch/mempcpy_chk.S

mkdir -v ../glibc-build
cd ../glibc-build



../glibc-2.21/configure    \
    --prefix=/usr          \
    --disable-profile      \
    --enable-kernel=2.6.32 \
    --enable-obsolete-rpc

make -j8

touch /etc/ld.so.conf

make -j8 install

cp -v ../glibc-2.21/nscd/nscd.conf /etc/nscd.conf

mkdir -pv /var/cache/nscd

mkdir -pv /usr/lib/locale
localedef -i en_US -f UTF-8 en_US.UTF-8

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../tzdata2015a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

cp -v /usr/share/zoneinfo/America/Chicago /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

mkdir -pv /etc/ld.so.conf.d

cd ..
rm -rf glibc-build glibc-2.21

#adjusting the toolchain

mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs


#checking sanity of the tool chain
echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log

grep -B1 '^ /usr/include' dummy.log

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

grep "/lib.*/libc.so.6 " dummy.log

grep found dummy.log



read -rsp $'Press any key to continue...\n' -n1 key
rm -v dummy.c a.out dummy.log

#zlib

tar xf zlib-1.2.8.tar.xz

cd zlib-1.2.8

./configure --prefix=/usr
make
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

cd ..
rm -rf zlib-1.2.8

#file

tar xf file-5.22.tar.gz

cd file-5.22

./configure --prefix=/usr
make
make install

cd ..
rm -rf file-5.22

#binutils

tar xf binutils-2.25.tar.bz2

cd binutils-2.25

mkdir -v ../binutils-build
cd ../binutils-build

../binutils-2.25/configure --prefix=/usr   \
                           --enable-shared \
                           --disable-werror

make -j8 tooldir=/usr

make -j8 tooldir=/usr install

cd ..
rm -rf binutils-2.25 binutils-build

#gmp

tar xf gmp-6.0.0a.tar.xz

cd gmp-6.0.0

ABI=32 ./configure --prefix=/usr \
            --enable-cxx  \
            --docdir=/usr/share/doc/gmp-6.0.0a

make -j8
make -j8 html

make -j8 install
make -j8 install-html

cd ..
rm -rf gmp-6.0.0

#mpfr

tar xf mpfr-3.1.2.tar.xz

cd mpfr-3.1.2
patch -Np1 -i ../mpfr-3.1.2-upstream_fixes-3.patch

./configure --prefix=/usr        \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-3.1.2

make
make html

make install
make install-html

cd ..
rm -rf mpfr-3.1.2

#MPC

tar xf mpc-1.0.2.tar.gz

cd mpc-1.0.2

./configure --prefix=/usr --docdir=/usr/share/doc/mpc-1.0.2
make
make html

make install
make install-html

cd ..
rm -rf mpc-1.0.2

#gcc

tar xf gcc-4.9.2.tar.bz2

cd gcc-4.9.2
mkdir -v ../gcc-build
cd ../gcc-build



SED=sed                       \
../gcc-4.9.2/configure        \
     --prefix=/usr            \
     --enable-languages=c,c++ \
     --disable-multilib       \
     --disable-bootstrap      \
     --with-system-zlib

make -j8

make -j8 install



ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/4.9.2/liblto_plugin.so /usr/lib/bfd-plugins/


echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log

grep -B4 '^ /usr/include' dummy.log

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

grep "/lib.*/libc.so.6 " dummy.log

grep found dummy.log

read -rsp $'Press any key to continue...\n' -n1 key

rm -v dummy.c a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd ..

rm -rf gcc-4.9.2 gcc-build


#bzip

tar xf bzip2-1.0.6.tar.gz

cd bzip2-1.0.6

patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean

make

make PREFIX=/usr install

cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat

cd ..

rm -rf bzip2-1.0.6

#pkg-config

tar xf pkg-config-0.28.tar.gz

cd pkg-config-0.28

./configure --prefix=/usr         \
            --with-internal-glib  \
            --disable-host-tool   \
            --docdir=/usr/share/doc/pkg-config-0.28

make
make install

cd ..
rm -rf pkg-config-0.28

#ncurses

tar xf ncurses-5.9.tar.gz

cd ncurses-5.9

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --enable-pc-files       \
            --enable-widec

make
make install

mv -v /usr/lib/libncursesw.so.5* /lib

ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv lib${lib}w.a      /usr/lib/lib${lib}.a
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncurses++w.a /usr/lib/libncurses++.a

rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
ln -sfv libncursesw.a      /usr/lib/libcursesw.a
ln -sfv libncurses.a       /usr/lib/libcurses.a

mkdir -v       /usr/share/doc/ncurses-5.9
cp -v -R doc/* /usr/share/doc/ncurses-5.9

cd ..
rm -rf ncurses-5.9

#attr

tar xf attr-2.4.47.src.tar.gz

cd attr-2.4.47

sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in

./configure --prefix=/usr --bindir=/bin

make

make install install-dev install-lib
chmod -v 755 /usr/lib/libattr.so

mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

cd ..

rm -rf attr-2.4.47

#acl

tar xf acl-2.2.52.src.tar.gz

cd acl-2.2.52

sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" \
    libacl/__acl_to_any_text.c

./configure --prefix=/usr \
            --bindir=/bin \
            --libexecdir=/usr/lib

make

make install install-dev install-lib
chmod -v 755 /usr/lib/libacl.so
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so

cd ..
rm -rf acl-2.2.52

#libcap

tar xf libcap-2.24.tar.xz

cd libcap-2.24

make

make RAISE_SETFCAP=no prefix=/usr install
chmod -v 755 /usr/lib/libcap.so

mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so

cd ..
rm -rf libcap-2.24

#sed

tar xf sed-4.2.2.tar.bz2

cd sed-4.2.2

./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2

make
make html
make install
make -C doc install-html

cd ..
rm -rf sed-4.2.2

#shadow

tar xf shadow-4.2.1.tar.xz

cd shadow-4.2.1

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32

make 
make install

mv -v /usr/bin/passwd /bin

pwconv
grpconv

passwd root

cd ..
rm -rf shadow-4.2.1

#psmisc
tar xf psmisc-22.21.tar.gz

cd psmisc-22.21

./configure --prefix=/usr

make

make install

mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin

cd ..

rm -rf psmisc-22.21

#procps-ng-3.3.10.tar.xz

tar xf procps-ng-3.3.10.tar.xz

cd procps-ng-3.3.10

./configure --prefix=/usr                           \
            --exec-prefix=                          \
            --libdir=/usr/lib                       \
            --docdir=/usr/share/doc/procps-ng-3.3.10 \
            --disable-static                        \
            --disable-kill

make

make install

mv -v /usr/bin/pidof /bin
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

cd ..
rm -rf procps-ng-3.3.10

#e2fsprogs-1.42.12.tar.gz

tar xf e2fsprogs-1.42.12.tar.gz

cd e2fsprogs-1.42.12

sed -e '/int.*old_desc_blocks/s/int/blk64_t/' \
    -e '/if (old_desc_blocks/s/super->s_first_meta_bg/desc_blocks/' \
    -i lib/ext2fs/closefs.c

mkdir -v build
cd build

LIBS=-L/tools/lib                    \
CFLAGS=-I/tools/include              \
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make
make install

make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

cd ../..

rm -rf e2fsprogs-1.42.12


#coreutils

tar xf coreutils-8.23.tar.xz

cd coreutils-8.23

patch -Np1 -i ../coreutils-8.23-i18n-1.patch 
touch Makefile.in

FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

make

echo "dummy:x:1000:nobody" >> /etc/group

chown -Rv nobody . 

sed -i '/dummy/d' /etc/group

make install

mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

mv -v /usr/bin/{head,sleep,nice,test,\[} /bin 

cd ..

rm -rf coreutils-8.23

#iana

tar xf iana-etc-2.30.tar.bz2

cd iana-etc-2.30

make
make install

cd ..

rm -rf iana-etc-2.30

# m4-1.4.17.tar.xz

tar xf m4-1.4.17.tar.xz

cd m4-1.4.17

./configure --prefix=/usr

make 
make install

cd ..

rm -rf m4-1.4.17


#flex

tar xf flex-2.5.39.tar.bz2

cd flex-2.5.39

sed -i -e '/test-bison/d' tests/Makefile.in

./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.5.39

make
make install

ln -sv flex /usr/bin/lex

cd ..

rm -rf flex-2.5.39

#bison

tar xf bison-3.0.4.tar.xz

cd bison-3.0.4

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.4

make -j8
make install

cd ..

rm -rf bison-3.0.4

#grep-2.21.tar.xz

tar xf grep-2.21.tar.xz

cd grep-2.21

sed -i -e '/tp++/a  if (ep <= tp) break;' src/kwset.c

./configure --prefix=/usr --bindir=/bin

make

make install

cd ..

rm -rf grep-2.21

#readline-6.3.tar.gz

tar xf readline-6.3.tar.gz

cd readline-6.3

patch -Np1 -i ../readline-6.3-upstream_fixes-3.patch
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr --docdir=/usr/share/doc/readline-6.3
make SHLIB_LIBS=-lncurses

make SHLIB_LIBS=-lncurses install
mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-6.3

cd ..
rm -rf readline-6.3

#bash

tar xf bash-4.3.30.tar.gz

cd bash-4.3.30

patch -Np1 -i ../bash-4.3.30-upstream_fixes-1.patch


./configure --prefix=/usr                    \
            --bindir=/bin                    \
            --docdir=/usr/share/doc/bash-4.3.30 \
            --without-bash-malloc            \
            --with-installed-readline

make -j8

make install

cd ..
rm -rf bash-4.3.30

exec /bin/bash --login +h
