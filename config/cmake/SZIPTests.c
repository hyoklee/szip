#define SIMPLE_TEST(x) int main(){ x; return 0; }

#ifdef VSNPRINTF_WORKS
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int test_vsnprintf(const char *fmt,...)
{
    va_list     ap;
    char *s = malloc(16);
    int ret;

    va_start(ap, fmt);
    ret=vsnprintf(s,16,"%s",ap);
    va_end(ap);

    return(ret!=42 ? 1 : 0);
}

int main(void)
{
    return(test_vsnprintf("%s","A string that is longer than 16 characters"));
}
#endif

#ifdef STDC_HEADERS
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <float.h>
int main() { return 0; }
#endif /* STDC_HEADERS */


#ifdef HAVE_DEFAULT_SOURCE
/* check default source */
#include <features.h>

int
main(void)
{
#ifdef __GLIBC_PREREQ
  return __GLIBC_PREREQ(2,19);
#else
  return 0;
#endif /* defined(__GLIBC_PREREQ) */
}
#endif

#ifdef TEST_LFS_WORKS
/* Return 0 when LFS is available and 1 otherwise.  */
#define _LARGEFILE_SOURCE
#define _LARGEFILE64_SOURCE
#define _LARGE_FILES
#define _FILE_OFFSET_BITS 64
#include <sys/types.h>
#include <sys/stat.h>
#include <assert.h>
#include <stdio.h>

int main(int argc, char **argv)
{
  /* check that off_t can hold 2^63 - 1 and perform basic operations... */
#define OFF_T_64 (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))
  if (OFF_T_64 % 2147483647 != 1)
    return 1;

  /* stat breaks on SCO OpenServer */
  struct stat buf;
  stat( argv[0], &buf );
  if (!S_ISREG(buf.st_mode))
    return 2;

  FILE *file = fopen( argv[0], "r" );
  off_t offset = ftello( file );
  fseek( file, offset, SEEK_CUR );
  fclose( file );
  return 0;
}
#endif
