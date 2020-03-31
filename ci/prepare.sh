#!/bin/sh

# assumes build host = amd64/x86_64 and either ubuntu >= 16.04, debian > 8
# fedora/centos/redhat are minimally supported by allowing multilib validation

if [ -e /etc/os-release ]; then
  . /etc/os-release
else
  ID=unknown
fi

ARCH=$(uname -m)
if [ $? -eq 0 ] && [ "$ARCH" != "x86_64" ]; then
  exit 0
fi

USERID=$(id -u)
if [ $? -eq 0 ] && [ $USERID -gt 0 ]; then
  type sudo >/dev/null
  if [ $? -eq 0 ]; then
    SUDO=sudo
  else
    echo "error: need root privileges"
    exit 1
  fi
fi

case $ID in
  debian|ubuntu)
    $SUDO apt-get update
    $SUDO apt-get install -y gcc make
    $SUDO apt-get install -y qemu-user-static
    $SUDO apt-get install -y gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf
    $SUDO apt-get install -y gcc-multilib-sparc64-linux-gnu
    if [ "$VERSION_ID" != "19.10" ]; then
      # mips in ubuntu 19.10 is beyond repair
      $SUDO apt-get install -y gcc-mips-linux-gnu gcc-mips64el-linux-gnuabi64
    fi
    $SUDO apt-get install -y gcc-powerpc-linux-gnu gcc-powerpc64le-linux-gnu
    ;;
  redhat|centos)
    $SUDO dnf -y update
    $SUDO dnf -y install gcc make
    $SUDO dnf -y install glibc-devel.i686
    ;;
  fedora)
    $SUDO dnf -y update
    $SUDO dnf -y install gcc make
    $SUDO dnf -y install glibc-devel.i686
    ;;
  *)
    exit 1
    ;;
esac
