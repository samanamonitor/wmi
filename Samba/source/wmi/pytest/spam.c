/*
    Ubuntu required packages: libpython3-dev
    Build command:
    gcc -DNDEBUG -g -O3 -Wall -Wstrict-prototypes -fPIC -DMAJOR_VERSION=1 -DMINOR_VERSION=0 \
        -I/usr/include -I/usr/include/python3.6m -c spam.c -o spam.o

    gcc -shared spam.o -L/usr/lib -o spam.so

*/

#define PY_SSIZE_T_CLEAN
#include <Python.h>

long global_var=0;

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
    if(!PyArg_ParseTuple(args, "i", &global_var))
        return NULL;
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
    return Py_BuildValue("s", "This is a test");
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
    {"set", spam_set, METH_FASTCALL,
     "Returns modifies internal variable"},
    {"get", spam_get, METH_FASTCALL,
     "Returns internal variable"},
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