#!/usr/bin/env python3

import argparse
import sys
import socket
import random
import struct
import logging
import time
import signal

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import *

logger = logging.getLogger("scapy")
logger.setLevel(logging.INFO)

def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface


def write_tcp_pkt(addr, iface):
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    # proto=6 -> TCP; proto=17 -> UDP
    pkt = pkt / IP(dst=addr,proto=6)
    pkt = pkt / TCP(dport=1234, sport=51000)
    pkt = pkt / "probe packet"

    return pkt

def write_udp_pkt(addr, iface):
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    # proto=6 -> TCP; proto=17 -> UDP
    pkt = pkt / IP(dst=addr,proto=17)
    pkt = pkt / UDP(dport=1234, sport=51000)
    pkt = pkt / "probe packet"

    return pkt

def handler(signum, frame):
    exit(1)

signal.signal(signal.SIGINT, handler)

addr = socket.gethostbyname(sys.argv[1])
iface = get_if()
pkt_count = int(sys.argv[3])
interval = float(sys.argv[4])

if sys.argv[2] == "tcp":
    pkt = write_tcp_pkt(addr, iface)
if sys.argv[2] == "udp":
    pkt = write_udp_pkt(addr, iface)

while True:
    sendp(pkt, iface=iface, count=pkt_count)
    time.sleep(interval)
