set -e

#this script begins at building the temporary tool chain

tar xf binutils-2.25.tar.bz2

#binutils

mkdir -v binutils-build
cd binutils-build

../binutils-2.25/configure     \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror

make -j8 
make -j8 install

cd ..
rm -rf binutils-build binutils-2.25

#gcc pass 1

tar xf gcc-4.9.2.tar.bz2

cd gcc-4.9.2

tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

mkdir -v ../gcc-build
cd ../gcc-build

../gcc-4.9.2/configure                               \
    --target=$LFS_TGT                                \
    --prefix=/tools                                  \
    --with-sysroot=$LFS                              \
    --with-newlib                                    \
    --without-headers                                \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --disable-nls                                    \
    --disable-shared                                 \
    --disable-multilib                               \
    --disable-decimal-float                          \
    --disable-threads                                \
    --disable-libatomic                              \
    --disable-libgomp                                \
    --disable-libitm                                 \
    --disable-libquadmath                            \
    --disable-libsanitizer                           \
    --disable-libssp                                 \
    --disable-libvtv                                 \
    --disable-libcilkrts                             \
    --disable-libstdc++-v3                           \
    --enable-languages=c,c++

make -j8

make -j8 install

cd ..

rm -rf gcc-build gcc-4.9.2


#linux api-headers

tar xf linux-3.19.tar.xz

cd linux-3.19

make -j8 mrproper

make -j8 INSTALL_HDR_PATH=dest headers_install

cp -rv dest/include/* /tools/include

cd ..

rm -rf linux-3.19.tar.xz

#glibc

tar xf glibc-2.21.tar.xz

cd glibc-2.21

sed -e '/ia32/s/^/1:/' \
    -e '/SSE2/s/^1://' \
    -i  sysdeps/i386/i686/multiarch/mempcpy_chk.S

mkdir -v ../glibc-build
cd ../glibc-build

../glibc-2.21/configure                             \
      --prefix=/tools                               \
      --host=$LFS_TGT                               \
      --build=$(../glibc-2.21/scripts/config.guess) \
      --disable-profile                             \
      --enable-kernel=2.6.32                        \
      --with-headers=/tools/include                 \
      libc_cv_forced_unwind=yes                     \
      libc_cv_ctors_header=yes                      \
      libc_cv_c_cleanup=yes

make -j8

make -j8 install

cd ..

rm -rf glibc-2.21 glibc-build


#checking sanity of tool chain

echo 'Checking tool chain sanity'
echo 'Output below should be [Requesting program interpreter: /tools/lib/ld-linux.so.2]'

echo 'main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'

read -rsp $'Press any key to continue...\n' -n1 key
rm -v dummy.c a.out

#libstdc++

tar xf gcc-4.9.2.tar.bz2

mkdir -pv gcc-build
cd gcc-build

../gcc-4.9.2/libstdc++-v3/configure \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-shared                \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/4.9.2

make -j8

make -j8 install

cd ..

rm -rf gcc-build gcc-4.9.2

#binutils pass 2

tar xf binutils-2.25.tar.bz2

mkdir -v binutils-build
cd binutils-build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../binutils-2.25/configure     \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot

make -j8

make -j8 install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

cd ..

rm -rf binutils-build binutils-2.25

#gcc pass 2

tar xf gcc-4.9.2

cd gcc-4.9.2

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h



for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done



tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc


mkdir -v ../gcc-build
cd ../gcc-build

CC=$LFS_TGT-gcc                                      \
CXX=$LFS_TGT-g++                                     \
AR=$LFS_TGT-ar                                       \
RANLIB=$LFS_TGT-ranlib                               \
../gcc-4.9.2/configure                               \
    --prefix=/tools                                  \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --enable-languages=c,c++                         \
    --disable-libstdcxx-pch                          \
    --disable-multilib                               \
    --disable-bootstrap                              \
    --disable-libgomp


make -j8
make -j8 install

ln -sv gcc /tools/bin/cc

cd ..

rm -rf gcc-build gcc-4.9.2


#checking sanity of tool chain

echo 'Checking tool chain sanity'
echo 'Output below should be [Requesting program interpreter: /tools/lib/ld-linux.so.2]'

echo 'main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'

read -rsp $'Press any key to continue...\n' -n1 key
rm -v dummy.c a.out


#tcl

tar xf tcl8.6.3-src.tar.gz

cd tcl8.6.3/unix

./configure --prefix=/tools

make -j8

make -j8 install

chmod -v u+w /tools/lib/libtcl8.6.so

make -j8 install-private-headers

ln -sv tclsh8.6 /tools/bin/tclsh

cd ../..
rm -rf tcl8.6.3

#expect

tar xf expect5.45.tar.gz
cd expect5.45

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include

make -j8
make -j8 SCRIPTS="" install

cd ..
rm -rf expect5.45

#dejagnu-1.5.2.tar.gz

tar xf dejagnu-1.5.2.tar.gz
cd dejagnu-1.5.2

./configure --prefix=/tools
make -j8 install

cd ..
rm -rf dejagnu-1.5.2

#check

tar xf check-0.9.14.tar.gz

cd check-0.9.14

PKG_CONFIG= ./configure --prefix=/tools

make -j8
make -j8 install

cd ..
rm -rf check-0.9.14

#ncurses-5.9.tar.gz

tar xf ncurses-5.9.tar.gz

cd ncurses-5.9

./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite

make -j8
make -j8 install

cd ..
rm -rf ncurses-5.9

#bash-4.3.30.tar.gz

tar xf bash-4.3.30.tar.gz

cd bash-4.3.30

./configure --prefix=/tools --without-bash-malloc

make -j8

make -j8 install

ln -sv bash /tools/bin/sh

cd ..
rm -rf bash-4.3.30

#bzip2-1.0.6.tar.gz

tar xf bzip2-1.0.6.tar.gz

cd bzip2-1.0.6

make -j8

make -j8 PREFIX=/tools install

cd ..
rm -rf bzip2-1.0.6

#coreutils

tar xf coreutils-8.23.tar.xz

cd coreutils-8.23
./configure --prefix=/tools --enable-install-program=hostname

make -j8
make -j8 install

cd ..
rm -rf coreutils-8.23

#diffutils-3.3.tar.xz

tar xf diffutils-3.3.tar.xz

cd diffutils-3.3

./configure --prefix=/tools

make -j8
make -j8 install

cd ..
rm -rf diffutils-3.3

#file-5.22.tar.gz

tar xf file-5.22.tar.gz

cd file-5.22

./configure --prefix=/tools

make -j8 
make -j8 install

cd ..
rm -rf file-5.22

#findutils-4.4.2.tar.gz

tar xf findutils-4.4.2.tar.gz

cd findutils-4.4.2

./configure --prefix=/tools

make -j8
make -j8 install

cd ..
rm -rf findutils-4.4.2

#gawk-4.1.1.tar.xz

tar xf gawk-4.1.1.tar.xz

cd gawk-4.1.1

./configure --prefix=/tools

make -j8
make -j8 install

cd ..
rm -rf gawk-4.1.1

#gettext-0.19.4.tar.xz

tar xf gettext-0.19.4.tar.xz

cd gettext-0.19.4/gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared

make -j8 -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -j8 -C src xgettext


cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

cd ../..
rm -rf gettext-0.19.4

#grep

tar xf grep-2.21.tar.xz

cd grep-2.21
./configure --prefix=/tools
make -j8
make -j8 install

cd ..
rm -rf grep-2.21

#gzip-1.6.tar.xz

tar xf gzip-1.6.tar.xz

cd gzip-1.6

./configure --prefix=/tools

make -j8
make -j8 install

cd ..
rm -rf gzip-1.6

#m4-1.4.17.tar.xz

tar xf m4-1.4.17.tar.xz

cd m4-1.4.17

./configure --prefix=/tools
make -j8
make -j8 install

cd ..
rm -rf m4-1.4.17

#make

tar xf make-4.1.tar.bz2

cd make-4.1

./configure --prefix=/tools --without-guile

make -j8
make -j8 install

cd ..
rm -rf make-4.1

#patch

tar xf patch-2.7.4.tar.xz

cd patch-2.7.4

./configure --prefix=/tools
make -j8
make -j8 install

cd ..
rm -rf patch-2.7.4

#perl

tar xf perl-5.20.2.tar.bz2

cd perl-5.20.2

sh Configure -des -Dprefix=/tools -Dlibs=-lm

make -j8

cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.20.2
cp -Rv lib/* /tools/lib/perl5/5.20.2

cd ..
rm -rf perl-5.20.2

#sed

tar xf sed-4.2.2.tar.bz2

cd sed-4.2.2

./configure --prefix=/tools
make -j8
make -j8 install

cd ..
rm -rf sed-4.2.2


#tar 

tar xf tar-1.28.tar.xz
cd tar-1.28

./configure --prefix=/tools
make -j8 
make -j8 install

cd ..
rm -rf tar-1.28

#texinfo

tar xf texinfo-5.2.tar.xz

cd texinfo-5.2

./configure --prefix=/tools
make -j8
make -j8 install

cd ..
rm -rf texinfo-5.2

#util-linux-2.26.tar.xz

tar xf util-linux-2.26.tar.xz

cd util-linux-2.26

./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""

make -j8
make -j8 install

cd ..
rm -rf util-linux-2.26

#xz-5.2.0.tar.xz

tar xf xz-5.2.0.tar.xz

cd xz-5.2.0

./configure --prefix=/tools
make -j8
make -j8 install

cd ..
rm -rf xz-5.2.0

