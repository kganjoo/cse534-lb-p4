import requests
import datetime
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
import time
query_server1 = {
    'query': 'avg(node_load5{instance="server1",job="node"}) / count(count(node_cpu_seconds_total{instance="server1",job="node"}) by (cpu)) * 100',
}

query_server2 = {
    'query': 'avg(node_load5{instance="server2",job="node"}) / count(count(node_cpu_seconds_total{instance="server2",job="node"}) by (cpu)) * 100',
}


auth_user = 'QrVrlLPR'
auth_pwd = 'UZCMLftt'




def query_prom_server(params, instance):
    resp = requests.get('https://localhost:9090/api/v1/query', params=params, verify=False, auth=(auth_user, auth_pwd))
    if resp.status_code==200:
        resp = resp.json()
        x =resp["data"]["result"][0]["value"]
        time_stamp = int(x[0])
        dt_jst_aware = datetime.datetime.fromtimestamp(time_stamp, datetime.timezone(datetime.timedelta(hours=-7)))
        metric = float(x[1])
        print(f'load at {instance} : {metric} at {dt_jst_aware}')
    print("///////////////////////")



if __name__ == '__main__':
    while True:
        query_prom_server(query_server1, "server1")
        query_prom_server(query_server2, "server2")
        print("\n")
        
        time.sleep(30)
