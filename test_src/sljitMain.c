/*
 *    Stack-less Just-In-Time compiler
 *
 *    Copyright 2009-2010 Zoltan Herczeg (hzmester@freemail.hu). All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 *   1. Redistributions of source code must retain the above copyright notice, this list of
 *      conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright notice, this list
 *      of conditions and the following disclaimer in the documentation and/or other materials
 *      provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDER(S) OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef SLJIT_TEST_DEVEL

/*
 * cc -Wall -Wextra -DSLJIT_CONFIG_AUTO -DSLJIT_TEST_DEVEL -DHAVE_LIBCAPSTONE -DSLJIT_SINGLE_THREADED -DSLJIT_UTIL_GLOBAL_LOCK=0 -DSLJIT_UTIL_STACK=0 -Isljit_src -o bin/sljit_devtest -lcapstone sljit_src/sljitLir.c test_src/sljitMain.c
 */

#include "sljitLir.h"

#include <stdio.h>

#ifdef SLJIT_64BIT_ARCHITECTURE
#ifdef _WIN32
#define SLJIT_PRINT_X	"016llx"
#else
#define SLJIT_PRINT_X	"016lx"
#endif /* windows */
#else
#define SLJIT_PRINT_X	"08x"
#endif

#ifdef HAVE_LIBCAPSTONE
#include <capstone/capstone.h>

static int disassemble_flag;

#if (defined SLJIT_CONFIG_X86_64 && SLJIT_CONFIG_X86_64)
#define CS_ARCH	CS_ARCH_X86
#define CS_MODE	CS_MODE_64
#elif (defined SLJIT_CONFIG_X86_32 && SLJIT_CONFIG_X86_32)
#define CS_ARCH	CS_ARCH_X86
#define CS_MODE	CS_MODE_32
#elif (defined SLJIT_CONFIG_ARM_64 && SLJIT_CONFIG_ARM_64)
#define CS_ARCH	CS_ARCH_ARM64
#ifdef SLJIT_BIG_ENDIAN
#define CS_MODE	CS_MODE_BIG_ENDIAN
#endif
#elif (defined SLJIT_CONFIG_ARM && SLJIT_CONFIG_ARM)
#define CS_ARCH	CS_ARCH_ARM
#ifdef SLJIT_BIG_ENDIAN
#if (defined SLJIT_CONFIG_ARM_THUMB2 && SLJIT_CONFIG_ARM_THUMB2)
#define CS_MODE	CS_MODE_THUMB | CS_MODE_BIG_ENDIAN
#else
#define CS_MODE	CS_MODE_ARM | CS_MODE_BIG_ENDIAN
#endif /* thumb */
#else /* little endian */
#if (defined SLJIT_CONFIG_ARM_THUMB2 && SLJIT_CONFIG_ARM_THUMB2)
#define CS_MODE	CS_MODE_THUMB
#else
#define CS_MODE	CS_MODE_ARM
#endif /* endianess */
#endif /* thumb */
#elif (defined SLJIT_CONFIG_PPC_64 && SLJIT_CONFIG_PPC_64)
#define CS_ARCH	CS_ARCH_PPC
#ifdef SLJIT_BIG_ENDIAN
#define CS_MODE	CS_MODE_64 | CS_MODE_BIG_ENDIAN
#else
#define CS_MODE	CS_MODE_64
#endif /* endianess */
#elif (defined SLJIT_CONFIG_PPC_32 && SLJIT_CONFIG_PPC_32)
#define CS_ARCH	CS_ARCH_PPC
#ifdef SLJIT_BIG_ENDIAN
#define CS_MODE	CS_MODE_BIG_ENDIAN
#endif /* big endian */
#elif (defined SLJIT_CONFIG_MIPS_64 && SLJIT_CONFIG_MIPS_64)
#define CS_ARCH	CS_ARCH_MIPS
#ifdef SLJIT_BIG_ENDIAN
#define CS_MODE	CS_MODE_MIPS64 | CS_MODE_BIG_ENDIAN
#else
#define CS_MODE	CS_MODE_MIPS64
#endif /* endianess */
#elif (defined SLJIT_CONFIG_MIPS_32 && SLJIT_CONFIG_MIPS_32)
#define CS_ARCH	CS_ARCH_MIPS
#if (defined SLJIT_MIPS_REV && SLJIT_MIPS_REV >= 6)
#ifdef SLJIT_BIG_ENDIAN
#define CS_MODE	CS_MODE_MIPS32R6 | CS_MODE_BIG_ENDIAN
#else
#define CS_MODE	CS_MODE_MIPS32R6
#endif /* endianess */
#else /* < R6 */
#ifdef SLJIT_BIG_ENDIAN
#define CS_MODE	CS_MODE_MIPS32 | CS_MODE_BIG_ENDIAN
#else
#define CS_MODE	CS_MODE_MIPS32
#endif /* endianess */
#endif /* >= R6 */
#elif (defined SLJIT_CONFIG_SPARC_32 && SLJIT_CONFIG_SPARC_32)
#define CS_ARCH	CS_ARCH_SPARC
#define CS_MODE	CS_MODE_BIG_ENDIAN
#else
#error "CPU architecture not supported"
#endif
#ifndef CS_MODE
#define CS_MODE	CS_MODE_LITTLE_ENDIAN
#endif

static int disassemble(void *code, size_t size, sljit_uw base)
{
	csh handle;
	cs_insn *insn;
	size_t count, i, b;

	if (cs_open(CS_ARCH, CS_MODE, &handle) != CS_ERR_OK)
		return -1;

	count = cs_disasm(handle, code, size, base, 0, &insn);

	if (count > 0)
		printf("disassembled:\n\n");
	for (i = 0; i < count; i++) {
		printf("0x%" PRIx64 ":\t", insn[i].address);
		for (b = 0; b < insn[i].size; b++) {
			if (b)
				putchar(' ');
			printf("%02x", insn[i].bytes[b]);
		}
#if (defined SLJIT_CONFIG_X86 && SLJIT_CONFIG_X86)
		while (b++ < 8)
			printf("   ");
#endif
		printf("\t%s\t%s\n", insn[i].mnemonic, insn[i].op_str);
	}

	cs_free(insn, count);

	return (count) ? 0 : -1;
}
#endif

static void error(const char* str)
{
	printf("An error occurred: %s\n", str);
	exit(-1);
}

static void usage(const char *name)
{
	printf("%s: debug code in devel()\n", name);
#ifdef HAVE_LIBCAPSTONE
	printf("\n");
	printf("\t-d\tdissassemble generated code\n");
#endif
	exit(0);
}

union executable_code {
	void* code;
	sljit_sw (SLJIT_FUNC *func)(sljit_sw* a);
};
typedef union executable_code executable_code;

static void devel(void)
{
	executable_code code;

	struct sljit_compiler *compiler = sljit_create_compiler(NULL);
	sljit_uw base;
	size_t size;
	sljit_sw buf[4];

	if (!compiler)
		error("Not enough memory");
	buf[0] = 5;
	buf[1] = 12;
	buf[2] = 0;
	buf[3] = 0;

#if (defined SLJIT_VERBOSE && SLJIT_VERBOSE)
	sljit_compiler_verbose(compiler, stdout);
#endif

	sljit_emit_enter(compiler, 0, SLJIT_ARG1(SW), 1, 1, 0, 0, 0);

	sljit_emit_return(compiler, SLJIT_MOV, SLJIT_RETURN_REG, 0);

	code.code = sljit_generate_code(compiler);
#if (defined SLJIT_VERBOSE && SLJIT_VERBOSE)
	printf("\n");
#endif
	size = sljit_get_generated_code_size(compiler);
	sljit_free_compiler(compiler);

	base = SLJIT_FUNC_OFFSET(code.code);
	printf("%zu bytes of code at: %" SLJIT_PRINT_X "\n", size, base);
#ifdef HAVE_LIBCAPSTONE
	if (disassemble_flag) {
		disassemble(code.code, size, base);
		printf("\n");
	}
#endif
	printf("Function returned with %ld\n", (long)code.func((sljit_sw*)buf));
	printf("buf[0] = %ld\n", (long)buf[0]);
	printf("buf[1] = %ld\n", (long)buf[1]);
	printf("buf[2] = %ld\n", (long)buf[2]);
	printf("buf[3] = %ld\n", (long)buf[3]);
	sljit_free_code(code.code);
}
#else
int sljit_test(int argc, char* argv[]);
#endif

int main(int argc, char* argv[])
{
#ifdef SLJIT_TEST_DEVEL
	if (argc > 1 && argv[1][0] == '-') {
		if (argc != 2 || argv[1][1] != 'd' || argv[1][2] != 0)
			usage(argv[0]);
		else
			disassemble_flag = 1;
	}
	devel();
	return 0;
#else
	return sljit_test(argc, argv);
#endif
}
