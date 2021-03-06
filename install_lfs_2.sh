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

