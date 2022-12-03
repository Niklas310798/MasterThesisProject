#!/bin/bash

# sleep 20
declare -a hosts=(h1 h2 h3 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16)

mx h1 ifconfig h1-eth0 mtu 1200
mx h2 ifconfig h2-eth0 mtu 1200
mx h3 ifconfig h3-eth0 mtu 1200
mx h4 ifconfig h4-eth0 mtu 1200
mx h5 ifconfig h5-eth0 mtu 1200
mx h6 ifconfig h6-eth0 mtu 1200
mx h7 ifconfig h7-eth0 mtu 1200
mx h8 ifconfig h8-eth0 mtu 1200
mx h9 ifconfig h9-eth0 mtu 1200
mx h10 ifconfig h10-eth0 mtu 1200
mx h11 ifconfig h11-eth0 mtu 1200
mx h12 ifconfig h12-eth0 mtu 1200
mx h13 ifconfig h13-eth0 mtu 1200
mx h14 ifconfig h14-eth0 mtu 1200
mx h15 ifconfig h15-eth0 mtu 1200
mx h16 ifconfig h16-eth0 mtu 1200

for host in "${hosts[@]}"
do
  mx ${host} ip route add 10.0.1.0/24 dev ${host}-eth0
  mx ${host} ip route add 10.0.2.0/24 dev ${host}-eth0

  mx ${host} arp -s 10.0.1.101 08:00:00:00:00:01
  mx ${host} arp -s 10.0.1.102 08:00:00:00:00:02
  mx ${host} arp -s 10.0.2.101 08:00:00:00:00:03
  mx ${host} arp -s 10.0.2.102 08:00:00:00:00:04
  mx ${host} arp -s 10.0.1.103 08:00:00:00:00:05
  mx ${host} arp -s 10.0.1.104 08:00:00:00:00:06
  mx ${host} arp -s 10.0.2.103 08:00:00:00:00:07
  mx ${host} arp -s 10.0.2.104 08:00:00:00:00:08
  mx ${host} arp -s 10.0.1.105 08:00:00:00:00:09
  mx ${host} arp -s 10.0.1.106 08:00:00:00:00:10
  mx ${host} arp -s 10.0.2.105 08:00:00:00:00:11
  mx ${host} arp -s 10.0.2.106 08:00:00:00:00:12
  mx ${host} arp -s 10.0.1.107 08:00:00:00:00:13
  mx ${host} arp -s 10.0.1.108 08:00:00:00:00:14
  mx ${host} arp -s 10.0.2.107 08:00:00:00:00:15
  mx ${host} arp -s 10.0.2.108 08:00:00:00:00:16
done

echo "Init.sh: configured hosts successfully"


# Leaf Switch 1 (VTEP 1)
simple_switch_CLI --thrift-port 9091 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.1.101 => 1
table_add tb_local_forward local_fwd 10.0.1.102 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_vtep set_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.101 10.0.2.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.102 10.0.2.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:01 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:02 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 1
EOF


# Leaf Switch 2 (VTEP 2)
simple_switch_CLI --thrift-port 9092 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.2.101 => 1
table_add tb_local_forward local_fwd 10.0.2.102 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_vtep set_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.101 10.0.2.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.102 10.0.2.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:03 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:04 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 2
EOF


# Leaf Switch 3 (VTEP 3)
simple_switch_CLI --thrift-port 9093 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.1.103 => 1
table_add tb_local_forward local_fwd 10.0.1.104 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_vtep set_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.103 10.0.2.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.104 10.0.2.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:05 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:06 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 3
EOF


# Leaf Switch 4 (VTEP 4)
simple_switch_CLI --thrift-port 9094 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.2.103 => 1
table_add tb_local_forward local_fwd 10.0.2.104 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_vtep set_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.103 10.0.2.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.104 10.0.2.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:07 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:08 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 4
EOF


# Leaf Switch 5 (VTEP 5)
simple_switch_CLI --thrift-port 9095 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.1.105 => 1
table_add tb_local_forward local_fwd 10.0.1.106 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_vtep set_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.105 10.0.2.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.106 10.0.2.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:09 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:10 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 5
EOF


# Leaf Switch 6 (VTEP 6)
simple_switch_CLI --thrift-port 9096 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.2.105 => 1
table_add tb_local_forward local_fwd 10.0.2.106 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_vtep set_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.105 10.0.2.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.106 10.0.2.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:11 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:12 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 6
EOF


# Leaf Switch 7 (VTEP 7)
simple_switch_CLI --thrift-port 9097 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.1.107 => 1
table_add tb_local_forward local_fwd 10.0.1.108 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_vtep set_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.107 10.0.2.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.1.108 10.0.2.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:13 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:14 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 7
EOF


# Leaf Switch 8 (VTEP 8)
simple_switch_CLI --thrift-port 9098 << EOF
mirroring_add 500 5
table_add tb_local_forward local_fwd 10.0.2.107 => 1
table_add tb_local_forward local_fwd 10.0.2.108 => 2
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.101 => 08:00:00:00:00:01
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.102 => 08:00:00:00:00:02
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.101 => 08:00:00:00:00:03
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.102 => 08:00:00:00:00:04
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.103 => 08:00:00:00:00:05
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.104 => 08:00:00:00:00:06
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.103 => 08:00:00:00:00:07
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.104 => 08:00:00:00:00:08
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.105 => 08:00:00:00:00:09
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.106 => 08:00:00:00:00:10
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.105 => 08:00:00:00:00:11
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.106 => 08:00:00:00:00:12
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.107 => 08:00:00:00:00:13
table_add tb_dst_ip_to_mac set_dst_mac 10.0.1.108 => 08:00:00:00:00:14
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.107 => 08:00:00:00:00:15
table_add tb_dst_ip_to_mac set_dst_mac 10.0.2.108 => 08:00:00:00:00:16
table_add tb_vtep set_vtep_ip 08:00:00:00:00:15 => 172.0.0.8
table_add tb_vtep set_vtep_ip 08:00:00:00:00:16 => 172.0.0.8
table_add tb_vxlan_segment set_vni 10.0.0.0/16 => 100
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:01 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:02 => 172.0.0.1
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:03 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:04 => 172.0.0.2
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:05 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:06 => 172.0.0.3
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:07 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:08 => 172.0.0.4
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:09 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:10 => 172.0.0.5
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:11 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:12 => 172.0.0.6
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:13 => 172.0.0.7
table_add tb_peer_vtep set_peer_vtep_ip 08:00:00:00:00:14 => 172.0.0.7
table_add tb_activate_source activate_source 1 =>
table_add tb_activate_source activate_source 2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.101 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.102 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.103 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.104 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.105 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.106 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.107 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.108 0x4D2 0xC738 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.108 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.101 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.102 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.103 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.104 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.105 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.2.106 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.107 0xC738 0x4D2 =>
table_add tb_flow_monitor mark_monitored_flow 10.0.2.108 10.0.1.108 0xC738 0x4D2 =>
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:15 => 1
table_add tb_vxlan_forward_l2 forward 08:00:00:00:00:16 => 2
table_add tb_int_sink configure_sink 1 => 5
table_add tb_int_sink configure_sink 2 => 5
table_add tb_int_transit configure_transit => 8
EOF


# Spine Switch 1
simple_switch_CLI --thrift-port 9099 << EOF
table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 2
table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 3
table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 4
table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 5
table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 1
table_add tb_int_transit configure_transit => 9
EOF


# Spine Switch 2
simple_switch_CLI --thrift-port 9100 << EOF
table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 2
table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 3
table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 4
table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 5
table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 1
table_add tb_int_transit configure_transit => 10
EOF


# Spine Switch 3
simple_switch_CLI --thrift-port 9101 << EOF
table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 2
table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 3
table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 4
table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 5
table_add tb_int_transit configure_transit => 11
EOF


# Spine Switch 4
simple_switch_CLI --thrift-port 9102 << EOF
table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 2
table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 3
table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 4
table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 5
table_add tb_int_transit configure_transit => 12
EOF


# Border Leaf Switch 1 (id 13)
simple_switch_CLI --thrift-port 9103 << EOF
mirroring_add 500 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 1
table_add tb_int_transit configure_transit => 13
EOF


# Border Leaf Switch 2 (id 14)
simple_switch_CLI --thrift-port 9104 << EOF
mirroring_add 500 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 1
table_add tb_int_transit configure_transit => 14
EOF


# Internet 1
simple_switch_CLI --thrift-port 9105 << EOF
table_add tb_ipv4_lpm ipv4_forward 172.0.0.1/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.2/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.3/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.4/32 => 1
table_set_default tb_ipv4_lpm drop
EOF


# Internet 2
simple_switch_CLI --thrift-port 9106 << EOF
table_set_default tb_ipv4_lpm drop
EOF


# Internet 3
simple_switch_CLI --thrift-port 9107 << EOF
table_set_default tb_ipv4_lpm drop
EOF


# Internet 4
simple_switch_CLI --thrift-port 9108 << EOF
table_add tb_ipv4_lpm ipv4_forward 172.0.0.5/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.6/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.7/32 => 1
table_add tb_ipv4_lpm ipv4_forward 172.0.0.8/32 => 1
table_set_default tb_ipv4_lpm drop
EOF


echo "Init.sh: configured switch nodes successfully"
