/*
This code is property of Samana Group LLC. You need permission from Samana Group
to use this code.

To build this code, wmic must be compiled first.
*/

#include <Python.h>
#include "includes.h"
#include "librpc/gen_ndr/ndr_epmapper_c.h"
#include "librpc/gen_ndr/com_dcom.h"
#include "librpc/rpc/dcerpc_table.h"
#include "lib/com/proto.h"

#include "lib/com/dcom/dcom.h"

#include "wmi.h"
#include "proto.h"

#define PYMODULE "pywmi"
#define PYOPEN_DOC "Creates a new connection to a Windows server using WMI.\n\
\n\
This functions establishes a connection with a windows server using WMI. All\n\
the parameters are mandatory:\n\
\n\
	pywmi.open(hostname, username, password, namespace)\n\
\n\
	hostname can be an IP address or an FQDN. If the username is specified in UPN\n\
		format, this module will try to use kerberos for authentication.\n\
		This means that the hostname must be specified as an FQDN.\n\
	username can be specified as \"user\" for workgroup environments, as \n\
		\"domain\\user\" for domain managed environments or \n\
		\"user@domain\" for domain managed environments with kerberos \n\
		authentication\n\
	namespace required for WMI queries. Recommended value is \"root\\cimv2\", but \n\
		any other namespace can be specified.\n\
\n\
The return value is an integer with the result of the operation. 0 means correct \n\
connection. Other values map to NTSTATUS Values as specified by \n\
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-erref/596a1078-e883-4972-9bbc-49e60bebca55\n\
This module is a single instance and cannot connect to multiple servers at the same time.\n\
This means that the `open` method can only be used once. If another connection is needed,\n\
the connection must be closed first."

#define PYCLOSE_DOC "Closes the connection to the Windows server. This method doesn't receive any parameters.\n\
The output of this method is always 0. It will free all the memory reserved for the connection."

#define PYQUERY_DOC "Sends a WQL query to the server that the module is currently connected.\n\
The query must follow the exact syntax of all WQL queries as defined by \n\
\n\
https://docs.microsoft.com/en-us/windows/win32/wmisdk/wql-sql-for-wmi\n\
\n\
	Example: SELECT * FROM win32_operatingsystem\n\
\n\
	pywmi.query(wql_query)\n\
\n\
	The output of this method is a dictionary array with the format:\n\
	[\n\
		{\n\
			\"classname\": \"...\",\n\
			\"properties\": {\n\
				\"property_name\": `value`\n\
				... \n\
			}\n\
		},\n\
		...\n\
	]\n\
\n\
	`value` can be any of the following types:\n\
	* string\n\
	* long\n\
	* boolean\n\
	* array of any of the previous types\n\
"

#define PYMODULE_DOC "This module provides various functions to communicate with windows servers using WMI.\n\
\n\
Windows Management Instrumentation (WMI) is the infrastructure for management\n\
data and operations on Windows-based operating systems.\n\
This module utilizes Samba source code and additional code with DCOM interfaces\n\
to allow Python to generate WMI queries targeted to a windows server.\n\
The original source code was downloaded from \n\
\n\
https://www.edcint.co.nz/checkwmiplus/wmi-1.3.14.tar.gz\n\
\n\
And modified by Fabian Baena at Samana Group.\n\
This library is not free. If you are using this library without written permission,\n\
you can be prosecuted. Please refrain from using this library if you are not \n\
authorized.\n\
\n\
:mod:`pywmi` exposes a simple API that allows for reutilization of WMI connections\n\
             to windows servers.\n\
\n\
       >>> import pywmi\n\
       >>> pywmi.open(server_ip, username, password, namespace)\n\
       0\n\
       >>> pywmi.query(wmi_query)  # wmi_query in WQL format\n\
       {...}                       # dictionary with the result\n\
       >>> pywmi.close()\n\
       0\n"

struct com_context *ctx = NULL;
struct IWbemServices *pWS = NULL;

#define PYTHON_FUNCDEF(funcname, description) \
	{                                         \
		#funcname,                            \
		pywmi_ ## funcname, METH_VARARGS,     \
		description                          \
	}

#define WERR_CHECK(msg) if (!W_ERROR_IS_OK(result)) { \
				DEBUG(0, ("ERROR: %s\n", msg));       \
				goto error;                           \
			} else {                                  \
				DEBUG(1, ("OK   : %s\n", msg));       \
			}

#define PY_BOOLEAN(x) x?Py_True:Py_False
#define PY_STRING(x) x==NULL?Py_None:PyUnicode_FromString(x)

#define RETURN_CVAR_ARRAY_PYOBJ(f, arr) {\
		uint32_t i;\
		PyObject *r = Py_BuildValue("[]");\
		if (!arr) {\
			return r;\
		}\
		for(i = 0; i < arr->count; i++) {\
		    PyObject_CallMethodObjArgs(r, Py_BuildValue("s", "append"), f(arr->item[i]), NULL);\
		}\
		return r;\
	}

PyObject *
pyObj_CIMVAR(union CIMVAR *v, enum CIMTYPE_ENUMERATION cimtype)
{
	switch (cimtype) {
        case CIM_SINT8: return PyLong_FromLong(v->v_sint8);
        case CIM_UINT8: return PyLong_FromLong(v->v_uint8);
        case CIM_SINT16: return PyLong_FromLong(v->v_sint16);
        case CIM_UINT16: return PyLong_FromLong(v->v_uint16);
        case CIM_SINT32: return PyLong_FromLong(v->v_sint32);
        case CIM_UINT32: return PyLong_FromLong(v->v_uint32);
        case CIM_SINT64: return PyLong_FromLong(v->v_sint64);
        case CIM_UINT64: return PyLong_FromLong(v->v_sint64);
        case CIM_REAL32: return PyFloat_FromDouble((double)v->v_uint32);
        case CIM_REAL64: return PyFloat_FromDouble((double)v->v_uint64);
        case CIM_BOOLEAN: return v->v_boolean?Py_True:Py_False;
        case CIM_STRING:
        case CIM_DATETIME:
        case CIM_REFERENCE: return PY_STRING(v->v_string);
        case CIM_CHAR16: return PyUnicode_FromString("Unsupported");
        case CIM_OBJECT: return PyUnicode_FromString("Unsupported");
        case CIM_ARR_SINT8: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_sint8);
        case CIM_ARR_UINT8: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_uint8);
        case CIM_ARR_SINT16: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_sint16);
        case CIM_ARR_UINT16: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_uint16);
        case CIM_ARR_SINT32: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_sint32);
        case CIM_ARR_UINT32: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_uint32);
        case CIM_ARR_SINT64: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_sint64);
        case CIM_ARR_UINT64: RETURN_CVAR_ARRAY_PYOBJ(PyLong_FromLong, v->a_uint64);
        case CIM_ARR_REAL32: RETURN_CVAR_ARRAY_PYOBJ(PyFloat_FromDouble, v->a_real32);
        case CIM_ARR_REAL64: RETURN_CVAR_ARRAY_PYOBJ(PyFloat_FromDouble, v->a_real64);
        case CIM_ARR_BOOLEAN: RETURN_CVAR_ARRAY_PYOBJ(PY_BOOLEAN, v->a_boolean);
        case CIM_ARR_STRING: RETURN_CVAR_ARRAY_PYOBJ(PY_STRING, v->a_string);
        case CIM_ARR_DATETIME: RETURN_CVAR_ARRAY_PYOBJ(PY_STRING, v->a_datetime);
        case CIM_ARR_REFERENCE: RETURN_CVAR_ARRAY_PYOBJ(PY_STRING, v->a_reference);
	default: return PyUnicode_FromString("Unsupported");
	}
}

static PyObject *
pywmi_close(PyObject *self, PyObject *args)
{
	talloc_free(pWS);
	pWS = NULL;
	talloc_free(ctx);
	ctx = NULL;
	return Py_BuildValue("i", 0);
}

static PyObject *
pywmi_open(PyObject *self, PyObject *args)
{
	WERROR result;
	NTSTATUS status;
	char *userdomain;
	char *password;
	char *hostname;
	char *ns = "root\\cimv2";

	if(!PyArg_ParseTuple(args, "ssss", &hostname, &userdomain, &password, &ns))
		return Py_BuildValue("i", -1);

	if(ctx != NULL || pWS != NULL) {
		/* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
		printf("CTX has already been initialized. Cannot continue.\n");
		return Py_BuildValue("i", 0x5);
	}

	if(hostname == NULL) {
		/* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
		W_ERROR_V(result) = 0x5;
		WERR_CHECK("Hostname required. Cannot continue.");
	}

	com_init_ctx(&ctx, NULL);
	dcom_client_init(ctx, NULL);
	result = WBEM_ConnectServer(ctx, hostname, ns, userdomain, password, 0, 0, 0, 0, &pWS);
	WERR_CHECK("Login to remote object.");

	return Py_BuildValue("i", 0);

error:
	status = werror_to_ntstatus(result);
	fprintf(stderr, "NTSTATUS: %s - %s\n", nt_errstr(status), get_friendly_nt_error_msg(status));
	talloc_free(ctx);
	ctx = NULL;
	talloc_free(pWS);
	pWS = NULL;
	return Py_BuildValue("i", status);
}

static PyObject *
pywmi_data(struct IEnumWbemClassObject *pEnum)
{
	WERROR result;
	NTSTATUS status;
	uint32_t cnt = 5, ret;
	char *class_name = NULL;
	PyObject *wmi_reclist = Py_BuildValue("[]");

	result = IEnumWbemClassObject_Reset(pEnum, ctx);
	WERR_CHECK("Reset result of WMI query.");
	do {
		uint32_t i, j;
		struct WbemClassObject *co[cnt];

		result = IEnumWbemClassObject_SmartNext(pEnum, ctx, 0xFFFFFFFF, cnt, co, &ret);
		/* WERR_BADFUNC is OK, it means only that there is less returned objects than requested */
		if (!W_ERROR_EQUAL(result, WERR_BADFUNC)) {
			WERR_CHECK("Retrieve result data.");
		} else {
			DEBUG(1, ("OK   : Retrieved less objects than requested (it is normal).\n"));
		}
		if (!ret) break;
		for (i = 0; i < ret; ++i) {
			PyObject *wmi_rec = Py_BuildValue("{}");
			if (!class_name || strcmp(co[i]->obj_class->__CLASS, class_name)) {
				if (class_name) talloc_free(class_name);
				class_name = talloc_strdup(ctx, co[i]->obj_class->__CLASS);
			    PyObject_CallMethod(wmi_rec, "__setitem__", "(s,s)", "classname", class_name);
			}
			PyObject *property_dict = Py_BuildValue("{}");
			for (j = 0; j < co[i]->obj_class->__PROPERTY_COUNT; ++j) {
				PyObject *v = pyObj_CIMVAR(&co[i]->instance->data[j],
					co[i]->obj_class->properties[j].desc->cimtype & CIM_TYPEMASK);
				PyObject_CallMethodObjArgs(property_dict, Py_BuildValue("s", "__setitem__"),
					Py_BuildValue("s", co[i]->obj_class->properties[j].name), v, NULL);
/*
				char *s;
				s = string_CIMVAR(ctx, &co[i]->instance->data[j], co[i]->obj_class->properties[j].desc->cimtype & CIM_TYPEMASK);
			    PyObject_CallMethod(property_dict, "__setitem__", "(s,s)", co[i]->obj_class->properties[j].name, s);
*/
			}
		    PyObject_CallMethodObjArgs(wmi_rec, Py_BuildValue("s", "__setitem__"), Py_BuildValue("s", "properties"), property_dict, NULL);
 		    PyObject_CallMethodObjArgs(wmi_reclist, Py_BuildValue("s", "append"), wmi_rec, NULL);
		}
	} while (ret == cnt);

	return wmi_reclist;

error:
	status = werror_to_ntstatus(result);
	fprintf(stderr, "NTSTATUS: %s - %s\n", nt_errstr(status), get_friendly_nt_error_msg(status));
	return Py_BuildValue("i", status);
}

static PyObject *
pywmi_query(PyObject *self, PyObject *args)
{
	WERROR result;
	NTSTATUS status;
	struct IEnumWbemClassObject *pEnum = NULL;
	const char *query;

	if(!PyArg_ParseTuple(args, "s", &query))
		return Py_BuildValue("[]");

	if(ctx == NULL) {
		/* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
		W_ERROR_V(result) = 0x5;
		WERR_CHECK("Server context has not been initialized. Cannot continue.");       
	}

	if(pWS == NULL) {
		/* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
		W_ERROR_V(result) = 0x5;
		WERR_CHECK("Connection has not been established with host. Cannot continue.");       
	}

	if(query == NULL) {
		/* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
		W_ERROR_V(result) = 0x5;
		WERR_CHECK("Query required. Cannot continue.");
	}

	if(pEnum != NULL) {
		talloc_free(pEnum);
		pEnum = NULL;
	}

	result = IWbemServices_ExecQuery(pWS, ctx, "WQL", query, WBEM_FLAG_RETURN_IMMEDIATELY | WBEM_FLAG_ENSURE_LOCATABLE, NULL, &pEnum);
	WERR_CHECK("WMI query execute.");

	PyObject *q_result = pywmi_data(pEnum);
	talloc_free(pEnum);
	pEnum = NULL;

	return q_result;

error:
	status = werror_to_ntstatus(result);
	fprintf(stderr, "NTSTATUS: %s - %s\n", nt_errstr(status), get_friendly_nt_error_msg(status));
	talloc_free(pEnum);
	return Py_BuildValue("[]");

}

static PyMethodDef PyWMIMethods[] = {
	PYTHON_FUNCDEF(open, PYOPEN_DOC),
	PYTHON_FUNCDEF(query, PYQUERY_DOC),
	PYTHON_FUNCDEF(close, PYCLOSE_DOC),
	{NULL, NULL, 0, NULL}        /* Sentinel */
};

static struct PyModuleDef pywmimodule = {
	PyModuleDef_HEAD_INIT,
	PYMODULE,   /* name of module */
	PYMODULE_DOC,     /* module documentation, may be NULL */
	-1,       /* size of per-interpreter state of the module,
				 or -1 if the module keeps state in global variables. */
	PyWMIMethods
};

PyMODINIT_FUNC
PyInit_pywmi(void)
{
	fault_setup(PYMODULE);
	setup_logging(PYMODULE, DEBUG_STDOUT);
	lp_load();

	dcerpc_init();
	dcerpc_table_init();

	dcom_proxy_IUnknown_init();
	dcom_proxy_IWbemLevel1Login_init();
	dcom_proxy_IWbemServices_init();
	dcom_proxy_IEnumWbemClassObject_init();
	dcom_proxy_IRemUnknown_init();
	dcom_proxy_IWbemFetchSmartEnum_init();
	dcom_proxy_IWbemWCOSmartEnum_init();

	return PyModule_Create(&pywmimodule);
}

int main(int argc, char *argv[])
{

	wchar_t *program = Py_DecodeLocale(argv[0], NULL);
	if (program == NULL) {
		fprintf(stderr, "Fatal error: cannot decode argv[0]\n");
		exit(1);
	}

	/* Add a built-in module, before Py_Initialize */
	if (PyImport_AppendInittab(PYMODULE, PyInit_pywmi) == -1) {
		fprintf(stderr, "Error: could not extend in-built modules table\n");
		exit(1);
	}

	/* Pass argv[0] to the Python interpreter */
	Py_SetProgramName(program);

	/* Initialize the Python interpreter.  Required.
	   If this step fails, it will be a fatal error. */
	Py_Initialize();

	/* Optionally import the module; alternatively,
	   import can be deferred until the embedded script
	   imports it. */
	PyObject *pmodule = PyImport_ImportModule(PYMODULE);
	if (!pmodule) {
		PyErr_Print();
		fprintf(stderr, "Error: could not import module '" PYMODULE "'\n");
	}

	PyMem_RawFree(program);

	return 0;
}