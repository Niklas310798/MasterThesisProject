#!/usr/bin/python

from time import sleep
import subprocess
import signal
import json
import random
import logging
import os
from datetime import datetime


class TrafficGenerator():

    def __init__(self):
        with open("conf/topo_conf.json") as to_conf:
            topo_conf = json.load(to_conf)

        hosts = topo_conf['hosts']
        counter=0
        for host in hosts:
            command = "sudo ps aux | grep 'mininet:{}$' | grep -v p4 | awk '{{print $2}}'".format(host['name'])
            pid = subprocess.check_output(command, shell=True)
            if pid != b'':
                pid = int(pid.decode('utf-8').strip())
                # print(pid)
                hosts[counter]['pid'] = pid
                counter += 1
            else:
                self.host_comp = None
                return
        self.host_comp = [(x['name'], x['ip'].split('/', 1)[0], x['pid']) for x in hosts]
        # print(self.host_comp)

    def start_server(self, srv_name, iperf_port):
        cmd = "mx {0} iperf3 -s -p {1} 2>&1 >/dev/null"
        subprocess.Popen(cmd.format(srv_name, iperf_port), shell=True)

    def gen_client_server_pairs(self):
        hosts = self.host_comp
        random.shuffle(hosts)
        client_server_pairs = [hosts[i:i+2] for i in range(0, len(hosts), 2)]
        return client_server_pairs

    def start_iperf_client(self, program, scenario, run, client, server, port, flow_index):
        server_ip = server[1]
        if scenario['flow_size_mode'] == "static":
            flow_size = scenario['static_flow_size']
        else:
            flow_size = random.randint(scenario['min_flow_size'], scenario['max_flow_size'])
        target_bandwidth = scenario['target_iperf_bandwidth']

        # 0: Program name
        # 1: Scenario name
        # 2: Run number
        # 3: Client name
        # 4: Server name
        # 5: Port number
        # 6: Flow number
        logfile = "./tmp_results/{0}_{1}_{2}_{3}_{4}_{5}_{6}.json"
        logfile = logfile.format(program, scenario['name'], run, port, client[0], server[0], flow_index)

        # 0: Client hostname
        # 1: Server ip
        # 2: Server/Client port
        # 3: Number bytes iperf3
        # 4: Target bandwidth
        # 5: Location/Name logfile
        cmd = "mx {0} iperf3 -c {1} -p {2} -n {3} -b {4} -J --logfile {5} 2>&1 >/dev/null"
        cmd = cmd.format(client[0], server_ip, port, flow_size, target_bandwidth, logfile)

        p = subprocess.Popen(cmd, shell=True)
        return p

    def start_probe_traffic(self, scenario, client, server):
        server_ip = server[1]
        cmd = "mx {0} python3 utils/send_probes.py {1} {2} {3} {4} 2>&1 >/dev/null"
        cmd = cmd.format(client[0], server_ip, scenario["probe_pkt_proto"], scenario["probe_pkt_count"], scenario["probe_pkt_interval"])
        p = subprocess.Popen(cmd, shell=True)
        return p
