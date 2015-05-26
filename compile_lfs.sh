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


