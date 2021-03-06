cmake_minimum_required (VERSION 3.10)
project (SZIP_SRC C)

#-----------------------------------------------------------------------------
# Define szip Library
#-----------------------------------------------------------------------------
set (SZIP_SRCS
    ${SZIP_SRC_SOURCE_DIR}/rice.c
    ${SZIP_SRC_SOURCE_DIR}/sz_api.c
    ${SZIP_SRC_SOURCE_DIR}/encoding.c
)

set (SZIP_PUBLIC_HEADERS
    ${SZIP_SRC_SOURCE_DIR}/ricehdf.h
    ${SZIP_SRC_SOURCE_DIR}/szip_adpt.h
    ${SZIP_SRC_SOURCE_DIR}/szlib.h
)

add_library (${SZIP_LIB_TARGET} STATIC ${SZIP_SRCS} ${SZIP_PUBLIC_HEADERS})
#set_target_properties (${SZIP_LIB_TARGET}
#  PROPERTIES
#      LINK_FLAGS "-version-info 2:0:0"
#)
target_include_directories(${SZIP_LIB_TARGET} PRIVATE "${SZIP_SOURCE_DIR};${CMAKE_BINARY_DIR}")
TARGET_C_PROPERTIES (${SZIP_LIB_TARGET} STATIC)
target_link_libraries (${SZIP_LIB_TARGET} PRIVATE ${LINK_LIBS})
SZIP_SET_LIB_OPTIONS (${SZIP_LIB_TARGET} ${SZIP_LIB_NAME} STATIC)
set_target_properties(${SZIP_LIB_TARGET} PROPERTIES
    PUBLIC_HEADER "${SZIP_PUBLIC_HEADERS}"
    LINKER_LANGUAGE C
    INTERFACE_INCLUDE_DIRECTORIES "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>"
)
set_global_variable (SZIP_LIBRARIES_TO_EXPORT ${SZIP_LIB_TARGET})
set (install_targets ${SZIP_LIB_TARGET})

if (BUILD_SHARED_LIBS)
  add_library (${SZIP_LIBSH_TARGET} SHARED ${SZIP_SRCS} ${SZIP_PUBLIC_HEADERS})
#  set_target_properties (${SZIP_LIB_TARGET}
#    PROPERTIES
#        LINK_FLAGS "-version-info 2:0:0"
#  )
  target_include_directories(${SZIP_LIBSH_TARGET} PRIVATE "${SZIP_SOURCE_DIR};${CMAKE_BINARY_DIR}")
  set_target_properties (${SZIP_LIBSH_TARGET} PROPERTIES DEFINE_SYMBOL ${SZIP_LIB_CORENAME}_EXPORTS)
  TARGET_C_PROPERTIES (${SZIP_LIBSH_TARGET} SHARED)
  target_link_libraries (${SZIP_LIBSH_TARGET} PRIVATE ${LINK_LIBS})
  SZIP_SET_LIB_OPTIONS (${SZIP_LIBSH_TARGET} ${SZIP_LIB_NAME} SHARED)
  set_target_properties(${SZIP_LIBSH_TARGET} PROPERTIES
      COMPILE_DEFINITIONS "SZ_BUILT_AS_DYNAMIC_LIB"
      PUBLIC_HEADER "${SZIP_PUBLIC_HEADERS}"
      LINKER_LANGUAGE C
      INTERFACE_INCLUDE_DIRECTORIES "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>"
      INTERFACE_COMPILE_DEFINITIONS SZ_BUILT_AS_DYNAMIC_LIB=1
  )
  if (WIN32)
    set_property (TARGET ${SZIP_LIBSH_TARGET} APPEND PROPERTY COMPILE_DEFINITIONS "SZIP_DLL")
  endif ()
  set_global_variable (SZIP_LIBRARIES_TO_EXPORT "${SZIP_LIBRARIES_TO_EXPORT};${SZIP_LIBSH_TARGET}")
  set (install_targets ${install_targets} ${SZIP_LIBSH_TARGET})
endif ()

#-----------------------------------------------------------------------------
# Add Target(s) to CMake Install for import into other projects
#-----------------------------------------------------------------------------
if (SZIP_EXPORTED_TARGETS)
  if (BUILD_SHARED_LIBS)
    INSTALL_TARGET_PDB (${SZIP_LIBSH_TARGET} ${SZIP_INSTALL_BIN_DIR} libraries)
  endif (BUILD_SHARED_LIBS)
  INSTALL_TARGET_PDB (${SZIP_LIB_TARGET} ${SZIP_INSTALL_BIN_DIR} libraries)

  install (
      TARGETS
          ${install_targets}
      EXPORT
          ${SZIP_EXPORTED_TARGETS}
      LIBRARY DESTINATION ${SZIP_INSTALL_LIB_DIR} COMPONENT libraries
      ARCHIVE DESTINATION ${SZIP_INSTALL_LIB_DIR} COMPONENT libraries
      RUNTIME DESTINATION ${SZIP_INSTALL_BIN_DIR} COMPONENT libraries
      FRAMEWORK DESTINATION ${SZIP_INSTALL_FWRK_DIR} COMPONENT libraries
      PUBLIC_HEADER DESTINATION ${SZIP_INSTALL_INCLUDE_DIR} COMPONENT headers
  )
endif ()
