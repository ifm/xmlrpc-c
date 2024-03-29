## -*- cmake -*-
project(xmlrpc-c)
include(FindPkgConfig)
include(CheckIncludeFile)
include(CheckFunctionExists)

cmake_minimum_required(VERSION 2.8.8)

if(COMMAND cmake_policy)
  cmake_policy(SET CMP0003 NEW)
endif()

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(XMLRPC_C_VERSION_MAJOR "1"  CACHE STRING "Version (major) of xmlrpc-c")
set(XMLRPC_C_VERSION_MINOR "33" CACHE STRING "Version (minor) of xmlrpc-c")
set(XMLRPC_C_VERSION_POINT "14"  CACHE STRING "Version (point) of xmlrpc-c")

set(XMLRPC_C_VERSION
  "${XMLRPC_C_VERSION_MAJOR}.${XMLRPC_C_VERSION_MINOR}.${XMLRPC_C_VERSION_POINT}"
  CACHE STRING "Version of xmlrpc-c")

set(XMLRPC_C_LIBVERSION "3.${XMLRPC_C_VERSION_MINOR}")
set(XMLRPC_C_SOVERSION  "3")

set(XMLRPC_CXX_LIBVERSION "8.${XMLRPC_C_VERSION_MINOR}")
set(XMLRPC_CXX_SOVERSION  "8")

string(REGEX REPLACE "^0+" "" XMLRPC_C_VERSION_MAJOR_NUM "${XMLRPC_C_VERSION_MAJOR}")
string(REGEX REPLACE "^0+" "" XMLRPC_C_VERSION_MINOR_NUM "${XMLRPC_C_VERSION_MINOR}")
string(REGEX REPLACE "^0+(.)" "\\1" XMLRPC_C_VERSION_POINT_NUM "${XMLRPC_C_VERSION_POINT}")


macro(ensc_set_bool NAME VALUE DESC)
  set(${NAME} ${VALUE} CACHE BOOL ${DESC})
  if(${NAME})
    set(_${NAME} 1)
  else(${NAME})
    set(_${NAME} 0)
  endif(${NAME})
endmacro(ensc_set_bool)

macro(ensc_pkgconfig COMP)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${COMP}.pc.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/${COMP}.pc
    @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${COMP}.pc
    DESTINATION ${pkgconfdir})
endmacro(ensc_pkgconfig)

macro(ensc_pkgconfig_lib TARGET LIBS)
  get_target_property(libtype ${TARGET} TYPE)
  if("${libtype}" STREQUAL "STATIC_LIBRARY")
    list(APPEND ${TARGET}_pkgconfig_libs "${LIBS}")
  endif("${libtype}" STREQUAL "STATIC_LIBRARY")
endmacro(ensc_pkgconfig_lib)

macro(ensc_set_link_exe_flags)
  ## HACK: libwww has broken inter-lib dependencies and '-Wl,--as-needed' fails with it
  if(NOT MUST_BUILD_LIBWWW_CLIENT)
    set_target_properties(${ARGV}
      PROPERTIES
      LINK_FLAGS ${XMLRPC_LINKER_FLAGS})
  endif(NOT MUST_BUILD_LIBWWW_CLIENT)
endmacro(ensc_set_link_exe_flags)

###########
if(WIN32)
  set(MUST_BUILD_CURL_CLIENT     1 CACHE BOOL "Set if Curl client transport shall be built")
  set(MUST_BUILD_WININET_CLIENT  0 CACHE BOOL "Set if WinInet client transport shall be built")
  set(MUST_BUILD_LIBWWW_CLIENT   0 CACHE BOOL "Set if libwww client transport shall be built")
  if(DEFINED MUST_BUILD_WININET_CLIENT)
    ensc_set_bool(MUST_BUILD_WININET_CLIENT 1 "Set if WinInet client transport shall be built")
    set(MUST_BUILD_CLIENT 1)
  endif(DEFINED MUST_BUILD_WININET_CLIENT)
  set(MSVCRT yes)
else()
   ensc_set_bool(MUST_BUILD_WININET_CLIENT 0 "Set to 0 as not needed on unix systems")
endif(WIN32)


set(wininet_srcdir ${xmlrpc-c_SOURCE_DIR}/lib/wininet_transport)

###########
if(DEFINED MUST_BUILD_CURL_CLIENT)
  set(tmp REQUIRED)
else(DEFINED MUST_BUILD_CURL_CLIENT)
  set(tmp)
endif(DEFINED MUST_BUILD_CURL_CLIENT)

find_package(CURL ${tmp})

ensc_set_bool(MUST_BUILD_CURL_CLIENT ${CURL_FOUND} "Set if Curl client transport shall be built")
set(curl_srcdir ${xmlrpc-c_SOURCE_DIR}/lib/curl_transport)

if(MUST_BUILD_CURL_CLIENT)
  set(MUST_BUILD_CLIENT 1)
endif(MUST_BUILD_CURL_CLIENT)

###########
find_program(LIBWWW_CONFIG_EXECUTABLE libwww-config)
if(DEFINED MUST_BUILD_LIBWWW_CLIENT)
  set(tmp ${MUST_BUILD_LIBWWW_CLIENT})
else(DEFINED MUST_BUILD_LIBWWW_CLIENT)
  if(LIBWWW_CONFIG_EXECUTABLE)
    set(tmp 1)
  else(LIBWWW_CONFIG_EXECUTABLE)
    set(tmp 0)
  endif(LIBWWW_CONFIG_EXECUTABLE)
endif(DEFINED MUST_BUILD_LIBWWW_CLIENT)

if(tmp)
  set(MUST_BUILD_CLIENT 1)
  exec_program(${LIBWWW_CONFIG_EXECUTABLE} ARGS --version OUTPUT_VARIABLE LIBWWW_VERSION)
  exec_program(${LIBWWW_CONFIG_EXECUTABLE} ARGS --libs    OUTPUT_VARIABLE LIBWWW_LIBS)
  exec_program(${LIBWWW_CONFIG_EXECUTABLE} ARGS --cflags  OUTPUT_VARIABLE LIBWWW_CFLAGS)
  message(STATUS "Using libwww ${LIBWWW_VERSION} transport")
endif(tmp)
ensc_set_bool(MUST_BUILD_LIBWWW_CLIENT ${tmp} "Set iff LibWWW client transport shall be built")
set(libwww_srcdir ${xmlrpc-c_SOURCE_DIR}/lib/libwww_transport)

############

set(ENABLE_CGI_SERVER      0 CACHE BOOL "Set if CGI server shall be enabled")
set(ENABLE_PSTREAM_SERVER  0 CACHE BOOL "Set if PSTREAM server shall be enabled")
set(ENABLE_EXAMPLES        0 CACHE BOOL "Set if Examples shall be enabled")
set(ENABLE_CPLUSPLUS       1 CACHE BOOL "Set if C++ part shall be enabled")
set(ENABLE_ABYSS_SERVER    0 CACHE BOOL "Set if Abyss server shall be enabled")
set(ENABLE_LIBXML2_BACKEND 0 CACHE BOOL "Set if libxml2 backend shall be used")
set(ENABLE_ABYSS_SERVER    0 CACHE BOOL "Set if abyss server shall be enabled")
set(ENABLE_ABYSS_THREADS   1 CACHE BOOL "Use pthread")

if(ENABLE_LIBXML2_BACKEND)
  pkg_check_modules(LIBXML2 libxml-2.0)

  if(LIBXML2_FOUND)
    set(libxml_pkgconfig libxml-2.0)  # TODO: add more alternative modules
  endif(LIBXML2_FOUND)
endif(ENABLE_LIBXML2_BACKEND)

###########

pkg_check_modules(NCURSES ncurses)
find_library(READLINE readline)

if (MUST_BUILD_LIBWWW_CLIENT OR MUST_BUILD_WININET_CLIENT OR MUST_BUILD_CURL_CLIENT)
  if (NCURSES_FOUND AND READLINE)
    set(BUILD_XMLRPC_PSTREAM 1)
    message(STATUS "Building xmlrpc_pstream tool")
  endif()
  message(STATUS "Tools will be built")
  set(BUILD_TOOLS 1)
else()
  message(STATUS "Tools will not be built")
  set(BUILD_TOOLS 0)
endif()

####  <wchar.h> tests
check_include_file(wchar.h _have_wchar_h)
if(_have_wchar_h)
  set(HAVE_WCHAR_H 1)
else(_have_wchar_h)
  set(HAVE_WCHAR_H 1)
endif(_have_wchar_h)
set(XMLRPC_HAVE_WCHAR   ${HAVE_WCHAR_H})
set(HAVE_WCHAR_H_DEFINE ${HAVE_WCHAR_H})


#######
#for arm64v8 platform builds
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  add_definitions("-fsigned-char")
endif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")

if(WIN32)
	set(LINKER_AS_NEEDED  0 CACHE BOOL "Use the --as-needed linker option")
else(WIN32)
	set(LINKER_AS_NEEDED  1 CACHE BOOL "Use the --as-needed linker option")
endif(WIN32)

if(LINKER_AS_NEEDED)
  set(XMLRPC_LINKER_FLAGS "-Wl,--as-needed")
endif(LINKER_AS_NEEDED)

if(WIN32)
	set(XMLRPC_LINKER_FLAGS "${XMLRPC_LINKER_FLAGS} ws2_32.lib")
endif(WIN32)

try_compile(HAVE_ATTR_UNUSED
  ${CMAKE_BINARY_DIR}/
  ${xmlrpc-c_SOURCE_DIR}/cmake/try-attr.cc
  CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=-DCMAKE_TEST_ATTR=__unused__)

try_compile(VA_LIST_IS_NOT_ARRAY
  ${CMAKE_BINARY_DIR}/
  ${xmlrpc-c_SOURCE_DIR}/cmake/va-list-is-array.c)

if(VA_LIST_IS_NOT_ARRAY)
  set(VA_LIST_IS_ARRAY 0)
  message(STATUS "va_list is not an array")
else(VA_LIST_IS_NOT_ARRAY)
  set(VA_LIST_IS_ARRAY 1)
  message(STATUS "va_list is an array")
endif(VA_LIST_IS_NOT_ARRAY)


if(HAVE_ATTR_UNUSED)
  set(ATTR_UNUSED "__attribute__((__unused__))")
endif(HAVE_ATTR_UNUSED)

if(WIN32)
  set(DIRECTORY_SEPARATOR "\\\\")
  set(THREAD_LIBS "")
else(WIN32)
  set(DIRECTORY_SEPARATOR "/")
  set(THREAD_LIBS "pthread")
  set(THREAD_LIBS_PKGCONFIG "-lpthread")
endif(WIN32)

check_include_file(sys/filio.h  HAVE_SYS_FILIO_H)
check_include_file(sys/ioctl.h  HAVE_SYS_IOCTL_H)
check_include_file(sys/select.h HAVE_SYS_SELECT_H)
check_function_exists(setenv		HAVE_SETENV)
check_function_exists(strcasecmp	HAVE_STRCASECMP)
check_function_exists(_stricmp		HAVE__STRICMP)
check_function_exists(stricmp		HAVE_STRICMP)
check_function_exists(strtoll		HAVE_STRTOLL)
check_function_exists(__strtoll		HAVE___STRTOLL)
check_function_exists(strtoull		HAVE_STRTOULL)
check_function_exists(__strtoull	HAVE___STRTOULL)
check_function_exists(strtoq		HAVE_STRTOQ)
check_function_exists(strtouq		HAVE_STRTOUQ)
check_function_exists(gettimeofday	HAVE_GETTIMEOFDAY)
check_function_exists(setgroups		HAVE_SETGROUPS)
check_function_exists(asprintf		HAVE_ASPRINTF)
check_function_exists(pselect		HAVE_PSELECT)
check_function_exists(wcsncmp		HAVE_WCSNCMP)
check_function_exists(localtime_r	HAVE_LOCALTIME_R)
check_function_exists(gmtime_r		HAVE_GMTIME_R)


configure_file(${xmlrpc-c_SOURCE_DIR}/xmlrpc_config.h.cmake
               ${xmlrpc-c_BINARY_DIR}/xmlrpc_config.h
	       ESCAPE_QUOTES @ONLY)

configure_file(${xmlrpc-c_SOURCE_DIR}/version.h.cmake
               ${xmlrpc-c_BINARY_DIR}/version.h
	       ESCAPE_QUOTES @ONLY)

configure_file(${xmlrpc-c_SOURCE_DIR}/transport_config.h.cmake
               ${xmlrpc-c_BINARY_DIR}/transport_config.h
	       ESCAPE_QUOTES @ONLY)

configure_file(${xmlrpc-c_SOURCE_DIR}/include/xmlrpc-c/config.h.cmake
               ${xmlrpc-c_BINARY_DIR}/include/xmlrpc-c/config.h
	       ESCAPE_QUOTES @ONLY)


include_directories(${xmlrpc-c_SOURCE_DIR}/include)
include_directories(${xmlrpc-c_BINARY_DIR}/include)
include_directories(${xmlrpc-c_SOURCE_DIR}/lib/util/include)
include_directories(${xmlrpc-c_BINARY_DIR})

add_custom_target(dist
  rm -rf _dist && mkdir -p _dist/xmlrpc-c-${XMLRPC_C_VERSION}
  COMMAND cp -a ${xmlrpc-c_SOURCE_DIR}/* _dist/xmlrpc-c-${XMLRPC_C_VERSION}/
  COMMAND cd _dist && tar cjf ../xmlrpc-c-${XMLRPC_C_VERSION}.tar.bz2 xmlrpc-c-${XMLRPC_C_VERSION} --exclude=.git --exclude=CVS --exclude=.svn
  )

set(_lib       lib CACHE STRING "Basename of the library-directory; usually 'lib' or 'lib64' (on multilib archs)")
set(_bin       bin CACHE STRING "Basename of the bin-directory; usually 'bin'")
set(_include   include CACHE STRING "Basename of the include-directory; usually 'include'")
set(prefix     ${CMAKE_INSTALL_PREFIX})
set(libdir     "${prefix}/${_lib}")
set(bindir     "${prefix}/${_bin}")
set(mandir     "${prefix}/share/man")
set(pkgconfdir "${libdir}/pkgconfig")
set(includedir "${prefix}/include")

#############

enable_testing()

#add_subdirectory(test)
add_subdirectory(lib)

if(ENABLE_EXAMPLES)
  add_subdirectory(examples)
endif(ENABLE_EXAMPLES)

add_subdirectory(include)
add_subdirectory(src)

if (BUILD_TOOLS)
  add_subdirectory(tools)
endif()


include (CMakePackageConfigHelpers)
configure_package_config_file (cmake/xmlrpc-c-config.cmake ${CMAKE_CURRENT_BINARY_DIR}/xmlrpc-c-config.cmake
  INSTALL_DESTINATION ${lib}/cmake/xmlrpc-c
  NO_CHECK_REQUIRED_COMPONENTS_MACRO)

write_basic_package_version_file (xmlrpc-c-config-version.cmake 
  VERSION ${XMLRPC_C_LIBVERSION} 
  COMPATIBILITY SameMajorVersion)

export (PACKAGE xmlrpc-c)
export (TARGETS 
  xmlrpc xmlrpc_client xmlrpc_server xmlrpc_xmlparse xmlrpc_util xmlrpc_xmltok xmlrpc_client++ xmlrpc++ xmlrpc_packetsocket
  NAMESPACE xmlrpc-c:: 
  FILE xmlrpc-c-targets.cmake)

install (FILES
  ${CMAKE_CURRENT_BINARY_DIR}/xmlrpc-c-config.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/xmlrpc-c-config-version.cmake 
  DESTINATION ${_lib}/cmake/xmlrpc-c)

install (EXPORT xmlrpc-c-targets 
  NAMESPACE xmlrpc-c:: 
  DESTINATION ${_lib}/cmake/xmlrpc-c)
