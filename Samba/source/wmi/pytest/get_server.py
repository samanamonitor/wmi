import pywmi
import time
from sys import argv
import json

hostname=argv[1]
user=argv[2]
pwd=argv[3]
ns="root\\cimv2"
event_secs=300
event_level=2


ct = time.strptime(time.ctime(time.time() + event_secs))
timefilter = "%04d%02d%02d%02d%02d%02d.000-000" % (ct.tm_year, ct.tm_mon, ct.tm_mday, ct.tm_hour, ct.tm_min, ct.tm_sec)

queries = {
    'os': "SELECT * FROM win32_operatingsystem",
    'disk': "SELECT * FROM win32_logicaldisk",
    'cpu': "SELECT * FROM Win32_PerfRawData_perfos_processor WHERE Name='_Total'",
    'pf': "SELECT * FROM Win32_PageFileUsage",
    'events': "select * from Win32_NTLogEvent where TimeGenerated > '%s' and EventType <= %d" % (timefilter, event_level),
    'proc': "SELECT * FROM Win32_Process"
}
server = {}

pywmi.open(hostname, user, pwd, ns)
for i in queries.keys():
    server[i] = pywmi.query(queries[i])
pywmi.close()

print(json.dumps(server))