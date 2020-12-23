#-----------------------------------------------------------------------------
# Include all the necessary files for macros
#-----------------------------------------------------------------------------
include (CheckFunctionExists)
include (CheckIncludeFile)
include (CheckIncludeFiles)
include (CheckLibraryExists)
include (CheckSymbolExists)
include (CheckTypeSize)
include (CheckVariableExists)
if (CMAKE_CXX_COMPILER_LOADED)
  include (CheckIncludeFileCXX)
  include (TestForSTDNamespace)
endif ()

#-----------------------------------------------------------------------------
# APPLE/Darwin setup
#-----------------------------------------------------------------------------
if (APPLE)
  list (LENGTH CMAKE_OSX_ARCHITECTURES ARCH_LENGTH)
  if (ARCH_LENGTH GREATER 1)
    set (CMAKE_OSX_ARCHITECTURES "" CACHE STRING "" FORCE)
    message (FATAL_ERROR "Building Universal Binaries on OS X is NOT supported by the SZIP project. This is"
    "due to technical reasons. The best approach would be build each architecture in separate directories"
    "and use the 'lipo' tool to combine them into a single executable or library. The 'CMAKE_OSX_ARCHITECTURES'"
    "variable has been set to a blank value which will build the default architecture for this system.")
  endif ()
  set (SZIP_AC_APPLE_UNIVERSAL_BUILD 0)
endif ()

# Check for Darwin (not just Apple - we also want to catch OpenDarwin)
if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set (SZIP_HAVE_DARWIN 1)
endif ()

# Check for Solaris
if (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    set (SZIP_HAVE_SOLARIS 1)
endif ()

#-----------------------------------------------------------------------------
# This MACRO checks IF the symbol exists in the library and IF it
# does, it appends library to the list.
#-----------------------------------------------------------------------------
set (LINK_LIBS "")
macro (CHECK_LIBRARY_EXISTS_CONCAT LIBRARY SYMBOL VARIABLE)
  CHECK_LIBRARY_EXISTS ("${LIBRARY};${LINK_LIBS}" ${SYMBOL} "" ${VARIABLE})
  if (${VARIABLE})
    set (LINK_LIBS ${LINK_LIBS} ${LIBRARY})
  endif ()
endmacro ()

# ----------------------------------------------------------------------
# WINDOWS Hard code Values
# ----------------------------------------------------------------------
set (WINDOWS)

if (MINGW)
  set (SZIP_HAVE_MINGW 1)
  set (WINDOWS 1) # MinGW tries to imitate Windows
  set (CMAKE_REQUIRED_FLAGS "-DWIN32_LEAN_AND_MEAN=1 -DNOGDI=1")
  set (SZIP_HAVE_WINSOCK2_H 1)
endif ()

if (WIN32 AND NOT MINGW)
  if (NOT UNIX)
    set (WINDOWS 1)
    set (CMAKE_REQUIRED_FLAGS "/DWIN32_LEAN_AND_MEAN=1 /DNOGDI=1")
    if (MSVC)
      set (SZIP_HAVE_VISUAL_STUDIO 1)
    endif ()
  endif ()
endif ()

if (WINDOWS)
  set (SZIP_REQUIRED_LIBRARIES "ws2_32.lib;wsock32.lib")
  set (SZIP_HAVE_WIN32_API 1)
  set (HAVE_STDDEF_H 1)
  set (HAVE_SYS_STAT_H 1)
  set (HAVE_SYS_TYPES_H 1)
  set (HAVE_WINSOCK_H 1)
  set (HAVE_LIBM 1)
  set (HAVE_STRDUP 1)
  set (HAVE_SYSTEM 1)
  set (HAVE_LIBWS2_32 1)
  set (HAVE_LIBWSOCK32 1)
endif ()

# ----------------------------------------------------------------------
# END of WINDOWS Hard code Values
# ----------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Check IF header file exists and add it to the list.
#-----------------------------------------------------------------------------
macro (CHECK_INCLUDE_FILE_CONCAT FILE VARIABLE)
  CHECK_INCLUDE_FILES ("${USE_INCLUDES};${FILE}" ${VARIABLE})
  if (${VARIABLE})
    set (USE_INCLUDES ${USE_INCLUDES} ${FILE})
  endif ()
endmacro ()

#-----------------------------------------------------------------------------
#  Check for the existence of certain header files
#-----------------------------------------------------------------------------
CHECK_INCLUDE_FILE_CONCAT ("unistd.h"        HAVE_UNISTD_H)
CHECK_INCLUDE_FILE_CONCAT ("sys/stat.h"      HAVE_SYS_STAT_H)
CHECK_INCLUDE_FILE_CONCAT ("sys/types.h"     HAVE_SYS_TYPES_H)
CHECK_INCLUDE_FILE_CONCAT ("stddef.h"        HAVE_STDDEF_H)
CHECK_INCLUDE_FILE_CONCAT ("stdint.h"        HAVE_STDINT_H)
CHECK_INCLUDE_FILE_CONCAT ("stdarg.h"        HAVE_STDARG_H)

# IF the c compiler found stdint, check the C++ as well. On some systems this
# file will be found by C but not C++, only do this test IF the C++ compiler
# has been initialized (e.g. the project also includes some c++)
if (HAVE_STDINT_H AND CMAKE_CXX_COMPILER_LOADED)
  CHECK_INCLUDE_FILE_CXX ("stdint.h" HAVE_STDINT_H_CXX)
  if (NOT HAVE_STDINT_H_CXX)
    set (HAVE_STDINT_H "" CACHE INTERNAL "Have includes HAVE_STDINT_H")
    set (USE_INCLUDES ${USE_INCLUDES} "stdint.h")
  endif ()
endif ()

# Windows
if (NOT CYGWIN)
  CHECK_INCLUDE_FILE_CONCAT ("winsock2.h"      HAVE_WINSOCK_H)
endif ()

CHECK_INCLUDE_FILE_CONCAT ("string.h"        HAVE_STRING_H)
CHECK_INCLUDE_FILE_CONCAT ("strings.h"       HAVE_STRINGS_H)
CHECK_INCLUDE_FILE_CONCAT ("stdlib.h"        HAVE_STDLIB_H)
CHECK_INCLUDE_FILE_CONCAT ("memory.h"        HAVE_MEMORY_H)
CHECK_INCLUDE_FILE_CONCAT ("dlfcn.h"         HAVE_DLFCN_H)
CHECK_INCLUDE_FILE_CONCAT ("fcntl.h"         HAVE_FCNTL_H)
CHECK_INCLUDE_FILE_CONCAT ("inttypes.h"      HAVE_INTTYPES_H)

#-----------------------------------------------------------------------------
#  Check for the math library "m"
#-----------------------------------------------------------------------------
if (MINGW OR NOT WINDOWS)
  CHECK_LIBRARY_EXISTS_CONCAT ("m" ceil     HAVE_LIBM)
  CHECK_LIBRARY_EXISTS_CONCAT ("ws2_32" WSAStartup  HAVE_LIBWS2_32)
  CHECK_LIBRARY_EXISTS_CONCAT ("wsock32" gethostbyname HAVE_LIBWSOCK32)
endif ()

# For other tests to use the same libraries
set (SZIP_REQUIRED_LIBRARIES ${SZIP_REQUIRED_LIBRARIES} ${LINK_LIBS})

set (USE_INCLUDES "")
if (WINDOWS)
  set (USE_INCLUDES ${USE_INCLUDES} "windows.h")
endif ()

# For other other specific tests, use this MACRO.
macro (SZIP_FUNCTION_TEST OTHER_TEST)
  if (NOT DEFINED ${OTHER_TEST})
    set (MACRO_CHECK_FUNCTION_DEFINITIONS "-D${OTHER_TEST} ${CMAKE_REQUIRED_FLAGS}")
    set (OTHER_TEST_ADD_LIBRARIES)
    if (SZIP_REQUIRED_LIBRARIES)
      set (OTHER_TEST_ADD_LIBRARIES "-DLINK_LIBRARIES:STRING=${SZIP_REQUIRED_LIBRARIES}")
    endif ()

    foreach (def ${SZIP_EXTRA_TEST_DEFINITIONS})
      set (MACRO_CHECK_FUNCTION_DEFINITIONS "${MACRO_CHECK_FUNCTION_DEFINITIONS} -D${def}=${${def}}")
    endforeach ()

    foreach (def
        HAVE_UNISTD_H
        HAVE_SYS_TYPES_H
    )
      if ("${def}")
        set (MACRO_CHECK_FUNCTION_DEFINITIONS "${MACRO_CHECK_FUNCTION_DEFINITIONS} -D${def}")
      endif ()
    endforeach ()

    if (LARGEFILE)
      set (MACRO_CHECK_FUNCTION_DEFINITIONS
          "${MACRO_CHECK_FUNCTION_DEFINITIONS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE"
      )
    endif ()

    #message (STATUS "Performing ${OTHER_TEST}")
    try_compile (${OTHER_TEST}
        ${CMAKE_BINARY_DIR}
        ${SZIP_RESOURCES_DIR}/SZIPTests.c
        CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=${MACRO_CHECK_FUNCTION_DEFINITIONS}
        "${OTHER_TEST_ADD_LIBRARIES}"
        OUTPUT_VARIABLE OUTPUT
    )
    if (${OTHER_TEST})
      set (${OTHER_TEST} 1 CACHE INTERNAL "Other test ${FUNCTION}")
      message (STATUS "Performing Other Test ${OTHER_TEST} - Success")
    else ()
      message (STATUS "Performing Other Test ${OTHER_TEST} - Failed")
      set (${OTHER_TEST} "" CACHE INTERNAL "Other test ${FUNCTION}")
      file (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
          "Performing Other Test ${OTHER_TEST} failed with the following output:\n"
          "${OUTPUT}\n"
      )
    endif ()
  endif ()
endmacro ()

#-----------------------------------------------------------------------------
SZIP_FUNCTION_TEST (STDC_HEADERS)
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  Check for large file support
#-----------------------------------------------------------------------------

# The linux-lfs option is deprecated.
set (LINUX_LFS 0)

set (SZIP_EXTRA_C_FLAGS)
set (SZIP_EXTRA_FLAGS)
if (MINGW OR NOT WINDOWS)
  if (SZIP_HAVE_SOLARIS OR SZIP_HAVE_DARWIN)
  # Linux Specific flags
  set (SZIP_EXTRA_FLAGS -D_POSIX_C_SOURCE -D_DEFAULT_SOURCE)
  option (SZIP_ENABLE_LARGE_FILE "Enable support for large (64-bit) files on Linux." ON)
  if (SZIP_ENABLE_LARGE_FILE AND NOT DEFINED TEST_LFS_WORKS_RUN)
    set (msg "Performing TEST_LFS_WORKS")
    if (CMAKE_CROSSCOMPILING)
      set (TEST_LFS_WORKS 1 CACHE INTERNAL ${msg})
      set (LARGEFILE 1)
      set (SZIP_EXTRA_FLAGS ${SZIP_EXTRA_FLAGS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE)
      message (STATUS "${msg} with presets... yes")
    else ()
      try_run (TEST_LFS_WORKS_RUN   TEST_LFS_WORKS_COMPILE
          ${CMAKE_BINARY_DIR}
          ${SZIP_RESOURCES_DIR}/SZIPTests.c
          CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=-DTEST_LFS_WORKS
      )
      if (TEST_LFS_WORKS_COMPILE)
        if (TEST_LFS_WORKS_RUN MATCHES 0)
          set (TEST_LFS_WORKS 1 CACHE INTERNAL ${msg})
          set (LARGEFILE 1)
          set (SZIP_EXTRA_FLAGS ${SZIP_EXTRA_FLAGS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE)
          message (STATUS "${msg}... yes")
        else ()
          set (TEST_LFS_WORKS "" CACHE INTERNAL ${msg})
          message (STATUS "${msg}... no")
          file (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
                "Test TEST_LFS_WORKS Run failed with the following exit code:\n ${TEST_LFS_WORKS_RUN}\n"
          )
        endif ()
      else ()
        set (TEST_LFS_WORKS "" CACHE INTERNAL ${msg})
        message (STATUS "${msg}... no")
        file (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
            "Test TEST_LFS_WORKS Compile failed\n"
        )
      endif ()
    endif ()
  endif ()
  set (CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS} ${SZIP_EXTRA_FLAGS})
  endif ()
endif ()

add_definitions (${SZIP_EXTRA_FLAGS})

#-----------------------------------------------------------------------------
# Check for some functions that are used
#
CHECK_FUNCTION_EXISTS (memset            HAVE_MEMSET)
CHECK_FUNCTION_EXISTS (snprintf          HAVE_SNPRINTF)
CHECK_FUNCTION_EXISTS (system            HAVE_SYSTEM)

CHECK_FUNCTION_EXISTS (vasprintf         HAVE_VASPRINTF)

CHECK_FUNCTION_EXISTS (vsnprintf         HAVE_VSNPRINTF)
if (NOT WINDOWS)
  if (HAVE_VSNPRINTF)
    SZIP_FUNCTION_TEST (VSNPRINTF_WORKS)
  endif ()
endif ()

