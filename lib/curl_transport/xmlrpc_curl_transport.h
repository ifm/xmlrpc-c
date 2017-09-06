#ifndef XMLRPC_CURL_TRANSPORT_H
#define XMLRPC_CURL_TRANSPORT_H

#include "xmlrpc-c/transport.h"

#ifdef __cplusplus
extern "C" {
#endif

extern struct xmlrpc_client_transport_ops xmlrpc_curl_transport_ops;

xmlrpc_client_transport_ops* get_curl_ops(void);

#ifdef __cplusplus
}
#endif
#endif
