#!/bin/bash -e

if [ -d bin ]; then
  make clean
fi

if [ -e /etc/os-release ]; then
  source /etc/os-release
  VERSION_ID=${VERSION_ID%".04"} # only keep integer part of ubuntu versions
  VERSION_ID=${VERSION_ID%".10"} # non LTS version differences ignored
else
  VERSION_ID=0
  ID=unknown
fi

if [ "$ID" = "ubuntu" ] && [ $VERSION_ID -ge 19 ]; then
  export EXTRA_CPPFLAGS="-mshstk"
fi

make CC=gcc
bin/sljit_test -s

case $ID in
  ubuntu|debian|redhat|centos|fedora)
    ARCH=$(uname -m)
    if [ $? -eq 0 ] && [ "$ARCH" != "x86_64" ]; then
      exit 0
    fi
    ;;
  *)
    exit 0
esac

make clean
if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
  # only do 32-bit as other architectures are custom
  make CC="gcc -m32" sljit_test
  bin/sljit_test -s
else
  unset EXTRA_CPPFLAGS

  make CROSS_COMPILER=aarch64-linux-gnu-gcc sljit_test
  qemu-aarch64-static -L /usr/aarch64-linux-gnu bin/sljit_test -s

  make clean
  make CROSS_COMPILER=arm-linux-gnueabihf-gcc sljit_test
  qemu-arm-static -L /usr/arm-linux-gnueabihf bin/sljit_test -s

  make clean
  make CROSS_COMPILER="arm-linux-gnueabihf-gcc -marm" sljit_test
  qemu-arm-static -L /usr/arm-linux-gnueabihf bin/sljit_test -s

  make clean
  make CROSS_COMPILER="arm-linux-gnueabihf-gcc -march=armv4 -marm" sljit_test
  qemu-arm-static -L /usr/arm-linux-gnueabihf bin/sljit_test -s

  if [ $VERSION_ID -ne 19 ]; then
    make clean
    make CROSS_COMPILER=mips64el-linux-gnuabi64-gcc sljit_test
    qemu-mips64el-static -L /usr/mips64el-linux-gnuabi64 bin/sljit_test -s

    make clean
    make CROSS_COMPILER=mips-linux-gnu-gcc sljit_test
# requires qemu >= 3.1.0 (debian >= 10) or qemu <= 2.5.0 (ubuntu 16.04)
# segfaults in debian 9 and ubuntu 18.04
    if [[ ("$ID" = "ubuntu" && ( $VERSION_ID -eq 16 || $VERSION_ID -eq 20 )) ||
          ("$ID" = "debian" && $VERSION_ID -eq 10 ) ]]; then
      qemu-mips-static -L /usr/mips-linux-gnu bin/sljit_test -s
    fi
  fi

  # require workaround for debian multiarch gcc bug #955345
  make clean
  make CROSS_COMPILER="sparc64-linux-gnu-gcc -m32 -static" sljit_test
  qemu-sparc32plus-static -L /usr/sparc64-linux-gnu bin/sljit_test -s

  make clean
  make CROSS_COMPILER=powerpc64le-linux-gnu-gcc sljit_test
# requires qemu > 2.5.0 and a fix for a bug that might be included in 4.2.0
# throws invalid instruction in ubuntu 16.04
# fails test54 case 19 in ubuntu 19 and debian stable because of NaN bug
  if [[ ("$ID" = "ubuntu" && $VERSION_ID -eq 16) ||
        ("$ID" = "debian" && $VERSION_ID -eq 10) ]]; then
    :
  else
    qemu-ppc64le-static -L /usr/powerpc64le-linux-gnu bin/sljit_test -s
  fi

  make clean
  make CROSS_COMPILER=powerpc-linux-gnu-gcc sljit_test
# requires qemu >= 4.2.0 or qemu <= 2.5.0 (ubuntu 16.04)
# segfaults in debian 9 and ubuntu 18.04
# fails test54 case 18 in debian 10 and ubuntu 18.04 thru 19.10 because of NaN
  if [[ ($VERSION_ID -eq 16 || $VERSION_ID -ge 20) &&
        "$ID" = "ubuntu" ]]; then
    qemu-ppc-static -L /usr/powerpc-linux-gnu bin/sljit_test -s
  fi
fi
