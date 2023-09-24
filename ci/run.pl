#!/usr/bin/perl

use warnings;
use strict;

my @platform = (
	{
		sanitize => "1"
	},
	{
		target => "aarch64-linux-gnu",
		sanitize => "atomic",
		emulate => "qemu-aarch64-static"
	},
	{
		target => "arm-linux-gnueabi",
		sanitize => "atomic",
		emulate => "qemu-arm-static"
	},
	{
		target => "arm-linux-gnueabihf",
		sanitize => "atomic",
		emulate => "qemu-arm-static"
	},
	{
		target => "i686-linux-gnu",
		sanitize => "1",
		emulate => "qemu-i386-static"
	},
	{
		target => "mips-linux-gnu",
		emulate => "qemu-mips-static"
	},
	{
		target => "mips64-linux-gnuabi64",
		emulate => "qemu-mips64-static"
	},
	{
		target => "mipsel-linux-gnu",
		emulate => "qemu-mipsel-static"
	},
	{
		target => "mips64el-linux-gnuabi64",
		emulate => "qemu-mips64el-static"
	},
	{
		target => "powerpc-linux-gnu",
		emulate => "qemu-ppc-static"
	},
	{
		target => "powerpc64-linux-gnu",
		sanitize => "atomic",
		emulate => "qemu-ppc64-static"
	},
	{
		target => "powerpc64le-linux-gnu",
		sanitize => "atomic",
		emulate => "qemu-ppc64le-static"
	},
	{
		target => "riscv64-linux-gnu",
		emulate => "qemu-riscv64-static"
	},
	{
		target => "s390x-linux-gnu",
		sanitize => "atomic",
		emulate => "qemu-s390x-static"
	}
);

my @args;
my $fail = 0;

die "broken build" unless system("make -j bin/regex_test") == 0;
$fail++ unless system("bin/regex_test -s") == 0;
foreach(@platform) {
	die "$!" unless system("make -s clean") == 0;
	@args = ("make", "-j");
	my $target = $_ -> {target};
	push @args, "CC=".$_ -> {target}."-gcc" if $target;
	my $sanitize = $_ -> {sanitize};
	if ($sanitize) {
		push @args, "CFLAGS=-fsanitize=undefined";
		push @args, "EXTRA_LIBS=-l".$sanitize if ($sanitize ne "1");
	}
	# workaround
	push @args, "CFLAGS=-static" if defined($target) && ($target =~ /mips64/);
	push @args, "bin/sljit_test";
	$fail++ unless system(@args) == 0;
	my $qemu = $_ -> {emulate};
	if ($qemu) {
		@args = ($qemu, "-L", "/usr/".$target, "bin/sljit_test", "-s");
	} else {
		@args = ("bin/sljit_test", "-s");
	}
	$fail++ unless system(@args) == 0;
}
exit($fail);
