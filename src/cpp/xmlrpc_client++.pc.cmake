bindir=@bindir@
prefix=@prefix@
libdir=@libdir@
includedir=@includedir@

Name:	     xmlrpc_client++
Description: XMLRPC C++ Client library
Version:     @XMLRPC_C_VERSION@

Requires.private:	xmlrpc++ xmlrpc_client xmlrpc_packetsocket xmlrpc xmlrpc_util
Libs:			-L${libdir} -lxmlrpc_client++
Cflags:			-I${includedir}
