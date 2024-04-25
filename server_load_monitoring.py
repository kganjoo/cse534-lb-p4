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
switch_ip = '192.168.4.1'
switch_port = '8080'




def query_load(params, instance):
    resp = requests.get('https://localhost:9090/api/v1/query', params=params, verify=False, auth=(auth_user, auth_pwd))
    if resp.status_code==200:
        resp = resp.json()
        x =resp["data"]["result"][0]["value"]
        time_stamp = int(x[0])
        dt_jst_aware = datetime.datetime.fromtimestamp(time_stamp, datetime.timezone(datetime.timedelta(hours=-7)))
        metric = float(x[1])
        print(f'load at {instance} : {metric} at {dt_jst_aware}')
        return metric
    print("///////////////////////")



if __name__ == '__main__':
    while True:
        server1_load = query_load(query_server1, "server1")
        #QUERY THE CURRENT SWITCH STATE
        switch_get_state_endpoint = f'http://{switch_ip}:{switch_port}/state'
        response = requests.get(switch_get_state_endpoint)
        data= response.json()
        switch_state = data["state"]
        
        if server1_load>55 and switch_state!=1:
            #call the upscale endpoint which changes switch state to 1
            switch_upscale_endpoint = f'http://{switch_ip}:{switch_port}/upscale'
            response = requests.post(switch_upscale_endpoint)
            result = response.json()
            print(f'switch_upscale resp : {result}')
        server2_load = query_load(query_server2, "server2")
        print("\n")
        
        time.sleep(30)
