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

struct com_context *ctx = NULL;
struct IWbemServices *pWS = NULL;
struct IEnumWbemClassObject *pEnum = NULL;
char *userdomain = "samana\\fabianb";
char *user = "fabianb";
char *domain = "samana";
char *password = "Samana82.";
char *hostname = "192.168.0.110";
char *ns = "root\\cimv2";
char *query = "SELECT * FROM Win32_PageFileUsage";

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


static PyObject *
pywmi_connect(PyObject *self, PyObject *args)
{
    WERROR result;
    NTSTATUS status;

    if(ctx == NULL) {
        /* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
        W_ERROR_V(result) = 0x5;
        WERR_CHECK("CTX has not been initialized. Cannot continue.");        
    }

    if(userdomain == NULL){
        /* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
        W_ERROR_V(result) = 0x5;
        WERR_CHECK("Username and domain required. Cannot continue.");
    }

    if(ns == NULL) {
        /* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
        W_ERROR_V(result) = 0x5;
        WERR_CHECK("WMI Namespace required. Cannot continue.");
    }

    if(password == NULL) {
        /* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
        W_ERROR_V(result) = 0x5;
        WERR_CHECK("Password required. Cannot continue.");
    }

    if(hostname == NULL) {
        /* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
        W_ERROR_V(result) = 0x5;
        WERR_CHECK("Hostname required. Cannot continue.");
    }

    result = WBEM_ConnectServer(ctx, hostname, ns, userdomain, password, 0, 0, 0, 0, &pWS);
    WERR_CHECK("Login to remote object.");
    return Py_BuildValue("i", 0);

error:
    status = werror_to_ntstatus(result);
    fprintf(stderr, "NTSTATUS: %s - %s\n", nt_errstr(status), get_friendly_nt_error_msg(status));
    talloc_free(ctx);
    return Py_BuildValue("i", status);
}

static PyObject *
pywmi_query(PyObject *self, PyObject *args)
{
    WERROR result;
    NTSTATUS status;

/*
    const char *query;
    if(!PyArg_ParseTuple(args, "s", &query))
        return Py_BuildValue("i", 0);
*/

    if(ctx == NULL) {
        /* TODO: search for valid WERROR value for now using STATUS_ACCESS_DENIED NTSTATUS=0xc0000022 WERROR=0x5 */
        W_ERROR_V(result) = 0x5;
        WERR_CHECK("CTX has not been initialized. Cannot continue.");        
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

    result = IWbemServices_ExecQuery(pWS, ctx, "WQL", query, WBEM_FLAG_RETURN_IMMEDIATELY | WBEM_FLAG_ENSURE_LOCATABLE, NULL, &pEnum);
    WERR_CHECK("WMI query execute.");

    IEnumWbemClassObject_Reset(pEnum, ctx);
    WERR_CHECK("Reset result of WMI query.");

    return Py_BuildValue("i", 0);

error:
    status = werror_to_ntstatus(result);
    fprintf(stderr, "NTSTATUS: %s - %s\n", nt_errstr(status), get_friendly_nt_error_msg(status));
    talloc_free(ctx);
    return Py_BuildValue("i", status);

}

static PyMethodDef PyWMIMethods[] = {
    PYTHON_FUNCDEF(connect, "Connect to the server"),
    PYTHON_FUNCDEF(query, "Send Query to the server"),
    {NULL, NULL, 0, NULL}        /* Sentinel */
};

static struct PyModuleDef pywmimodule = {
    PyModuleDef_HEAD_INIT,
    "pywmi",   /* name of module */
    "PyWMI Documentation",     /* module documentation, may be NULL */
    -1,       /* size of per-interpreter state of the module,
                 or -1 if the module keeps state in global variables. */
    PyWMIMethods
};

PyMODINIT_FUNC
PyInit_pywmi(void)
{
    fault_setup("pywmi");
    setup_logging("pywmi", DEBUG_STDOUT);
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
    com_init_ctx(&ctx, NULL);
    dcom_client_init(ctx, NULL);

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
    if (PyImport_AppendInittab("pywmi", PyInit_pywmi) == -1) {
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
    PyObject *pmodule = PyImport_ImportModule("pywmi");
    if (!pmodule) {
        PyErr_Print();
        fprintf(stderr, "Error: could not import module 'pywmi'\n");
    }

    PyMem_RawFree(program);

    return 0;
}