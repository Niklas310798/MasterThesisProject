#!/usr/bin/python

import time
import subprocess
import signal
import json
import random
import logging
import os
from datetime import datetime
import sys

def start_cross_traffic_server(server):
    cmd = "mx {0} iperf3 -s -p {1} 2>&1 >/dev/null"
    subprocess.Popen(cmd.format(server['name'], server['server_port']), shell=True)

def start_cross_traffic_client(client, server, flow_index, target_bandwidth):
    flow_size = random.randint(0, 5000000)

    # 0: Program name
    # 1: Scenario name
    # 2: Run number
    # 3: Client name
    # 4: Server name
    # 5: Flow number
    logfile = "./log/cross_traffic/{0}_{1}_{2}_{3}_{4}_flow{5}.json"
    logfile = logfile.format(program, scenario, run, client['name'], server['name'], flow_index)

    # 0: Client hostname
    # 1: Server ip
    # 2: Server/Client port
    # 3: Number bytes iperf3
    # 4: Target bandwidth
    cmd = "mx {0} iperf3 -c {1} -p {2} -n {3} -b {4} -u -J --logfile {5} 2>&1 >/dev/null"
    cmd = cmd.format(client['name'], server['ip'], server['server_port'], flow_size, target_bandwidth, logfile)

    p = subprocess.Popen(cmd, shell=True)
    return p


dummy1 = {
    "name": "dummy1",
    "ip": "10.10.1.1",
    "server_port": 6001
}
dummy2 = {
    "name": "dummy2",
    "ip": "10.20.1.1",
    "server_port": 6002
}

client_procs = [None, None]

program = sys.argv[1]
scenario = sys.argv[2]
run = sys.argv[3]
target_bandwidth = sys.argv[4]

start_cross_traffic_server(dummy1)
start_cross_traffic_server(dummy2)

dummy1_flowindex = 0
dummy2_flowindex = 0

client_procs[0] = start_cross_traffic_client(dummy1, dummy2, dummy1_flowindex, target_bandwidth)
client_procs[1] = start_cross_traffic_client(dummy2, dummy1, dummy2_flowindex, target_bandwidth)

print("CrossTraffic: Cross traffic between dummy1 and dummy2 started")

dummy1_flowindex += 1
dummy2_flowindex += 1

while True:
    for i in range(len(client_procs)):
        if client_procs[i] == None or client_procs[i].poll() is not None:
            if i == 0:
                client_procs[i] = start_cross_traffic_client(dummy1, dummy2, dummy1_flowindex, target_bandwidth)
                dummy1_flowindex += 1
            if i == 1:
                client_procs[i] = start_cross_traffic_client(dummy2, dummy1, dummy2_flowindex, target_bandwidth)
                dummy2_flowindex += 1
    time.sleep(1)
