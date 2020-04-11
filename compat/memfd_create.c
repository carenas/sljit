#if defined(__linux__)
#include <linux/memfd.h>
#ifndef MFD_CLOEXEC
#define MFD_CLOEXEC 0x0001U
#endif

#include <sys/syscall.h>

#ifndef SYS_memfd_create
#error need kernel 3.17 or newer
#else
#ifdef __GLIBC__
#include <gnu/libc-version.h>
#endif

if !defined(__ANDROID__)
/* this also works for MUSL hence why not using a more sane expression */
#if __GLIBC_MINOR__ < 27
#include <unistd.h>
int memfd_create(const char *name, unsigned int flags)
{
       return syscall(SYS_memfd_create, name, flags);
}
#else
int memfd_create(const char *name, unsigned int flags);
#endif /* glibc */
#endif /* ANDROID */
#endif /* kernel */
#endif /* OS */
