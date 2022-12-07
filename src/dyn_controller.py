#!/usr/bin/env python3
import sys
import struct
import os
from subprocess import Popen
from pprint import pprint
import signal
from statistics import mean

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet, IPOption, Ether, IP, raw
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.layers.inet import _IPOption_HDR

from p4utils.utils.sswitch_p4runtime_API import SimpleSwitchP4RuntimeAPI
from p4utils.mininetlib.network_API import NetworkAPI

from utils.decoder import *
from utils.ctlr_helper import DequeHandler, ReroutingStatsHandler


def teardown_grpc_connections():
    global leafs
    global spines
    global borderleafs
    global internets

    for leaf in leafs:
        leaf[1].teardown()
    for spine in spines:
        spine[1].teardown()
    for borderleaf in borderleafs:
        borderleaf[1].teardown()
    for internet in internets:
        internet[1].teardown()
    print("Controller: all grpc server connections teared down")

def install_inital_rules_p4runtime(leafs, spines, borderleafs, internets):
    number_leafs = len(leafs)
    base_ip = "172.0.0.{0}"
    for leaf in leafs:
        first_uplink = True
        controller = leaf[1]
        for i in range(number_leafs):
            match_key = base_ip.format(i + 1)
            if match_key in leaf[0]['ip']:
                out_port = "0"
            else:
                if first_uplink:
                    out_port = "3"
                else:
                    out_port = "4"
                first_uplink = not first_uplink
            controller.table_add(table_name="tb_vxlan_routing", action_name="route", match_keys=[match_key], action_params=[out_port])

    # SPINES
    # no variable P4Runtime managed forwarding rules necessary for spines

    # BORDERLEAFS:
    # forwarding towards VTEPS in the same DC must be modifyable
    bl1 = borderleafs[0][1]
    bl1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["2"])
    bl1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["3"])
    bl1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["2"])
    bl1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["3"])

    bl2 = borderleafs[1][1]
    bl2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["2"])
    bl2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["3"])
    bl2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["2"])
    bl2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["3"])

    # BL1:
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 3
    # BL2:
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 3

    # INTERNETS
    # e.g. Internet1:
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 3
    #
    # table_add tb_ipv4_lpm ipv4_forward 10.10.1.1/24 => 4
    # table_add tb_ipv4_lpm ipv4_forward 10.20.1.1/24 => 3
    i1 = internets[0][1]
    i1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["2"])
    i1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["3"])
    i1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["2"])
    i1.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["3"])

    # Internet 2:
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 1
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 1
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 3
    #
    # table_add tb_ipv4_lpm ipv4_forward 10.10.1.1/24 => 2
    # table_add tb_ipv4_lpm ipv4_forward 10.20.1.1/24 => 4
    i2 = internets[1][1]
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["1"])
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["2"])
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["1"])
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["2"])
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["2"])
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["3"])
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["2"])
    i2.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["3"])

    # Internet 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 1
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 1
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 2
    #
    # table_add tb_ipv4_lpm ipv4_forward 10.10.1.1/24 => 1
    # table_add tb_ipv4_lpm ipv4_forward 10.20.1.1/24 => 2
    i3 = internets[2][1]
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["2"])
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["1"])
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["2"])
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["1"])
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["3"])
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["2"])
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["3"])
    i3.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["2"])

    # Internet 4
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 3
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 2
    # table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 3
    i4 = internets[3][1]
    i4.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["2"])
    i4.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["3"])
    i4.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["2"])
    i4.table_add(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["3"])

    print("Controller: initial rule configuration has been installed!")


def reset_initial_rules_p4runtime(leafs, spines, borderleafs, internets):
    number_leafs = len(leafs)
    base_ip = "172.0.0.{0}"
    for leaf in leafs:
        first_uplink = True
        controller = leaf[1]
        for i in range(number_leafs):
            match_key = base_ip.format(i + 1)
            if match_key in leaf[0]['ip']:
                out_port = "0"
            else:
                if first_uplink:
                    out_port = "3"
                else:
                    out_port = "4"
                first_uplink = not first_uplink
            controller.table_modify_match(table_name="tb_vxlan_routing", action_name="route", match_keys=[match_key], action_params=[out_port])

    bl1 = borderleafs[0][1]
    bl1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["2"])
    bl1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["3"])
    bl1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["2"])
    bl1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["3"])

    bl2 = borderleafs[1][1]
    bl2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["2"])
    bl2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["3"])
    bl2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["2"])
    bl2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["3"])

    i1 = internets[0][1]
    i1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["2"])
    i1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["3"])
    i1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["2"])
    i1.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["3"])

    i2 = internets[1][1]
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["1"])
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["2"])
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["1"])
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["2"])
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["2"])
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["3"])
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["2"])
    i2.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["3"])

    i3 = internets[2][1]
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["2"])
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["1"])
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["2"])
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["1"])
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.5"], action_params=["3"])
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.6"], action_params=["2"])
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.7"], action_params=["3"])
    i3.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.8"], action_params=["2"])

    i4 = internets[3][1]
    i4.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.1"], action_params=["2"])
    i4.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.2"], action_params=["3"])
    i4.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.3"], action_params=["2"])
    i4.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=["172.0.0.4"], action_params=["3"])

    print("Controller: Rules have been reset!")


def handle_pkt(pkt):
    global leafs
    global spines
    global borderleafs
    global internets
    global dequeHandler
    global statsHandler
    global program
    global start_time
    global stats_file

    # print("Controller got a packet")

    int_info = handle_pkt_collector(pkt)
    # print(int_info)

    # if it is a one-hop flow, no rerouting can be triggered
    if (len(int_info['data']) - 1) == 1:
        return

    src_vtep = next((leaf[0] for leaf[0] in leafs if int_info['ip_src_vtep'] in leaf[0][0]['ip']), None)
    dst_vtep = next((leaf[0] for leaf[0] in leafs if int_info['ip_dst_vtep'] in leaf[0][0]['ip']), None)

    tmp_name = "{}to{}".format(src_vtep[0]['name'], dst_vtep[0]['name'])
    if (dequeHandler.getDeque(tmp_name) == None):
        dequeHandler.initDeque(tmp_name)
    tmp_deque = dequeHandler.getDeque(tmp_name)

    tmp_stats = {}
    if tmp_name in statsHandler.getStats():
        tmp_stats = statsHandler.getStats()[tmp_name]
    else:
        tmp_stats["reroute_triggered"] = 0
        tmp_stats["packet_count"] = 0
        tmp_stats["highest_inthop_latency"] = 0
        tmp_stats["average_inthop_latency"] = 0
        tmp_stats["highest_tstamp_latency"] = 0
        tmp_stats["average_tstamp_latency"] = 0
        tmp_stats["tstamp_latency_over_200ms"] = 0
        tmp_stats["events"] = []

    if (int_info["data"]["total_inthop_latency"] > tmp_stats["highest_inthop_latency"]):
        tmp_stats["highest_inthop_latency"] = int_info["data"]["total_inthop_latency"]
    if (int_info["tstamp_latency"] > tmp_stats["highest_tstamp_latency"]):
        tmp_stats["highest_tstamp_latency"] = int_info["tstamp_latency"]
    if (int_info["tstamp_latency"] > 200):
        tmp_stats["tstamp_latency_over_200ms"] += 1
    tmp_stats["average_tstamp_latency"] = (tmp_stats["packet_count"] * tmp_stats["average_tstamp_latency"] + int_info["tstamp_latency"]) / (tmp_stats["packet_count"] + 1)
    tmp_stats["average_inthop_latency"] = (tmp_stats["packet_count"] * tmp_stats["average_inthop_latency"] + int_info["data"]["total_inthop_latency"]) / (tmp_stats["packet_count"] + 1)
    tmp_stats["average_tstamp_latency"] = round(tmp_stats["average_tstamp_latency"])
    tmp_stats["average_inthop_latency"] = round(tmp_stats["average_inthop_latency"])

    tmp_stats["packet_count"] = tmp_stats["packet_count"] + 1

    tmp_deque.append(int_info["tstamp_latency"])
    if (len(tmp_deque) > 50):

        last_50_to_30 = list(tmp_deque)[-50:-30]
        last_15 = list(tmp_deque)[-15:]
        trigger_msg = None
        if (mean(last_15) / mean(last_50_to_30)) >= trigger or dequeHandler.getDequeAverage(tmp_name) > 200:
            if mean(last_15) / mean(last_50_to_30) >= trigger:
                trigger_msg = "average of last 15 ({}) more than {}-times higher than last 30 to 50 ({})".format(mean(last_15), trigger, mean(last_50_to_30))
                trigger_type = "dyn_trigger"
            if dequeHandler.getDequeAverage(tmp_name) > 200:
                trigger_msg = "current average timestamp latency higher than 200ms ({})".format(dequeHandler.getDequeAverage(tmp_name))
                trigger_type = "fallback_trigger"
            if mean(last_15) / mean(last_50_to_30) >= trigger and dequeHandler.getDequeAverage(tmp_name) > 200:
                trigger_msg = "Triggered based on both conditions: average of last 15 ({}) being more than {}-times higher than of last 30 to 50 ({}) AND current average timestamp latency deque being higher than 200ms ({})".format(mean(last_15), trigger, mean(last_50_to_30), dequeHandler.getDequeAverage(tmp_name))
                trigger_type = "both_triggers"
            if program == "rerouting":
                tmp_stats["reroute_triggered"] = tmp_stats["reroute_triggered"] + 1
                tmp_stats["events"].append([datetime.now().strftime("%H:%M:%S.%f"), "{}s in experiment".format(round((time.time() - start_time), 2)), last_15, trigger_type, trigger_msg])
                update_forwarding_rules(int_info, src_vtep, dst_vtep)
            if program == "probed":
                tmp_stats["reroute_triggered"] = tmp_stats["reroute_triggered"] + 1
                tmp_stats["events"].append([datetime.now().strftime("%H:%M:%S.%f"), "{}s in experiment".format(round((time.time() - start_time), 2)), last_15, trigger_type, trigger_msg])
            tmp_deque.clear()
            # if trigger_msg is not None:
            #     print(trigger_msg)

    statsHandler.getStats()[tmp_name] = tmp_stats


def update_forwarding_rules(int_info, src_vtep, dst_vtep):
    # print("preparing rule updates")

    # if packet has only 3 hops: definitely new spine required
    # if not required, check if local spine hop succeeds 30ms latency
    new_spine_required = False
    if (len(int_info['data']) - 1) == 3:
        new_spine_required = True
    if int_info['data']['hop_2']['hop_latency'] > 5 or new_spine_required == True:
        if int_info['data']['hop_1']['egress_port'] == 3:
            new_egress_port = "4"
            src_vtep[0]['current_spine'] = 2
        elif int_info["data"]["hop_1"]["egress_port"] == 4:
            new_egress_port = "3"
            src_vtep[0]['current_spine'] = 1
        # print("new spine set in working conf")

        controller = src_vtep[1]
        # print("updating rule on {}".format(src_vtep[0]['name']))
        # print("new uplink spine: {}".format(src_vtep[0]['current_spine']))
        controller.table_modify_match(table_name="tb_vxlan_routing", action_name="route", match_keys=[dst_vtep[0]['ip'].split('/')[0]], action_params=[new_egress_port])

    # if cross-dc traffic is being captured
    if (src_vtep[0]['dc'] == "1" and dst_vtep[0]['dc'] == "2") or (src_vtep[0]['dc'] == "2" and dst_vtep[0]['dc'] == "1"):

        # non_vtep_base_cmd = "table_modify tb_ipv4_lpm ipv4_forward {} ".format(current_dst_vtep_index)

        # print("building new internet path")
        # figure out traffic direction for 'new path' selection
        if (src_vtep[0]['dc'] == "1" and dst_vtep[0]['dc'] == "2"):
            direction = "dc1_to_dc2_paths"
        if (src_vtep[0]['dc'] == "2" and dst_vtep[0]['dc'] == "1"):
            direction = "dc2_to_dc1_paths"

        # Internet hops
        current_path_to = dst_vtep[0]['path_to_from_other_dc']
        paths=["0", "1", "2", "3"]
        paths.remove(current_path_to)
        random.shuffle(paths)
        new_path_id=int(paths[0])
        # print("current path: {}; new path: {}".format(current_path_to, new_path_id))
        dst_vtep[0]['path_to_from_other_dc'] = str(new_path_id)
        new_path = paths_list[direction][new_path_id]
        # print("new internet path for {} to {} connection".format(src_vtep[0]['name'], dst_vtep[0]['name']))
        # print("new path: {}".format(new_path['details']))
        # Last hop not required: Will always stay port 1 to send packet to dc level
        internet_hops = new_path['hops'].copy()
        internet_hops.pop()
        for hop in internet_hops:
            internet_s = next((internet[0] for internet[0] in internets if str(hop['device_id']) == str(internet[0][0]['device_id'])), None)
            controller = internet_s[1]
            # print("updating rule on {}".format(internet_s[0]['name']))
            # print("new output port: {}".format(hop['out_port']))
            controller.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=[dst_vtep[0]['ip'].split('/')[0]], action_params=[hop['out_port']])


        # Dst BL to Spine hop
        if int_info['data']["hop_5"]["hop_latency"] > 5:
            if dst_vtep[0]['dc'] == "1":
                borderleaf_s = borderleafs[0]
            elif dst_vtep[0]['dc'] == "2":
                borderleaf_s = borderleafs[1]
            controller = borderleaf_s[1]
            if int_info["data"]["hop_4"]["egress_port"] == 2:
                new_egress_port = "3"
            elif int_info["data"]["hop_4"]["egress_port"] == 3:
                new_egress_port = "2"
            # print("updating rule on {}".format(borderleaf_s[0]['name']))
            # print("new output port to spine level: {}".format(new_egress_port))
            controller.table_modify_match(table_name="tb_ipv4_lpm", action_name="ipv4_forward", match_keys=[dst_vtep[0]['ip'].split('/')[0]], action_params=[new_egress_port])

def handler(signum, frame):
    global statsHandler
    # print("Controller: sigint handler triggered...")
    with open("tmp_ctlr_logs/{}_{}_{}_controllerstats.json".format(scenario, program, run), 'w') as f:
        f.write(json.dumps(statsHandler.getStats(), indent = 2))
        f.close()
    teardown_grpc_connections()
    exit(1)

def terminate_controller():
    print("Terminating controller...")
    exit(1)

with open("conf/topo_conf.json") as conf:
    working_conf = json.load(conf)

with open("utils/paths.json") as paths_file:
    paths_list = json.load(paths_file)

hostname = "ctlr"
scenario = sys.argv[1]
program = sys.argv[2]
run = sys.argv[3]
start_time = float(sys.argv[4])
if start_time == 0:
    start_time = time.time()
initial_config_done = sys.argv[5]
trigger = float(sys.argv[6])

leafs = []
spines = []
borderleafs = []
internets = []

# try:
#     stats_file = open("tmp_ctlr_logs/{}_{}_{}_controllerstats.json".format(scenario, program, run), 'w')
# except:
#     print("Controller: stats file did not open")
# time.sleep(3)
# terminate_controller()

for leaf in working_conf['switches']['leafs']:
    try:
        tmp_leaf = [leaf, SimpleSwitchP4RuntimeAPI(device_id=leaf['device_id'],
                                                    grpc_port=leaf['grpc_port'],
                                                    p4rt_path='vxlan_int_p4rt.txt',
                                                    json_path='vxlan_int.json')]
        leafs.append(tmp_leaf)
    except:
        print("Controller: connecting to {} failed, trying again in 1 second".format(leaf['name']))
        time.sleep(1)
        try:
            tmp_leaf = [leaf, SimpleSwitchP4RuntimeAPI(device_id=leaf['device_id'],
                                                        grpc_port=leaf['grpc_port'],
                                                        p4rt_path='vxlan_int_p4rt.txt',
                                                        json_path='vxlan_int.json')]
            leafs.append(tmp_leaf)
        except:
            print("Controller: can't connect to {}. Exiting...".format(leaf['name']))
            # terminate_controller()

for spine in working_conf['switches']['spines']:
    try:
        tmp_spine = [spine, SimpleSwitchP4RuntimeAPI(device_id=spine['device_id'],
                                                    grpc_port=spine['grpc_port'],
                                                    p4rt_path='vxlan_int_p4rt.txt',
                                                    json_path='vxlan_int.json')]
        spines.append(tmp_spine)
    except:
        print("Controller: connecting to {} failed, trying again in 1 second".format(spine['name']))
        time.sleep(1)
        try:
            tmp_leaf = [spine, SimpleSwitchP4RuntimeAPI(device_id=spine['device_id'],
                                                        grpc_port=spine['grpc_port'],
                                                        p4rt_path='vxlan_int_p4rt.txt',
                                                        json_path='vxlan_int.json')]
            spines.append(tmp_spine)
        except:
            print("Controller: can't connect to {}. Exiting...".format(spine['name']))
            # terminate_controller()

for borderleaf in working_conf['switches']['borderleafs']:
    try:
        tmp_borderleaf = [borderleaf, SimpleSwitchP4RuntimeAPI(device_id=borderleaf['device_id'],
                                                    grpc_port=borderleaf['grpc_port'],
                                                    p4rt_path='vxlan_int_p4rt.txt',
                                                    json_path='vxlan_int.json')]
        borderleafs.append(tmp_borderleaf)
    except:
        print("Controller: connecting to {} failed, trying again in 1 second".format(borderleaf['name']))
        time.sleep(1)
        try:
            tmp_borderleaf = [borderleaf, SimpleSwitchP4RuntimeAPI(device_id=borderleaf['device_id'],
                                                        grpc_port=borderleaf['grpc_port'],
                                                        p4rt_path='vxlan_int_p4rt.txt',
                                                        json_path='vxlan_int.json')]
            borderleafs.append(tmp_borderleaf)
        except:
            print("Controller: can't connect to {}. Exiting...".format(borderleaf['name']))
            # terminate_controller()

for internet in working_conf['switches']['internets']:
    try:
        tmp_internet = [internet, SimpleSwitchP4RuntimeAPI(device_id=internet['device_id'],
                                                    grpc_port=internet['grpc_port'],
                                                    p4rt_path='ipv4_lpm_p4rt.txt',
                                                    json_path='ipv4_lpm.json')]
        internets.append(tmp_internet)
    except:
        print("Controller: connecting to {} failed, trying again in 1 second".format(internet['name']))
        time.sleep(1)
        try:
            tmp_internet = [internet, SimpleSwitchP4RuntimeAPI(device_id=internet['device_id'],
                                                        grpc_port=internet['grpc_port'],
                                                        p4rt_path='ipv4_lpm_p4rt.txt',
                                                        json_path='ipv4_lpm.json')]
            internets.append(tmp_internet)
        except:
            print("Controller: can't connect to {}. Exiting...".format(internet['name']))
            # terminate_controller()


if initial_config_done == "True" and program == "rerouting":
    reset_initial_rules_p4runtime(leafs, spines, borderleafs, internets)
elif initial_config_done == "False":
    install_inital_rules_p4runtime(leafs, spines, borderleafs, internets)
else:
    print("Controller: no initial controller action required")

signal.signal(signal.SIGINT, handler)

if program == "rerouting" or program == "probed":
    rerouting_stats = {}

    dequeHandler = DequeHandler()
    statsHandler = ReroutingStatsHandler()


    ifaces = ['l1-cpu-eth0', 'l2-cpu-eth0', 'l3-cpu-eth0', 'l4-cpu-eth0', 'l5-cpu-eth0', 'l6-cpu-eth0', 'l7-cpu-eth0', 'l8-cpu-eth0']

    # print("sniffing on %s" % ifaces)
    sys.stdout.flush()
    sniff(iface = ifaces, prn = lambda x: handle_pkt(x))
