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
