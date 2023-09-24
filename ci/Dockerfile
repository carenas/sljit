FROM debian:testing-slim
RUN apt-get update && apt-get -y install \
	gcc make qemu-user-static \
	gcc-aarch64-linux-gnu \
	gcc-arm-linux-gnueabi \
	gcc-arm-linux-gnueabihf \
	gcc-i686-linux-gnu \
	gcc-mips-linux-gnu \
	gcc-mips64-linux-gnuabi64 \
	gcc-mipsel-linux-gnu \
	gcc-mips64el-linux-gnuabi64 \
	gcc-powerpc-linux-gnu \
	gcc-powerpc64-linux-gnu \
	gcc-powerpc64le-linux-gnu \
	gcc-riscv64-linux-gnu \
	gcc-s390x-linux-gnu \
	&& rm -rf /var/lib/apt/lists/*
