#!/usr/bin/python

from time import sleep
import subprocess
import signal
import json
import random
import logging
import os
from datetime import datetime

def start_cross_traffic_server(server):
    cmd = "mx {0} iperf3 -s -p {1} 2>&1 >/dev/null"
    subprocess.Popen(cmd.format(server['name'], server['server_port']), shell=True)

def start_cross_traffic_client(client, server):
    flow_size = random.randint(0, 1000000)
    target_bandwidth = "2M"

    # 0: Client hostname
    # 1: Server ip
    # 2: Server/Client port
    # 3: Number bytes iperf3
    # 4: Target bandwidth
    cmd = "mx {0} iperf3 -c {1} -p {2} -n {3} -b {4} -u 2>&1 >/dev/null"
    cmd = cmd.format(client['name'], server['ip'], server['server_port'], flow_size, target_bandwidth)

    p = subprocess.Popen(cmd, shell=True)
    return p


dummy1 = {
    "name": "dummy1",
    "ip": "10.10.10.1",
    "server_port": 5001
}
dummy2 = {
    "name": "dummy1",
    "ip": "10.10.10.2",
    "server_port": 5002
}

client_procs = [None, None]

start_time = sys.argv[1]
experiment_duration = sys.argv[2]

start_cross_traffic_server(dummy1)
start_cross_traffic_server(dummy2)

client_procs[0] = start_cross_traffic_client(dummy1, dummy2)
client_procs[1] = start_cross_traffic_client(dummy2, dummy1)

while time.time() < start_time + experiment_duration + 25:
    for i in range(len(client_procs)):
        if client_procs[i] == None or client_proc.poll() is not None:
            if i == 0:
                client_procs[i] = start_cross_traffic_client(dummy1, dummy2)
            if i == 1:
                client_procs[i] = start_cross_traffic_client(dummy2, dummy1)
    time.sleep(1)
