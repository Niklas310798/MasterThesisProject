#!/usr/bin/env python
import sys
import struct
import socket
import json
from datetime import datetime

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import PacketListField, ShortField, IntField, LongField, BitField, FieldListField, FieldLenField, ByteField
from scapy.all import IP, TCP, UDP, Raw
from scapy.fields import *
from scapy.layers.l2 import Ether

from scapy.all import *
from scapy.packet import *
from scapy.fields import *

class VXLAN_RAW(Packet):
    name = "hdr_vxlan"
    fields_desc = [ FlagsField("flags", 0x08, 8, ['R', 'R', 'R', 'I', 'R', 'R', 'R', 'R']),
                    ThreeBytesField("rsvd0", 0),
                    ThreeBytesField("vni", 0),
                    XByteField("rsvd1", 0x00)
    ]

class VXLAN_GPE(Packet):
    name = "hdr_vxlan_gpe"
    fields_desc = [ FlagsField("flags", 0x08, 8, ['R', 'R', 'R', 'I', 'R', 'R', 'R', 'R']),
                    ShortField("rsvd0", 0),
                    XByteField("next_proto", 0x82),
                    X3BytesField("vni", 100),
                    XByteField("rsvd1", 0x00)
    ]

class HDR_INT_SHIM(Packet):
    name = "hdr_int_shim"
    fields_desc = [
        XByteField("int_type", 0),
        XByteField("len", 3),
        XByteField("rsvd", 0),
        XByteField("next_proto", 0),
    ]

class HDR_INT(Packet):
    name = "hdr_int"
    fields_desc = [
        BitField("ver", 0, 4),
        BitField("rep", 0, 2),
        BitField("c", 0, 1),
        BitField("e", 0, 1),
        BitField("m", 0, 1),
        BitField("rsvd1", 0, 7),
        BitField("rsvd2", 0, 3),
        BitField("hop_metadata_len", 0, 5),
        XByteField("remaining_hop_cnt", 0),
        BitField("instruction_mask_0003", 0, 4),
        BitField("instruction_mask_0407", 0, 4),
        BitField("instruction_mask_0811", 0, 4),
        BitField("instruction_mask_1215", 0, 4),
        BitField("rsvd3", 0, 16)
    ]

class EXTENDED_SIMPLE_INT_META_BOS(Packet):
    name = "ext_simple_int_meta_values_bos"
    fields_desc = [
        BitField("bos", 0, 8),
        BitField("switch_id", 0, 24),
        BitField("ingress_port", 0, 16),
        BitField("egress_port", 0, 16),
        BitField("hop_latency", 0, 32),
        BitField("ingress_tstamp", 0, 48),
        BitField("egress_tstamp", 0, 48),
    ]

def handle_pkt_collector(packet):
    info = { }

    info["rec_time"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
    info["data"] = {}

    pkt = bytes(packet)

    TCP_PROTO = 6
    UDP_PROTO = 17

    ETHERNET_HEADER_LENGTH = 14
    IP_HEADER_LENGTH = 20
    UDP_HEADER_LENGTH = 8
    TCP_HEADER_LENGTH = 20
    VXLAN_HEADER_LENGTH = 8

    INT_SHIM_LENGTH = 4
    INT_META_LENGTH = 8
    INT_REPORT_HEADER_LENGTH = 24

    OUTER_ETHERNET_OFFSET = 0
    OUTER_IP_HEADER = OUTER_ETHERNET_OFFSET + ETHERNET_HEADER_LENGTH
    OUTER_L4_HEADER_OFFSET = OUTER_IP_HEADER + IP_HEADER_LENGTH
    OUTER_L4_HEADER = OUTER_L4_HEADER_OFFSET + UDP_HEADER_LENGTH

    eth_report = Ether(pkt[0:ETHERNET_HEADER_LENGTH])
    ip_report = IP(pkt[OUTER_IP_HEADER:OUTER_IP_HEADER+IP_HEADER_LENGTH])
    udp_report = UDP(pkt[OUTER_L4_HEADER_OFFSET:OUTER_L4_HEADER])

    VXLAN_HEADER_OFFSET = OUTER_L4_HEADER
    VXLAN_HEADER = VXLAN_HEADER_OFFSET + VXLAN_HEADER_LENGTH
    INT_SHIM_OFFSET = VXLAN_HEADER
    INT_SHIM = INT_SHIM_OFFSET + INT_SHIM_LENGTH
    INT_META_OFFSET = INT_SHIM
    INT_META = INT_META_OFFSET + INT_META_LENGTH

    raw_payload = bytes(packet[Raw]) # to get payload
    vxlan_report = VXLAN_GPE(pkt[VXLAN_HEADER_OFFSET:VXLAN_HEADER])
    int_shim_report = HDR_INT_SHIM(pkt[INT_SHIM_OFFSET:INT_SHIM])
    int_meta_report = HDR_INT(pkt[INT_META_OFFSET:INT_META])

    INT_METADATA_STACK_OFFSET = INT_META

    hop_number=6-int(str(int_meta_report.remaining_hop_cnt), 16)
    stack_payload = pkt[INT_METADATA_STACK_OFFSET:INT_METADATA_STACK_OFFSET+(hop_number*INT_REPORT_HEADER_LENGTH)]

    hops=[]
    hop_counter=0
    for hop in range(hop_number):
        begin_hop=hop_counter*INT_REPORT_HEADER_LENGTH
        end_hop=(hop_counter+1)*INT_REPORT_HEADER_LENGTH
        hop_data=EXTENDED_SIMPLE_INT_META_BOS(stack_payload[begin_hop:end_hop])
        hops.append(hop_data)

        hop_counter+=1
    hops.reverse()

    INNER_HEADERS_OFFSET = INT_METADATA_STACK_OFFSET+(hop_number*INT_REPORT_HEADER_LENGTH)
    inner_headers = pkt[INNER_HEADERS_OFFSET:INNER_HEADERS_OFFSET+42]
    inner_ethernet = Ether(inner_headers[:ETHERNET_HEADER_LENGTH])
    inner_ipv4 = IP(inner_headers[14:34])
    if inner_ipv4.proto == 17:
        inner_udp = UDP(inner_headers[34:42])
    if inner_ipv4.proto == 6:
        inner_tcp = TCP(inner_headers[34:54])

    i=1
    total_latency=0
    start = hops[0].ingress_tstamp
    end = hops[len(hops)-1].egress_tstamp
    for hop in hops:
        info["data"]["hop_%d" % i] = {}
        info["data"]["hop_%d" % i]["switch_id"] = hop.switch_id
        info["data"]["hop_%d" % i]["ingress_port"] = hop.ingress_port
        info["data"]["hop_%d" % i]["egress_port"] = hop.egress_port
        info["data"]["hop_%d" % i]["hop_latency"] = hop.hop_latency
        info["data"]["hop_%d" % i]["ingress_tstamp"] = hop.ingress_tstamp
        info["data"]["hop_%d" % i]["egress_tstamp"] = hop.egress_tstamp
        total_latency += hop.hop_latency
        i+=1

    # latency/timestamp values in mikro seconds -> divided by 1000 for milliseconds
    info["data"]["total_inthop_latency"] = round(total_latency / 1000, 2)
    info["ip_src"] = (inner_ipv4.src).strip("'")
    info["start"] = start
    info["ip_dst"] = (inner_ipv4.dst).strip("'")
    info["end"] = end
    info["tstamp_latency"] = round((end - start) / 1000, 2)
    info["ip_src_vtep"] = (ip_report.src).strip("'")
    info["ip_dst_vtep"] = (ip_report.dst).strip("'")
    info["ip_proto"] = inner_ipv4.proto

    return info

    sys.stdout.flush()
