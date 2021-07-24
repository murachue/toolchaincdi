# ref: ArchLinux User Repository: m68k-elf-binutils, m68k-elf-gcc-bootstrap, m68k-elf-newlib
FROM ubuntu:20.04 AS build
RUN apt update && \
  DEBIAN_FRONTEND="noninteractive" apt install --no-install-recommends -y build-essential autoconf automake libtool gettext bison flex manpages-dev wget git texinfo zlib1g-dev ca-certificates

WORKDIR /work
RUN git clone --depth=1 -b binutils-2_35 https://github.com/murachue/binutils-gdb binutils-src && \
  git clone --depth=1 -b 11.1.0-os9 https://github.com/murachue/gcc gcc-src && \
  git clone --depth=1 -b newlib-4.1.0-os9 https://github.com/murachue/newlib-cygwin newlib-src && \
  wget http://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.xz http://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz http://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz && \
  tar xf mpfr-4.1.0.tar.xz && mv mpfr-4.1.0 gcc-src/mpfr && \
  tar xf mpc-1.2.1.tar.gz && mv mpc-1.2.1 gcc-src/mpc && \
  tar xf gmp-6.2.1.tar.xz && mv gmp-6.2.1 gcc-src/gmp && \
  mkdir -p /work/root

WORKDIR /work/binutils-build
RUN ../binutils-src/configure --target=m68k-elfos9 --prefix=/usr --disable-multilib --with-cpu=68000 --disable-nls --disable-gdb --enable-install-libbfd --disable-libctf && \
  make -j$(grep -c ^processor /proc/cpuinfo) && \
  mkdir -p /work/binutils-root/usr && \
  make prefix=/work/binutils-root/usr install && \
  cp -r /work/binutils-root/usr /work/root/ && \
  cp -r /work/binutils-root/usr /

WORKDIR /work/gcc-bootstrap-build
RUN CFLAGS_FOR_TARGET="-mpcrel -ma6rel -mbsrw" ../gcc-src/configure --prefix=/usr --target=m68k-elfos9 --enable-languages="c" --disable-multilib --with-cpu=68000 --with-system-zlib --with-libgloss --without-headers --disable-shared --disable-nls && \
  make all-gcc all-target-libgcc -j$(grep -c ^processor /proc/cpuinfo) && \
  mkdir -p /work/gcc-bootstrap-root && \
  make DESTDIR=/work/gcc-bootstrap-root install-gcc install-target-libgcc && \
  strip /work/gcc-bootstrap-root/usr/bin/* && \
  cp -r /work/gcc-bootstrap-root/usr /work/root/ && \
  cp -r /work/gcc-bootstrap-root/usr /

WORKDIR /work/newlib-build
RUN CFLAGS_FOR_TARGET="-Os -g -mpcrel -ma6rel -ffunction-sections -fdata-sections -fomit-frame-pointer -ffast-math" ../newlib-src/configure --target=m68k-elfos9 --prefix=/usr --disable-newlib-supplied-syscalls --disable-multilib --with-cpu=68000 --disable-nls && \
  make -j$(grep -c ^processor /proc/cpuinfo) && \
  mkdir -p /work/newlib-root && \
  DESTDIR=/work/newlib-root/ make install && \
  cp -r /work/newlib-root/usr / && \
  cp -r /work/newlib-root/usr /work/root/

FROM ubuntu:20.04
COPY --from=build /work/root/usr /usr/
