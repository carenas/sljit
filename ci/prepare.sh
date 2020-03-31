#!/bin/sh

# assumes build host = amd64 and either ubuntu >= 16.04, debian > 8 or fedora

if [ -e /etc/os-release ]; then
  . /etc/os-release
else
  ID=unknown
fi

USERID=$(id -u)
type sudo
if [ $? -eq 0 ] && [ $USERID -gt 0 ]; then
  SUDO=sudo
else
  echo "error: need root privileges"
  exit 1
fi

case $ID in
  debian|ubuntu)
    $SUDO apt-get update
    $SUDO apt-get install -y gcc make
    $SUDO apt-get install -y qemu-user-static
    if [ "$VERSION_ID" != "19.10" ]; then
      $SUDO apt-get install -y gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-mips-linux-gnu gcc-mips64el-linux-gnuabi64 gcc-multilib-sparc64-linux-gnu gcc-powerpc-linux-gnu gcc-powerpc64le-linux-gnu
    else
      # mips in ubuntu 19.10 is beyond repair
      $SUDO apt-get install -y gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf
      $SUDO apt-get install -y gcc-multilib-sparc64-linux-gnu
      $SUDO apt-get install -y gcc-powerpc-linux-gnu gcc-powerpc64le-linux-gnu
    fi
    ;;
  fedora)
    $SUDO dnf -y update
    $SUDO dnf -y install gcc make
    $SUDO dnf -y install qemu-user-static
    $SUDO dnf -y install glibc-devel.i686
    ;;
  *)
    exit 1
    ;;
esac
