from p4utils.mininetlib.network_API import NetworkAPI
import json
import subprocess

with open("conf/topo_conf.json") as conf:
    topo_conf = json.load(conf)

with open("conf/experiment_conf.json") as conf:
    exp_conf = json.load(conf)

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.enableCli()
net.setCompiler(p4rt=True)

hosts = []
leafs = []
spines = []
borderleafs = []
internets = []

for leaf in topo_conf['switches']['leafs']:
    leafs.append(net.addP4RuntimeSwitch(leaf['name'], **{"device_id": leaf['device_id']}))
    net.setP4Source(leaf['name'], 'vxlan_int.p4')
    net.enableCpuPort(leaf['name'])
    net.setGrpcPort(leaf['name'], leaf['grpc_port'])
    net.setThriftPort(leaf['name'], leaf['thrift_port'])

for spine in topo_conf['switches']['spines']:
    spines.append(net.addP4RuntimeSwitch(spine['name'], **{"device_id": spine['device_id']}))
    net.setP4Source(spine['name'], 'vxlan_int.p4')
    net.setGrpcPort(spine['name'], spine['grpc_port'])
    net.setThriftPort(spine['name'], spine['thrift_port'])

for borderleaf in topo_conf['switches']['borderleafs']:
    borderleafs.append(net.addP4RuntimeSwitch(borderleaf['name'], **{"device_id": borderleaf['device_id']}))
    net.setP4Source(borderleaf['name'], 'vxlan_int.p4')
    net.setGrpcPort(borderleaf['name'], borderleaf['grpc_port'])
    net.setThriftPort(borderleaf['name'], borderleaf['thrift_port'])

for internet in topo_conf['switches']['internets']:
    internets.append(net.addP4RuntimeSwitch(internet['name'], **{"device_id": internet['device_id']}))
    net.setP4Source(internet['name'], 'ipv4_lpm.p4')
    net.setGrpcPort(internet['name'], internet['grpc_port'])
    net.setThriftPort(internet['name'], internet['thrift_port'])

for host in topo_conf['hosts']:
    hosts.append(net.addHost(host['name']))
    net.addLink(host['name'], host['default_gateway'])
    net.setIntfIp(host['name'], host['default_gateway'], host['ip'])
    net.setIntfMac(host['name'], host['default_gateway'], host['mac'])
    gw = next((gw for gw in topo_conf['switches']['leafs'] if gw['name'] == host['default_gateway']), None)
    net.setIntfIp(host['default_gateway'], host['name'], gw['ip'])


    # set switch interface MAC at some other point (if necessary, probably not)
    # net.setIntfMac(host['default_gateway'], host['name'], gw['macs'][])

for spine in spines[:2]:
    net.addLink(borderleafs[0], spine)
    for leaf in leafs[:4]:
        net.addLink(leaf, spine)
for spine in spines[-2:]:
    net.addLink(borderleafs[1], spine)
    for leaf in leafs[-4:]:
        net.addLink(leaf, spine)
net.addLink(borderleafs[0], internets[0])
net.addLink(borderleafs[1], internets[3])
net.addLink(internets[0], internets[1])
net.addLink(internets[0], internets[2])
net.addLink(internets[1], internets[2])
net.addLink(internets[3], internets[1])
net.addLink(internets[3], internets[2])


####### Cross-Traffic using two Dummy Hosts #######
# Connected to i1 and i2
# path:
# i1: in i1-eth4; out i1-eth3
# i3: in i3-eth1; out i3-eth2
# i2: in i2-eth2; out i2-eth4
#
# dummy host 1: 10.10.10.1
# dummy host 2: 10.10.10.2
net.addHost('dummy1')
net.addLink('dummy1', 'i1')
net.setIntfIp('dummy1', 'i1', '10.10.10.1/24')
net.setDefaultRoute('dummy1', '172.0.0.15/32')
net.setIntfPort('i1', 'dummy1', 4)
net.addHost('dummy2')
net.addLink('dummy2', 'i2')
net.setIntfIp('dummy2', 'i2', '10.10.10.2/24')
net.setDefaultRoute('dummy2', '172.0.0.16/32')
net.setIntfPort('i2', 'dummy2', 4)


net.setBwAll(exp_conf['dc_bandwidth_limit'])

net.setBw('i1', 'i2', exp_conf['internet_bandwidth_limit'])
net.setBw('i1', 'i3', exp_conf['internet_bandwidth_limit'])
net.setBw('i2', 'i3', exp_conf['internet_bandwidth_limit'])
net.setBw('i4', 'i3', exp_conf['internet_bandwidth_limit'])
net.setBw('i4', 'i2', exp_conf['internet_bandwidth_limit'])

net.setBw('bl1','i1', 100)
net.setBw('bl2','i4', 100)
net.setBw('l1', 'sw-cpu', 1000)
net.setBw('l2', 'sw-cpu', 1000)
net.setBw('l3', 'sw-cpu', 1000)
net.setBw('l4', 'sw-cpu', 1000)
net.setBw('l5', 'sw-cpu', 1000)
net.setBw('l6', 'sw-cpu', 1000)
net.setBw('l7', 'sw-cpu', 1000)
net.setBw('l8', 'sw-cpu', 1000)

# net.enableDebuggerAll()
net.disableLogAll()
net.disablePcapDumpAll()

# Start the network
net.startNetwork()
