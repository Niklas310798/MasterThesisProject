#!/usr/bin/env python3
import argparse
import sys
import socket
import random
import struct
import netifaces as ni

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface

def write_tcp_pkt(ip, addr, iface):
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    # proto=6 -> TCP; proto=17 -> UDP
    pkt = pkt / IP(src=ip,dst=addr,proto=6)
    pkt = pkt / TCP(dport=1234, sport=51000)
    pkt = pkt / "probe packet"

    return pkt

def main():

    if len(sys.argv)<2:
        print('pass 1 arguments: <destination>')
        exit(1)

    addr = socket.gethostbyname(sys.argv[1])
    print("dest address", addr)
    iface = get_if()
    ip = ni.ifaddresses(iface)[ni.AF_INET][0]['addr']

    pkt = write_tcp_pkt(ip, addr, iface)

    print("sending on interface %s to %s" % (iface, str(addr)))
    pkt.show2()
    sendp(pkt, iface=iface, verbose=False)


if __name__ == '__main__':
    main()
