/*
	Ubuntu required packages: libpython3-dev
	Build command:
	gcc -DNDEBUG -g -O3 -Wall -Wstrict-prototypes -fPIC -DMAJOR_VERSION=1 -DMINOR_VERSION=0 \
		-I/usr/include -I/usr/include/python3.6m -c spam.c -o spam.o

	gcc -shared spam.o -L/usr/lib -o spam.so

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

struct com_context *ctx = NULL;
struct IWbemServices *pWS = NULL;
struct cli_credentials *server_credentials;

#define PYTHON_FUNCDEF(funcname, description) \
	{                                         \
		#funcname,                            \
		pywmi_ ## funcname, METH_VARARGS,     \
		"\"" #description "\""                \
	}

#define WERR_CHECK(msg) if (!W_ERROR_IS_OK(result)) { \
				DEBUG(0, ("ERROR: %s\n", msg));       \
				goto error;                           \
			} else {                                  \
				DEBUG(1, ("OK   : %s\n", msg));       \
			}

#define RETURN_CVAR_ARRAY_STR(fmt, arr) {\
        uint32_t i;\
		char *r;\
\
        if (!arr) {\
                return talloc_strdup(mem_ctx, "NULL");\
        }\
		r = talloc_strdup(mem_ctx, "(");\
        for (i = 0; i < arr->count; ++i) {\
			r = talloc_asprintf_append(r, fmt "%s", arr->item[i], (i+1 == arr->count)?"":",");\
        }\
        return talloc_asprintf_append(r, ")");\
	}

#define PY_BOOLEAN(x) x?Py_True:Py_False

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
        case CIM_REFERENCE: return PyUnicode_FromString(v->v_string);
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
        case CIM_ARR_STRING: RETURN_CVAR_ARRAY_PYOBJ(PyUnicode_FromString, v->a_string);
        case CIM_ARR_DATETIME: RETURN_CVAR_ARRAY_PYOBJ(PyUnicode_FromString, v->a_datetime);
        case CIM_ARR_REFERENCE: RETURN_CVAR_ARRAY_PYOBJ(PyUnicode_FromString, v->a_reference);
	default: return PyUnicode_FromString("Unsupported");
	}
}

char *string_CIMVAR(TALLOC_CTX *mem_ctx, union CIMVAR *v, enum CIMTYPE_ENUMERATION cimtype)
{
	switch (cimtype) {
        case CIM_SINT8: return talloc_asprintf(mem_ctx, "%d", v->v_sint8);
        case CIM_UINT8: return talloc_asprintf(mem_ctx, "%u", v->v_uint8);
        case CIM_SINT16: return talloc_asprintf(mem_ctx, "%d", v->v_sint16);
        case CIM_UINT16: return talloc_asprintf(mem_ctx, "%u", v->v_uint16);
        case CIM_SINT32: return talloc_asprintf(mem_ctx, "%d", v->v_sint32);
        case CIM_UINT32: return talloc_asprintf(mem_ctx, "%u", v->v_uint32);
        case CIM_SINT64: return talloc_asprintf(mem_ctx, "%ld", v->v_sint64);
        case CIM_UINT64: return talloc_asprintf(mem_ctx, "%lu", v->v_sint64);
        case CIM_REAL32: return talloc_asprintf(mem_ctx, "%f", (double)v->v_uint32);
        case CIM_REAL64: return talloc_asprintf(mem_ctx, "%f", (double)v->v_uint64);
        case CIM_BOOLEAN: return talloc_asprintf(mem_ctx, "%s", v->v_boolean?"True":"False");
        case CIM_STRING:
        case CIM_DATETIME:
        case CIM_REFERENCE: return talloc_asprintf(mem_ctx, "%s", v->v_string);
        case CIM_CHAR16: return talloc_asprintf(mem_ctx, "Unsupported");
        case CIM_OBJECT: return talloc_asprintf(mem_ctx, "Unsupported");
        case CIM_ARR_SINT8: RETURN_CVAR_ARRAY_STR("%d", v->a_sint8);
        case CIM_ARR_UINT8: RETURN_CVAR_ARRAY_STR("%u", v->a_uint8);
        case CIM_ARR_SINT16: RETURN_CVAR_ARRAY_STR("%d", v->a_sint16);
        case CIM_ARR_UINT16: RETURN_CVAR_ARRAY_STR("%u", v->a_uint16);
        case CIM_ARR_SINT32: RETURN_CVAR_ARRAY_STR("%d", v->a_sint32);
        case CIM_ARR_UINT32: RETURN_CVAR_ARRAY_STR("%u", v->a_uint32);
        case CIM_ARR_SINT64: RETURN_CVAR_ARRAY_STR("%ld", v->a_sint64);
        case CIM_ARR_UINT64: RETURN_CVAR_ARRAY_STR("%lu", v->a_uint64);
        case CIM_ARR_REAL32: RETURN_CVAR_ARRAY_STR("%d", v->a_real32);
        case CIM_ARR_REAL64: RETURN_CVAR_ARRAY_STR("%ld", v->a_real64);
        case CIM_ARR_BOOLEAN: RETURN_CVAR_ARRAY_STR("%d", v->a_boolean);
        case CIM_ARR_STRING: RETURN_CVAR_ARRAY_STR("%s", v->a_string);
        case CIM_ARR_DATETIME: RETURN_CVAR_ARRAY_STR("%s", v->a_datetime);
        case CIM_ARR_REFERENCE: RETURN_CVAR_ARRAY_STR("%s", v->a_reference);
	default: return talloc_asprintf(mem_ctx, "Unsupported");
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
					Py_BuildValue("s", co[i]->obj_class->properties[j].name),
					v, NULL);
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
	PYTHON_FUNCDEF(open, "Connect to the server"),
	PYTHON_FUNCDEF(query, "Send Query to the server"),
	PYTHON_FUNCDEF(close, "Disconnect from server"),
	{NULL, NULL, 0, NULL}        /* Sentinel */
};

static struct PyModuleDef pywmimodule = {
	PyModuleDef_HEAD_INIT,
	PYMODULE,   /* name of module */
	"PyWMI Documentation",     /* module documentation, may be NULL */
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