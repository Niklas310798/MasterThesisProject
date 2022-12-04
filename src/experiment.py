
import json
import sys
from subprocess import Popen, check_output
import subprocess
import time
import matplotlib.pyplot as plt
import numpy
import os
import signal
from datetime import datetime
import shutil
from utils.traffic_gen import TrafficGenerator
from p4utils.utils.helper import check_listening_on_port


def copy_to_shared_folder():
    root = os.getcwd()
    root_list = root.split('/')
    root_list[-1] = "experiment_results"
    destination = ""
    for dir in root_list:
        destination += "/"
        destination += dir

    srcs = ["results", "result_plots", "ctlr_logs"]
    conf_src = "{}/conf/experiment_conf.json".format(root)

    timestamp = datetime.now().strftime("%d-%b-%Y_%H-%M-%S")
    dst = "{}/{}".format(destination, timestamp)
    for src in srcs:
        try:
            shutil.copytree("{}/tmp_{}".format(root, src), "{}/{}".format(dst, src))
        except IOError as e:
            print("Experiment: unable to copy folder. {}".format(e))
        else:
            print("Experiment: copied {} folder to shared drive".format(src))
    try:
        shutil.copy(conf_src, dst)
    except IOError as e:
        print("Experiment: unable to copy file. {}".format(e))
    else:
        print("Experiment: copied experiment_conf file to shared drive")

def delete_old_results():
    Popen("rm -rf ./tmp_results && mkdir tmp_results", shell=True) # delete old results and create new results folder
    Popen("rm -rf ./tmp_result_plots && mkdir tmp_result_plots", shell=True) # delete old results and create new results folder
    Popen("rm -rf ./tmp_ctlr_logs && mkdir tmp_ctlr_logs", shell=True) # delete old controller logs and create new controller logs folder
    Popen("rm -rf ./log/cross_traffic && mkdir log/cross_traffic", shell=True) # delete old controller logs and create new controller logs folder
    print("Experiment: removed old results folders and created new folders")

def init_mininet():
    # cleanup()
    # network.py starts Mininet and runs network, additionally configures host nodes
    # switch configuration is done by P4Runtime controller
    # executes switch_command bash scripts and installs forwarding rules via gRPC connection
    p4_utils_cmd = 'xterm -e "cd /home/p4/Niklas-Schwingeler-MA2021/src; sudo python3 network.py"'
    Popen(p4_utils_cmd, shell=True)
    # print("\nExperiment: starting mininet")
    time.sleep(15)

def check_mininet_running():
    print("Experiment: Checking if Mininet is up and running")
    grpc_port = 50001

    all_switches_running = False
    timeout = 60
    start = time.time()
    while not all_switches_running:
        switches_not_running = 0
        for i in range(18):
            if not check_listening_on_port(grpc_port + i):
                switches_not_running += 1
        if switches_not_running == 0:
            all_switches_running = True
            print("Experiment: all switches started and listening on their grpc ports")
            return True
        if time.time() > start + timeout:
            print("Experiment: mininet startup failed, hit timeout")
            cleanup(True)
            return False

def start_controller(type, scenario, program, run, start_time, initial_config_done, static_trigger, dyn_trigger):
    if type == "dynamic":
        trigger = dyn_trigger
        ctlr_cmd = "sudo python3 dyn_controller.py {0} {1} {2} {3} {4} {5}"
    if type == "static_threshold":
        trigger = static_trigger
        ctlr_cmd = "sudo python3 controller.py {0} {1} {2} {3} {4} {5}"
    # Popen(ctlr_cmd.format(scenario, program, run), shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    ctlr_p = Popen(ctlr_cmd.format(scenario, program, run, start_time, initial_config_done, trigger), shell=True, preexec_fn=os.setsid)
    print("Experiment: started {} controller".format(type))
    return ctlr_p

def start_cross_traffic(program, scenario, run, target_bandwidth):
    cmd = "sudo python3 utils/cross_traffic.py {0} {1} {2} {3}"
    cross_traffic_p = Popen(cmd.format(program, scenario, run, target_bandwidth), shell=True)

def configure_nodes():
    init_command = "sudo bash init.sh"
    Popen(init_command, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) # configure nodes without output
    time.sleep(15) # wait until all nodes are readily configured
    print("Experiment: all nodes configured successfully via script")

def get_iperf_client_pids():
    cmd = "ps aux|grep 'iperf3 -c 10.0.'|awk '{print $2}'"
    pids = check_output(cmd, shell=True).decode('utf-8').strip()
    pid_list = pids.split()
    return pid_list

def log_link_utilization(scenario, program, run, links):
    log_interval = 1 # seconds
    for l in links:
        logfile = "./tmp_results/{0}_{1}_{2}_{3}.tsv"
        command = 'mx {0} ./utils/log_link_utilization.sh {1} {2} {3}'
        Popen(command.format(l[0], l[1], logfile.format(scenario, program, run, l[1]), log_interval), shell=True)

def cleanup(reset_mininet):
    # Popen("logging=$(ps aux|grep log_link_utilization|awk '{print $2}');sudo kill -9 $logging 2>&1 >/dev/null", shell=True) # kill logging processes
    # print("kill logging processes")
    # time.sleep(2)
    Popen("mnexec_commands=$(ps aux|grep mnexec|awk '{print $2}');sudo kill -9 $mnexec_commands 2>&1 >/dev/null", shell=True) # kill mx command stuff
    print("kill mnexec processes")
    time.sleep(2)
    Popen("mnexec_commands=$(ps aux|grep mx|awk '{print $2}');sudo kill -9 $mnexec_commands 2>&1 >/dev/null", shell=True) # kill mx command stuff
    print("kill mx processes")
    time.sleep(2)
    Popen("mnexec_commands=$(ps aux|grep iperf3|awk '{print $2}');sudo kill -9 $mnexec_commands 2>&1 >/dev/null", shell=True) # kill iperf command processes
    print("kill iperf3 processes")
    time.sleep(2)
    Popen("controller=$(ps aux|grep controller.py|awk '{print $2}');sudo kill -9 $controller 2>&1 >/dev/null", shell=True) # kill controller processes
    print("kill controller processes")
    time.sleep(2)
    Popen("trafficgen=$(ps aux|grep send_probes|awk '{print $2}');sudo kill -9 $trafficgen 2>&1 >/dev/null", shell=True) # kill probe traffic generation processes
    print("kill probe processes")
    time.sleep(2)
    Popen("crosstraffic=$(ps aux|grep cross_traffic|awk '{print $2}');sudo kill -9 $crosstraffic 2>&1 >/dev/null", shell=True) # kill probe traffic generation processes
    print("kill cross traffic processes")
    time.sleep(2)
    if reset_mininet:
        Popen("mininet=$(ps aux|grep network.py|awk '{print $2}');sudo kill -9 $mininet 2>&1 >/dev/null", shell=True) # kill mininet
        print("kill mininet/p4-utils processes")
        time.sleep(2)

def evaluate_flow_completion_times(client_server_pairs_list, scenario, programs):
    max_fct = 0
    fcts_list = []
    program_index = 0
    run_index = 0
    flow_counter = 0
    error_counter = 0
    for csp_list in client_server_pairs_list:
        fcts_list.append([])
        run = "run{0}"
        if run_index < 10:
            run = "run0{0}"
        print("")
        print("program", programs[program_index], "run", run.format(run_index))
        for csp in csp_list:
            client = csp[0]
            server = csp[1]
            iperf_ports = csp[2:]
            for iperf_port in iperf_ports:
                port_number = iperf_port[0]
                for flow_number in range(iperf_port[1]):
                    flow_counter += 1
                    logfile = "./tmp_results/{0}_{1}_{2}_{3}_{4}_{5}_{6}.json"
                    try:
                        # print(program_index, scenario,  run.format(run_index), port_number, client[0], server[0], flow_number)
                        f = open(logfile.format(programs[program_index], scenario,  run.format(run_index), port_number, client[0], server[0], flow_number))
                        data = json.load(f)
                        if data["end"]["sum_received"]["bytes"] != 0:
                            fcts_list[program_index].append(data["end"]["sum_received"]["seconds"])
                        elif fcts_list[program_index][len(fcts_list[program_index]) - 1] > max_fct:
                            max_fct = fcts_list[program_index][len(fcts_list[program_index]) - 1]
                    except:
                        if "error" in data:
                            if data["error"]  == "error - unable to connect to server: Connection refused":
                                print("ERROR: {} {} {} {} to {} -- Connection refused (flow {})".format(programs[program_index], scenario,  run.format(run_index), client[0], server[0], flow_number))
                        else:
                            print("error in iperf3 json file ", logfile.format(programs[program_index], scenario,  run.format(run_index), port_number, client[0], server[0], flow_number))
                        error_counter += 1
        if run_index < experiment_conf['number_runs'] - 1:
            run_index += 1
        else:
            program_index += 1
            run_index = 0
    program_index = 0
    plotfile = "./tmp_result_plots/{0}_fct.png"
    for program in programs:
        fcts = numpy.sort(fcts_list[program_index])
        fcts_cdf = []
        for i in range(len(fcts)):
            fcts_cdf.append(1/len(fcts) * (i + 1))
        plt.plot(fcts, fcts_cdf)
        plt.legend(programs)
        plt.xlabel('FCT (s)')
        plt.ylabel('CDF')
        plt.title("Flow completion time")
        plt.savefig(plotfile.format(scenario))
        program_index += 1
    plt.clf()
    print("Experiment: number total flows:", flow_counter)
    print("Experiment: number failed flows:", error_counter)

def evaluate_retransmissions(client_server_pairs_list, scenario, programs):
    max_fct = 0
    fcts_list = []
    program_index = 0
    run_index = 0
    flow_counter = 0
    error_counter = 0
    for csp_list in client_server_pairs_list:
        fcts_list.append([])
        run = "run{0}"
        if run_index < 10:
            run = "run0{0}"
        print("")
        print("program", programs[program_index], "run", run.format(run_index))
        for csp in csp_list:
            client = csp[0]
            server = csp[1]
            iperf_ports = csp[2:]
            for iperf_port in iperf_ports:
                port_number = iperf_port[0]
                for flow_number in range(iperf_port[1]):
                    flow_counter += 1
                    logfile = "./tmp_results/{0}_{1}_{2}_{3}_{4}_{5}_{6}.json"
                    try:
                        # logfile format: program, scenario, run, iperf_port, src_host, dst_host, flow_number
                        f = open(logfile.format(programs[program_index], scenario, run.format(run_index), port_number, client[0], server[0], flow_number))
                        data = json.load(f)
                        if data["end"]["sum_received"]["bytes"] != 0:
                            fcts_list[program_index].append(data["end"]["sum_sent"]["retransmits"])
                        elif fcts_list[program_index][len(fcts_list[program_index]) - 1] > max_fct:
                            max_fct = fcts_list[program_index][len(fcts_list[program_index]) - 1]
                    except:
                        if "error" in data:
                            if data["error"]  == "error - unable to connect to server: Connection refused":
                                print("ERROR: {} {} {} {} to {} -- Connection refused (flow {})".format(programs[program_index], scenario,  run.format(run_index), client[0], server[0], flow_number))
                        else:
                            print("error in iperf3 json file ", logfile.format(programs[program_index], scenario,  run.format(run_index), port_number, client[0], server[0], flow_number))
                        error_counter += 1
        if run_index < experiment_conf['number_runs'] - 1:
            run_index += 1
        else:
            program_index += 1
            run_index = 0
    program_index = 0
    plotfile = "./tmp_result_plots/{0}_retransmissions.png"
    for program in programs:
        fcts = numpy.sort(fcts_list[program_index])
        fcts_cdf = []
        for i in range(len(fcts)):
            fcts_cdf.append(1/len(fcts) * (i + 1))
        plt.plot(fcts, fcts_cdf)
        # fcts = numpy.sort(fcts_list[program_index])
        # fcts_ccdf = []
        # for i in range(len(fcts)):
        #   fcts_ccdf.append(1-(1/len(fcts) * (i + 1)))
        # plt.plot(fcts, fcts_ccdf)
        plt.xscale('log')
        plt.legend(programs)
        plt.xlabel('Number retransmissions')
        plt.ylabel('CDF')
        plt.title("Number retransmissions")
        plt.savefig(plotfile.format(scenario))
        program_index += 1
    plt.clf()
    print("Number total flows:", flow_counter)
    print("Number failed flows:", error_counter)

def evaluate_link_utilization(scenario, program, run, links, link_capacity):
    for l in links:
        logfile = "./tmp_results/{0}_{1}_{2}_{3}.tsv"
        plotfile = "./tmp_results/{0}_{1}_{2}_{3}.png"
        f = open(logfile.format(scenario, program, run, l[1]), "r")
        lines = f.readlines()
        counter = 0
        time_interval_middle_point_timestamps = []
        bits_per_second = []
        link_utilization = []
        timestamps = [] # in milliseconds
        tx_bytes = []
        rx_bytes = []
        for line in lines: # read columns from file
            timestamps.append(int(line.split('\t')[0]))
            if len(line.split('\t')[1]) == 0:
                tx_bytes.append(0)
            else:
                tx_bytes.append(int(line.split('\t')[1]))
            if len(line.split('\t')[2]) == 0:
                rx_bytes.append(0)
            else:
                rx_bytes.append(int(line.split('\t')[2]))
#               print("timestamp: ", timestamps[counter], " tx_bytes: ", tx_bytes[counter], " rx_bytes: ", rx_bytes[counter])
            if counter > 0:
                time_interval_middle_point_timestamps.append((timestamps[counter] + (timestamps[counter] - timestamps[counter - 1]) / 2 - timestamps[0]) / 1000) # used to calculate throughput
                bits_per_second.append((tx_bytes[counter] + rx_bytes[counter] - tx_bytes[counter - 1] - rx_bytes[counter - 1]) * 8 / ((timestamps[counter] - timestamps[counter - 1]) / 1000))
                link_utilization.append(100 / link_capacity * bits_per_second[counter - 1])
                counter += 1
        plt.plot(time_interval_middle_point_timestamps, link_utilization)
        plt.xlabel('time (s)')
        plt.ylabel('link utilization (%)')
        plt.title(l[1])
        plt.savefig(plotfile.format(scenario, program, run, l[1]))
        plt.clf()


# Experiment start

delete_old_results()
cleanup(True)

link_capacity = 5000000 # in bps

links = [["l1", "l1-eth1"], ["l1", "l1-eth2"], ["l1", "l1-eth3"], ["l1", "l1-eth4"],
         ["l2", "l2-eth1"], ["l2", "l2-eth2"], ["l2", "l2-eth3"], ["l2", "l2-eth4"],
         ["l3", "l3-eth1"], ["l3", "l3-eth2"], ["l3", "l3-eth3"], ["l3", "l3-eth4"],
         ["l4", "l4-eth1"], ["l4", "l4-eth2"], ["l4", "l4-eth3"], ["l4", "l4-eth4"],
         ["l5", "l5-eth1"], ["l5", "l5-eth2"], ["l5", "l5-eth3"], ["l5", "l5-eth4"],
         ["l6", "l6-eth1"], ["l6", "l6-eth2"], ["l6", "l6-eth3"], ["l6", "l6-eth4"],
         ["l7", "l7-eth1"], ["l7", "l7-eth2"], ["l7", "l7-eth3"], ["l7", "l7-eth4"],
         ["l8", "l8-eth1"], ["l8", "l8-eth2"], ["l8", "l8-eth3"], ["l8", "l8-eth4"],
         ["s1", "s1-eth1"], ["s1", "s1-eth2"], ["s1", "s1-eth3"], ["s1", "s1-eth4"], ["s1", "s1-eth5"],
         ["s2", "s2-eth1"], ["s2", "s2-eth2"], ["s2", "s2-eth3"], ["s2", "s2-eth4"], ["s2", "s2-eth5"],
         ["s3", "s3-eth1"], ["s3", "s3-eth2"], ["s3", "s3-eth3"], ["s3", "s3-eth4"], ["s3", "s3-eth5"],
         ["s4", "s4-eth1"], ["s4", "s4-eth2"], ["s4", "s4-eth3"], ["s4", "s4-eth4"], ["s4", "s4-eth5"],
         ["bl1", "bl1-eth1"], ["bl1", "bl1-eth2"], ["bl1", "bl1-eth3"],
         ["bl2", "bl2-eth1"], ["bl2", "bl2-eth2"], ["bl2", "bl2-eth3"],
         ["i1", "i1-eth1"], ["i1", "i1-eth2"], ["i1", "i1-eth3"],
         ["i2", "i2-eth1"], ["i2", "i2-eth2"], ["i2", "i2-eth3"],
         ["i3", "i3-eth1"], ["i3", "i3-eth2"], ["i3", "i3-eth3"],
         ["i4", "i4-eth1"], ["i4", "i4-eth2"], ["i4", "i4-eth3"]
        ]

with open("conf/experiment_conf.json") as f:
    experiment_conf = json.load(f)

programs = experiment_conf['programs']
# programs = ['rerouting', 'static']

scenarios = []
scenarios = experiment_conf['scenarios']
# scenarios.append(experiment_conf['scenarios'][0])
# scenarios.append(experiment_conf['scenarios'][1])

if experiment_conf['start_mininet_for_every'] == "experiment":
    print("Experiment: starting mininet for entire experiment")
    init_mininet()

initial_config_done = False
for scenario in scenarios:
    if experiment_conf['start_mininet_for_every'] == "scenario":
        print("Experiment: starting mininet for", scenario['name'])
        init_mininet()
    client_server_pairs_list = []
    for program in programs:
        if experiment_conf['start_mininet_for_every'] == "program":
            print("Experiment: starting mininet for", scenario['name'], program)
            init_mininet()
        last_run = "run{0}".format(experiment_conf['number_runs'] - 1)
        if experiment_conf['number_runs'] <= 10:
            last_run = "run0{0}".format(experiment_conf['number_runs'] - 1)
        if experiment_conf['number_runs'] == 11:
            last_run = "run10"
        for i in range(experiment_conf['number_runs']):
            run = "run{0}"
            if i < 10:
                run = "run0{0}"

            if experiment_conf['start_mininet_for_every'] == "run":
                print("\nExperiment: starting mininet for", scenario['name'], program, run.format(i))
                init_mininet()

            started = check_mininet_running()
            timeout_counter = 0
            while not started:
                print("Experiment: did not start correctly, restarting mininet...")
                init_mininet()
                started = check_mininet_running()
                initial_config_done = False
            if started:
                start_time = time.time()
                print("Experiment: starting scenario", scenario['name'], "program", program, "run", run.format(i), "at", time.ctime(start_time))
                # log_link_utilization(scenario['name'], program, run.format(i), links)

                controller_process = start_controller(scenario['controller_type'], scenario['name'], program, run.format(i), (start_time + 25), initial_config_done, scenario['static_controller_threshold'], scenario['dyn_controller_congestion_factor'])
                time.sleep(5)
                if not initial_config_done:
                    print("Experiment: run init.sh to configure hosts and switches")
                    configure_nodes()
                    initial_config_done = True
                else:
                    print("Experiment: initial config already done, no modification necessary")
            else:
                print("Experiment: mininet did not start, skipping", scenario['name'], "program", program, "run", run.format(i))
                continue

            if experiment_conf['cross_traffic'] == "True":
                start_cross_traffic(program, scenario['name'], run.format(i), experiment_conf['ct_target_bandwidth'])

            print("Experiment: opening a total of {} simultaneous iperf3 connections/pairs".format(scenario["8_times_x_pairs"]*8))
            print("Experiment: each server opening {} iperf port(s)".format(scenario['ports_per_server']))
            tg = TrafficGenerator()
            iperf_port = 5200
            current_client_server_pairs = []
            for x in range(scenario['8_times_x_pairs']):
                if tg.host_comp is None:
                    sys.exit("No host processes found")
                current_client_server_pairs.extend(tg.gen_client_server_pairs())

            client_probe_mappings = []
            c_s_pair_index = 0
            for c_s_pair in current_client_server_pairs:
                client = c_s_pair[0]
                server = c_s_pair[1]

                port_index = 0
                for port in range(scenario['ports_per_server']):
                    iperf_port += 1
                    tg.start_server(server[0], iperf_port)
                    port_flow_mapping = [iperf_port, 0]
                    c_s_pair.append(port_flow_mapping)

                client_probe_mapping = []
                ports = c_s_pair[2:]
                port_index = 2
                for port in ports:
                    client_pids = []
                    iperf_port = port[0]
                    flow_index = port[1]
                    client_pids.append(tg.start_iperf_client(program, scenario, run.format(i), client, server, iperf_port, flow_index))
                    current_client_server_pairs[c_s_pair_index][port_index][1] += 1
                    port_index += 1
                    info = "new flow for {0} to {1} started: #{2}"
                    # print(info.format(client[0], server[0], flow_index))
                client_probe_mapping.append(client_pids)

                if program != "static":
                    client_probe_mapping.append(tg.start_probe_traffic(scenario, client, server))

                client_probe_mappings.append(client_probe_mapping)
                # client_server_pairs_list.append(c_s_pair)
                c_s_pair_index += 1
            if program == "static":
                print("Experiment: iperf3 servers and clients started at {}".format(datetime.fromtimestamp(start_time + 25 )))
            else:
                print("Experiment: iperf3 servers, clients and probe traffic started at {}".format(datetime.fromtimestamp(start_time + 25)))

            # print(current_client_server_pairs)
            # print(client_probe_mappings)
            print("")
            while time.time() < start_time + experiment_conf['experiment_duration'] + 25:
                sys.stdout.write("\r{}s of {}s from run over".format(round(time.time() - (start_time + 25)), experiment_conf['experiment_duration']))
                sys.stdout.flush()
                csp_index = 0
                for client_probe_mapping in client_probe_mappings:
                    client = current_client_server_pairs[csp_index][0]
                    server = current_client_server_pairs[csp_index][1]
                    iperf_port_index = 2
                    client_proc_index = 0
                    for client_proc in client_probe_mapping[0]:
                        if client_proc.poll() is not None:
                            iperf_port = current_client_server_pairs[csp_index][iperf_port_index][0]
                            flow_index = current_client_server_pairs[csp_index][iperf_port_index][1]
                            new_client_proc = tg.start_iperf_client(program, scenario, run.format(i), client, server, iperf_port, flow_index)
                            client_probe_mappings[csp_index][0][client_proc_index] = new_client_proc
                            current_client_server_pairs[csp_index][iperf_port_index][1] += 1
                            # info = "new flow for {0} to {1} started: #{2}"
                            # print(info.format(client[0], server[0], flow_index))
                        iperf_port_index += 1
                        client_proc_index += 1
                    csp_index += 1
                time.sleep(1)

            client_processes_running = True
            # != 1 because the grep process always creates one pid to be returned
            while client_processes_running:
                if len(get_iperf_client_pids()) == 2:
                    print("Experiment: all client processes ended")
                    client_server_pairs_list.append(current_client_server_pairs)
                    wait = 1
                    os.killpg(os.getpgid(controller_process.pid), signal.SIGINT)
                    # controller_process.send_signal(signal.SIGINT)
                    print("Experiment: waiting {} second(s) before starting cleanup".format(wait))
                    time.sleep(wait)
                    client_processes_running = False
                else:
                    time.sleep(1)

            # evaluate_link_utilization(scenario['name'], program, run.format(i), links, link_capacity)
            print("Experiment: finishing", scenario['name'], program, run.format(i))

            # test if Mininet startup works after every run
            if experiment_conf['start_mininet_for_every'] == "run":
                print("Experiment: shutting down mininet after run")
                cleanup(True)
                initial_config_done = False
            else:
                cleanup(False)
        print("Experiment: finishing", scenario['name'], program)
        if experiment_conf['start_mininet_for_every'] == "program":
            print("Experiment: shutting down mininet after program")
            cleanup(True)
            initial_config_done = False
        else:
            cleanup(False)
    print("Experiment: finishing", scenario['name'])
    if experiment_conf['start_mininet_for_every'] == "scenario":
        print("Experiment: shutting down mininet after scenario")
        cleanup(True)
        initial_config_done = False
    # cleanup(False)
    # print(client_server_pairs_list)
    evaluate_flow_completion_times(client_server_pairs_list, scenario['name'], experiment_conf['programs'])
    evaluate_retransmissions(client_server_pairs_list, scenario['name'], experiment_conf['programs'])
    print("Experiment: ", scenario['name'], "ended")

copy_to_shared_folder()
cleanup(True)

print("")
print("##################")
print("Experiment ended !!")
print("##################")
