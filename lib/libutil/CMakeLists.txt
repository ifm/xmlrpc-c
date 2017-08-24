# -*- cmake -*-

set( SOURCE_FILES
  asprintf.c
  base64.c
  error.c
  make_printable.c
  memblock.c
  select.c
  sleep.c
  string_number.c
  time.c
  utf8.c
  lock_none.c
  lock_platform.c
)

if(WIN32)
    set ( SOURCE_FILES
        ${SOURCE_FILES}
        lock_windows.c
        )
else(WIN32)
    set( SOURCE_FILES
        ${SOURCE_FILES}
        lock_pthread.c
        )
endif(WIN32)

add_library(xmlrpc_util SHARED
        ${SOURCE_FILES}
  )

set_target_properties(xmlrpc_util
  PROPERTIES
  LINK_FLAGS ${XMLRPC_LINKER_FLAGS}
  VERSION    ${XMLRPC_C_LIBVERSION}
  SOVERSION  ${XMLRPC_C_SOVERSION})

install(TARGETS xmlrpc_util
  RUNTIME DESTINATION ${_bin}
  LIBRARY DESTINATION ${_lib}
  ARCHIVE DESTINATION ${_lib})

ensc_pkgconfig(xmlrpc_util)
