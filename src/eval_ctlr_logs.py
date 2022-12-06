import os
from os.path import dirname
from pathlib import Path
import json
from numpy import mean
import matplotlib.pyplot as plt


path = os.getcwd().replace("src", "experiment_results")
result_dirs = [f.path for f in os.scandir(path) if f.is_dir()]

scenarios = 0
packet_data = []
controller_data = []
for result_dir in result_dirs:
    conf_path = result_dir + "/experiment_conf.json"
    with open(conf_path) as f:
        experiment_conf = json.load(f)

    ctlr_logs_dir = result_dir + "/ctlr_logs"
    scenario_stats = {}
    for scenario in experiment_conf['scenarios']:
        comprehended_ctlr_stats = {}
        comprehended_pckt_stats = {}
        scenario_number = scenario['name'].split("scenario", 1)[1]
        cross_traffic = scenario['cross_traffic']
        ct_bw = scenario['ct_target_bandwidth']
        iperf_conns = scenario['8_times_x_pairs']*8
        for program in ['rerouting', 'probed']:
            packets_per_vtep_pair_per_run_list = []
            highest_packets_per_vtep_pair_list = []
            lowest_packets_per_vtep_pair_list = []
            highest_latency_per_vtep_pair_list = []
            average_latency_per_vtep_pair_program_list = []
            reroute_per_run_list = []
            static_trigger_per_run_list = []
            dyn_trigger_per_run_list = []
            both_trigger_per_run_list = []

            for i in range(experiment_conf['number_runs']):
                packets_per_vtep_pair_list = []

                reroute = 0
                static_trigger = 0
                dyn_trigger = 0
                both_trigger = 0

                highest_packets_per_vtep_pair_run = 0
                lowest_packets_per_vtep_pair_run = 0
                highest_latency_per_vtep_pair_run = 0
                average_latency_per_vtep_pair_run_list = []

                run = "run{0}"
                if i < 10:
                    run = "run0{0}"
                run = run.format(i)

                controller_stats_file = "/{}_{}_{}_controllerstats.json".format(scenario['name'], program, run)
                controller_stats_path = ctlr_logs_dir + controller_stats_file

                ctlr_log = json.load(open(controller_stats_path))

                for vtep_pair, entry in ctlr_log.items():
                    if highest_packets_per_vtep_pair_run == 0:
                        highest_packets_per_vtep_pair_run = entry['packet_count']
                        lowest_packets_per_vtep_pair_run = entry['packet_count']
                    else:
                        if highest_packets_per_vtep_pair_run < entry['packet_count']:
                            highest_packets_per_vtep_pair_run = entry['packet_count']
                        if lowest_packets_per_vtep_pair_run > entry['packet_count']:
                            lowest_packets_per_vtep_pair_run = entry['packet_count']

                    if highest_latency_per_vtep_pair_run == 0:
                        highest_latency_per_vtep_pair_run = entry['highest_tstamp_latency']
                    else:
                        if highest_latency_per_vtep_pair_run < entry['highest_tstamp_latency']:
                            highest_latency_per_vtep_pair_run = entry['highest_tstamp_latency']

                    reroute += entry['reroute_triggered']
                    packets_per_vtep_pair_list.append(entry['packet_count'])
                    average_latency_per_vtep_pair_run_list.append(entry['average_tstamp_latency'])
                    for event in entry['events']:
                        if event[3] == "static_trigger" or event[3] == "fallback_trigger":
                            static_trigger += 1
                        elif event[3] == "dyn_trigger":
                            dyn_trigger += 1
                        elif event[3] == "both_triggers":
                            both_trigger += 1

                # general stats
                packets_per_vtep_pair_per_run_list.append(mean(packets_per_vtep_pair_list))

                # controller stats
                reroute_per_run_list.append(reroute)
                static_trigger_per_run_list.append(static_trigger)
                dyn_trigger_per_run_list.append(dyn_trigger)
                both_trigger_per_run_list.append(both_trigger)

                # packet stats
                highest_packets_per_vtep_pair_list.append(highest_packets_per_vtep_pair_run)
                lowest_packets_per_vtep_pair_list.append(lowest_packets_per_vtep_pair_run)
                highest_latency_per_vtep_pair_list.append(highest_latency_per_vtep_pair_run)
                average_latency_per_vtep_pair_program_list.append(mean(average_latency_per_vtep_pair_run_list))

            ctlr_stats = {
                "packets_per_vtep_pair": int(mean(packets_per_vtep_pair_per_run_list)),
                "reroute_per_run": mean(reroute_per_run_list),
                "static_trigger_per_run": mean(static_trigger_per_run_list),
                "dyn_trigger_per_run": mean(dyn_trigger_per_run_list),
                "both_triggers_per_run": mean(both_trigger_per_run_list)
            }
            pckt_stats = {
                "packets_per_vtep_pair": int(mean(packets_per_vtep_pair_per_run_list)),
                "highest_packets_per_vtep_pair": int(mean(highest_packets_per_vtep_pair_list)),
                "lowest_packets_per_vtep_pair": int(mean(lowest_packets_per_vtep_pair_list)),
                "highest_latency_per_vtep_pair": int(mean(highest_latency_per_vtep_pair_list)),
                "average_tstamp_latency": int(mean(average_latency_per_vtep_pair_program_list))
            }
            if program == "rerouting":
                comprehended_ctlr_stats['rerouting'] = ctlr_stats
            elif program == "probed":
                comprehended_ctlr_stats['probed'] = ctlr_stats
            if program == "rerouting":
                comprehended_pckt_stats['rerouting'] = pckt_stats
            elif program == "probed":
                comprehended_pckt_stats['probed'] = pckt_stats


        reroute_d = comprehended_ctlr_stats['rerouting']
        probed_d = comprehended_ctlr_stats['probed']
        scenario_d = [
            scenario_number, cross_traffic, ct_bw, iperf_conns,
            reroute_d['packets_per_vtep_pair'], reroute_d['reroute_per_run'], reroute_d['static_trigger_per_run'], reroute_d['dyn_trigger_per_run'], reroute_d['both_triggers_per_run'],
            probed_d['packets_per_vtep_pair'], probed_d['reroute_per_run'], probed_d['static_trigger_per_run'], probed_d['dyn_trigger_per_run'], probed_d['both_triggers_per_run']
        ]
        controller_data.append(scenario_d)

        reroute_d = comprehended_pckt_stats['rerouting']
        probed_d = comprehended_pckt_stats['probed']
        scenario_d = [
            scenario_number, cross_traffic, ct_bw, iperf_conns,
            reroute_d['packets_per_vtep_pair'], reroute_d['highest_packets_per_vtep_pair'], reroute_d['lowest_packets_per_vtep_pair'], reroute_d['highest_latency_per_vtep_pair'], reroute_d['average_tstamp_latency'],
            probed_d['packets_per_vtep_pair'], probed_d['highest_packets_per_vtep_pair'], probed_d['lowest_packets_per_vtep_pair'], probed_d['highest_latency_per_vtep_pair'], probed_d['average_tstamp_latency']
        ]

        packet_data.append(scenario_d)

        scenarios += 1

for i in range(scenarios):
    print("Szenario:", i)
    print("Controller:")
    print(controller_data[i])
    print("Packets:")
    print(packet_data[i])
