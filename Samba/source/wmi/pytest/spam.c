/*
    Ubuntu required packages: libpython3-dev
    Build command:
    gcc -DNDEBUG -g -O3 -Wall -Wstrict-prototypes -fPIC -DMAJOR_VERSION=1 -DMINOR_VERSION=0 \
        -I/usr/include -I/usr/include/python3.6m -c spam.c -o spam.o

    gcc -shared spam.o -L/usr/lib -o spam.so

*/

#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include "includes.h"
#include "librpc/rpc/dcerpc.h"
#include "librpc/gen_ndr/ndr_oxidresolver.h"
#include "librpc/gen_ndr/ndr_oxidresolver_c.h"
#include "librpc/gen_ndr/ndr_dcom.h"
#include "librpc/gen_ndr/ndr_dcom_c.h"
#include "librpc/gen_ndr/ndr_remact_c.h"
#include "librpc/gen_ndr/ndr_epmapper_c.h"
#include "librpc/gen_ndr/com_dcom.h"
#include "librpc/rpc/dcerpc_table.h"
#include "lib/com/proto.h"
#include "auth/credentials/credentials.h"

#include "lib/cmdline/popt_common.h"

#include "lib/com/dcom/dcom.h"
#include "lib/com/dcom/proto.h"

long global_var=0;

#include "../wmi.h"

char *userdomain = "samana\\fabianb";
char *user = "fabianb";
char *domain = "samana";
char *password = "Samana82.";
char *hostname = "192.168.0.110";
char *ns = "root\\cimv2";
char *query = "SELECT * FROM Win32_PageFileUsage";


#define WERR_CHECK(msg) if (!W_ERROR_IS_OK(result)) { \
                DEBUG(0, ("ERROR: %s\n", msg)); \
                goto error; \
            } else { \
                DEBUG(1, ("OK   : %s\n", msg)); \
            }

static PyObject *
spam_wmi_help(PyObject *self, PyObject *args)
{
    return Py_BuildValue("(ssss)", query, hostname, ns, "");

}

static PyObject *
spam_system(PyObject *self, PyObject *args)
{
    const char *command;
    int sts;

    if (!PyArg_ParseTuple(args, "s", &command))
        return NULL;
    sts = system(command);
    return PyLong_FromLong(sts);
}

static PyObject *
spam_set(PyObject *self, PyObject *args)
{
    long in;
    if(!PyArg_ParseTuple(args, "l", &in))
        return NULL;
    global_var = in;
    return PyLong_FromLong(global_var);
}

static PyObject *
spam_get(PyObject *self, PyObject *args)
{
    return PyLong_FromLong(global_var);
}

static PyObject *
spam_string(PyObject *self, PyObject *args)
{
    return Py_BuildValue("s", hostname);
}

static PyObject *
spam_dict(PyObject *self, PyObject *args)
{
    PyObject *out = Py_BuildValue("{}");
    PyObject_CallMethod(out, "__setitem__", "(s,s)", "firstname", "fabian");
    PyObject_CallMethod(out, "__setitem__", "(s,s)", "lastname", "baens");
    return out;
}

static PyObject *
spam_list(PyObject *self, PyObject *args)
{
    PyObject *out = Py_BuildValue("[]");
    for(int i=0; i<10; i++){
        PyObject_CallMethod(out, "append", "(i)", i);
    }
    return out;
}

static PyMethodDef SpamMethods[] = {
    {"system",  spam_system, METH_VARARGS,
     "Execute a shell command."},
    {"string", spam_string, METH_VARARGS,
     "Returns a string"},
    {"dict", spam_dict, METH_FASTCALL,
     "Returns a dict"},
    {"list", spam_list, METH_FASTCALL,
     "Returns a list"},
    {"set", spam_set, METH_VARARGS,
     "Returns modifies internal variable"},
    {"get", spam_get, METH_FASTCALL,
     "Returns internal variable"},
    {"wmi_help",  spam_wmi_help, METH_VARARGS,
     "wmi help."},
    {NULL, NULL, 0, NULL}        /* Sentinel */
};

static struct PyModuleDef spammodule = {
    PyModuleDef_HEAD_INIT,
    "spam",   /* name of module */
    "this is module documentation",     /* module documentation, may be NULL */
    -1,       /* size of per-interpreter state of the module,
                 or -1 if the module keeps state in global variables. */
    SpamMethods
};

PyMODINIT_FUNC
PyInit_spam(void)
{
    WERROR result;
    struct IWbemServices *pWS = NULL;
    NTSTATUS status;
    global_var=10;

    fault_setup("pywmic");
    setup_logging("pywmic", DEBUG_STDOUT);
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
    struct com_context *ctx = NULL;
    com_init_ctx(&ctx, NULL);
    dcom_client_init(ctx, NULL);

    result = WBEM_ConnectServer(ctx, hostname, ns, userdomain, password, 0, 0, 0, 0, &pWS);
    WERR_CHECK("Login to remote object.");

    struct IEnumWbemClassObject *pEnum = NULL;
    result = IWbemServices_ExecQuery(pWS, ctx, "WQL", query, WBEM_FLAG_RETURN_IMMEDIATELY | WBEM_FLAG_ENSURE_LOCATABLE, NULL, &pEnum);
    WERR_CHECK("WMI query execute.");

    IEnumWbemClassObject_Reset(pEnum, ctx);
    WERR_CHECK("Reset result of WMI query.");

    return PyModule_Create(&spammodule);
error:
    status = werror_to_ntstatus(result);
    fprintf(stderr, "NTSTATUS: %s - %s\n", nt_errstr(status), get_friendly_nt_error_msg(status));
    talloc_free(ctx);
    return PyModule_Create(&spammodule);
}

int main(int argc, char *argv[])
{

    wchar_t *program = Py_DecodeLocale(argv[0], NULL);
    if (program == NULL) {
        fprintf(stderr, "Fatal error: cannot decode argv[0]\n");
        exit(1);
    }

    /* Add a built-in module, before Py_Initialize */
    if (PyImport_AppendInittab("spam", PyInit_spam) == -1) {
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
    PyObject *pmodule = PyImport_ImportModule("spam");
    if (!pmodule) {
        PyErr_Print();
        fprintf(stderr, "Error: could not import module 'spam'\n");
    }

    PyMem_RawFree(program);



    return 0;
}