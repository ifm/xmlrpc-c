# -*- cmake -*-

if(ENABLE_LIBXML2_BACKEND)
  set(xmlrpc_xml_parser xmlrpc_libxml2.c)
  set(libxml_INCLUDES ${LIBXML2_CFLAGS})
  set(libxml_LIBS     ${LIBXML2_LDFLAGS})
  set(xmlrpc_pkgconfig_req ${libxml_pkgconfig})
else(ENABLE_LIBXML2_BACKEND)
  set(xmlrpc_xml_parser xmlrpc_expat.c)
  set(libxml_INCLUDES -I${xmlrpc-c_SOURCE_DIR}/lib/expat/xmlparse)
  set(libxml_LIBS xmlrpc_xmlparse)
  set(xmlrpc_pkgconfig_req xmlrpc_xmlparse)
endif(ENABLE_LIBXML2_BACKEND)

if(MUST_BUILD_WININET_CLIENT)
  set(client_wininet_CFLAGS "")
  set(client_wininet_LIBS  wininet util)
  list(APPEND transport_SOURCES
    ${wininet_srcdir}/xmlrpc_wininet_transport.c ${wininet_srcdir}/xmlrpc_wininet_transport.h)
endif(MUST_BUILD_WININET_CLIENT)

if(MUST_BUILD_LIBWWW_CLIENT)
  set(client_libwww_CFLAGS "${LIBWWW_CFLAGS}")
  set(client_libwww_LIBS   "${LIBWWW_LIBS}")
  list(APPEND transport_SOURCES ${libwww_srcdir}/xmlrpc_libwww_transport.c ${libwww_srcdir}/xmlrpc_libwww_transport.h)
endif(MUST_BUILD_LIBWWW_CLIENT)

if(MUST_BUILD_CURL_CLIENT)
  FIND_PACKAGE(CURL REQUIRED)
  include_directories(${CURL_INCLUDE_DIR})
  set(client_curl_LIBS ${CURL_LIBRARY})
  set(xmlrpc_client_pkgconfig_req libcurl)
  list(APPEND transport_SOURCES
    ${curl_srcdir}/xmlrpc_curl_transport.c
    ${curl_srcdir}/curltransaction.c
    ${curl_srcdir}/curltransaction.h
    ${curl_srcdir}/curlmulti.c
    ${curl_srcdir}/curlmulti.h
    ${curl_srcdir}/curlversion.h
	${curl_srcdir}/xmlrpc_curl_transport.h
    )
endif(MUST_BUILD_CURL_CLIENT)

set(client_CFLAGS "-I${wininet_srcdir} -I${libwww_srcdir} -I${curl_srcdir} ${client_wininet_CFLAGS} ${client_libwww_CFLAGS}")
set(client_LIBS   ${client_wininet_LIBS} ${client_libwww_LIBS} ${client_curl_LIBS})



add_subdirectory(cpp)



### libxmlrpc.so
add_library(xmlrpc
  double.c parse_datetime.c parse_value.c resource.c trace.c version.c
  json.c
  ${xmlrpc_xml_parser}
  xmlrpc_data.c xmlrpc_datetime.c xmlrpc_string.c
  xmlrpc_array.c xmlrpc_struct.c
  xmlrpc_build.c xmlrpc_decompose.c xmlrpc_parse.c xmlrpc_serialize.c
  xmlrpc_authcookie.c)

set_target_properties(xmlrpc PROPERTIES COMPILE_FLAGS ${libxml_INCLUDES})

ensc_pkgconfig(xmlrpc)
target_link_libraries(xmlrpc PRIVATE ${libxml_LIBS} PUBLIC xmlrpc_util)
list(APPEND lib_TARGETS ${libxml_LIBS})
list(APPEND lib_TARGETS xmlrpc_xmltok)

list(APPEND lib_TARGETS xmlrpc)

### libxmlrpc_client.so
add_library(xmlrpc_client
  xmlrpc_client.c xmlrpc_client_global.c xmlrpc_server_info.c ${transport_SOURCES}
  ${xmlrpc-c_SOURCE_DIR}/include/xmlrpc-c/client.h)

if(WIN32)
   target_link_libraries(xmlrpc_client xmlrpc ${client_LIBS} wldap32)
else(WIN32)
   target_link_libraries(xmlrpc_client xmlrpc ${client_LIBS})
endif(WIN32)
set_target_properties(xmlrpc_client
  PROPERTIES
  COMPILE_FLAGS "${client_CFLAGS}")
list(APPEND lib_TARGETS xmlrpc_client)
ensc_pkgconfig(xmlrpc_client)

set_target_properties(xmlrpc_util PROPERTIES DEFINE_SYMBOL XMLRPC_CLIENT_EXPORTED __declspec(dllexport))

### libxmlrpc_server.so
add_library(xmlrpc_server
  registry.c method.c system_method.c)
target_link_libraries(xmlrpc_server xmlrpc)
list(APPEND lib_TARGETS xmlrpc_server)
ensc_pkgconfig(xmlrpc_server)


### libxmlrpc_server_abyss.so
if(ENABLE_ABYSS_SERVER)
  add_library(xmlrpc_server_abyss
    xmlrpc_server_abyss.c abyss_handler.c)
  target_link_libraries(xmlrpc_server_abyss xmlrpc_abyss xmlrpc_server)
  list(APPEND lib_TARGETS xmlrpc_server_abyss)
  ensc_pkgconfig(xmlrpc_server_abyss)
endif(ENABLE_ABYSS_SERVER)



### libxmlrpc_server_cgi.so
if(ENABLE_CGI_SERVER)
  add_library(xmlrpc_server_cgi
    xmlrpc_server_cgi)
  target_link_libraries(xmlrpc_server_cgi xmlrpc_server)
  list(APPEND lib_TARGETS xmlrpc_server_cgi)
  ensc_pkgconfig(xmlrpc_server_cgi)
endif(ENABLE_CGI_SERVER)

install(TARGETS ${lib_TARGETS}
  EXPORT xmlrpc-c-targets
  RUNTIME DESTINATION ${_bin}
  ARCHIVE DESTINATION ${_lib}
  LIBRARY DESTINATION ${_lib}
  PUBLIC_HEADER DESTINATION ${_include})

set_target_properties(${lib_TARGETS}
  PROPERTIES
  LINK_FLAGS ${XMLRPC_LINKER_FLAGS}
  VERSION    ${XMLRPC_C_LIBVERSION}
  SOVERSION  ${XMLRPC_C_SOVERSION})


enable_testing()
