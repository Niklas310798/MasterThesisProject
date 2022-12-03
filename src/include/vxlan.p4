/********************************************************************
*  VXLAN Ingress Handling
*******************************************************************/


// in case of vxlan-encapped packets packet that arrived, do following steps
// - determine whether match for dst VM mac address is defined in table
// - if match is found, dst VM is connected to switch port
//   -> forward to corresponding egress port and mark as tunnel_end packet in meta
// - if no match is found, dst VM is not directly connected to switch
//   -> perform IPv4 LPM forwarding based on outer IP dst address (dst VTEP)
control vxlan_ingress_upstream(inout headers hdr,
                               inout metadata meta,
                               inout standard_metadata_t standard_metadata) {


    action forward(bit<9> port) {
        standard_metadata.egress_spec = port;
        meta.vxlan_metadata.tunnel_end = 1;
        meta.vxlan_metadata.final_egress_port = port;
    }

    table tb_vxlan_forward_l2 {
        key = {
            hdr.inner_ethernet.dstAddr : exact;
        }

        actions = {
            forward;
        }
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table tb_ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            if (hdr.vxlan_gpe.isValid() || hdr.vxlan.isValid()) {
                if (!tb_vxlan_forward_l2.apply().hit) {
                    tb_ipv4_lpm.apply();
                }
            }
        }
    }
}


// in case of non-vxlan encapped packet arriving at switch, do following steps
// - determine dst VM mac address and write into ethernet header
// - determine src VTEP IP address based on src VM mac address
// - determine VXLAN segment based on dst VM IP address
// - determine dst (peer) VTEP IP address based on dst VM mac address
// - determine output port based on IPv4 forwarding to dst VTEP IP address
control vxlan_ingress_downstream(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

    // match IP of dst VM to MAC address of dst VM
    action set_dst_mac(bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }

    table tb_dst_ip_to_mac {
        key = {
            hdr.ipv4.dstAddr : exact;
        }

        actions = {
            set_dst_mac;
        }
    }

    // determine IP of source VTEP, corresponding to src VM's MAC address
    // e.g. source VM MAC 08:00:00:00:00:02 behind VTEP with IP 172.0.0.2

    // save src VTEP ip in meta construct to set src IP in IP header in egress block
    action set_vtep_ip(bit<32> vtep_ip) {
        meta.vxlan_metadata.vtep_ip = vtep_ip;
    }

    // match exact src VM's MAC address to src VTEPs IP
    table tb_vtep {
        key = {
            hdr.ethernet.srcAddr : exact;
        }

        actions = {
            set_vtep_ip;
        }

    }

    // check IP of destination VM, assign corresponding VNI value
    // e.g. IPs in segment 10.0.0.0/8 -> assign VNI 10

    // save VNI in meta construct to set VNI in VXLAN_GPE header in egress block
    action set_vni(bit<24> vni) {
        meta.vxlan_metadata.vxlan_vni = vni;
    }

    // match IP segment to VNI
    table tb_vxlan_segment {

        key = {
            hdr.ipv4.dstAddr : lpm;
        }

        actions = {
            @defaultonly NoAction;
            set_vni;
        }

    }

    // determine IP of peer VTEP, corresponding to dst VM's MAC address
    // e.g. 08:00:00:00:00:01 behind VTEP with IP 172.0.0.1

    // save peer VTEP IP in meta construct, to set dst IP in IP header in egress block
    action set_peer_vtep_ip(bit<32> peer_vtep_ip) {
        meta.vxlan_metadata.peer_vtep_ip = peer_vtep_ip;
    }

    // match exact dst VM's MAC address to peer VTEP's IP
    table tb_peer_vtep {

        key = {
            hdr.ethernet.dstAddr : exact;
        }

        actions = {
            set_peer_vtep_ip;
        }
    }

    action route(bit<9> port) {
        standard_metadata.egress_spec = port;
    }

    table tb_vxlan_routing {

        key = {
            meta.vxlan_metadata.peer_vtep_ip : exact;
        }

        actions = {
            route;
        }
    }

    apply {
        if (hdr.ipv4.isValid()) {
            tb_dst_ip_to_mac.apply();
            tb_vtep.apply();
            if(tb_vxlan_segment.apply().hit) {
                if(tb_peer_vtep.apply().hit) {
                    tb_vxlan_routing.apply();
                }
            }
        }
    }
}


/********************************************************************
*  VXLAN Egress Handling
*******************************************************************/


// in case of vxlan-encapped packets that arrived at dst VTEP
// must be decapped from outer headers and vxlan header
control vxlan_egress_upstream(inout headers hdr,
                              inout metadata meta,
                              inout standard_metadata_t standard_metadata) {

    action vxlan_gpe_decap() {
        // as simple as set outer headers as invalid
        hdr.ethernet.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.vxlan_gpe.setInvalid();
    }

    action vxlan_decap() {
        // as simple as set outer headers as invalid
        hdr.ethernet.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.vxlan.setInvalid();
    }

    apply {
        if (standard_metadata.instance_type == 0 && meta.vxlan_metadata.tunnel_end == 1) {
            if (hdr.vxlan_gpe.isValid()) {
                vxlan_gpe_decap();
            }
            if (hdr.vxlan.isValid()) {
                vxlan_decap();
            }
        }
    }
}


#define ETH_HDR_SIZE 14
#define IPV4_HDR_SIZE 20
#define UDP_HDR_SIZE 8
#define VXLAN_GPE_HDR_SIZE 8
#define IP_VERSION_4 4
#define IPV4_MIN_IHL 5

// in case of non-encapped packets coming into egress pipeline
// vxlan metadata must be set by the downstream ingress control block
control vxlan_egress_downstream(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {


    action vxlan_gpe_tcp_encap() {

        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_ipv4.protocol = 6;

        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();

        hdr.ethernet.setValid();

        hdr.ipv4.setValid();
        hdr.ipv4.version = IP_VERSION_4;
        hdr.ipv4.ihl = IPV4_MIN_IHL;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen
                            + (ETH_HDR_SIZE + IPV4_HDR_SIZE + UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.ipv4.id = 0x1513; /* From NGIC */
        hdr.ipv4.flags = 0;
        hdr.ipv4.fragOffset = 0;
        hdr.ipv4.ttl = 64;
        hdr.ipv4.protocol = 17;
        hdr.ipv4.dstAddr = meta.vxlan_metadata.peer_vtep_ip;
        hdr.ipv4.srcAddr = meta.vxlan_metadata.vtep_ip;
        hdr.ipv4.hdrChecksum = 0;

        hdr.udp.setValid();
        // The VTEP calculates the source port by performing the hash of the inner Ethernet frame's header.
        hash(hdr.udp.srcPort, HashAlgorithm.crc16, (bit<13>)0, { hdr.inner_ethernet }, (bit<32>)65536);
        hdr.udp.dstPort = 4800;
        hdr.udp.len = hdr.ipv4.totalLen + (UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.udp.csum = 0;

        hdr.vxlan_gpe.setValid();
        hdr.vxlan_gpe.flags = 0;
        hdr.vxlan_gpe.rsvd0 = 0;
        hdr.vxlan_gpe.next_proto = 0x82;
        hdr.vxlan_gpe.vni = meta.vxlan_metadata.vxlan_vni;
        hdr.vxlan_gpe.rsvd1 = 0;
    }

    action vxlan_gpe_udp_encap() {

        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_ipv4.protocol = 17;

        hdr.inner_udp= hdr.udp;

        hdr.ethernet.setValid();

        hdr.ipv4.setValid();
        hdr.ipv4.version = IP_VERSION_4;
        hdr.ipv4.ihl = IPV4_MIN_IHL;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen
                            + (ETH_HDR_SIZE + IPV4_HDR_SIZE + UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.ipv4.id = 0x1513; /* From NGIC */
        hdr.ipv4.flags = 0;
        hdr.ipv4.fragOffset = 0;
        hdr.ipv4.ttl = 64;
        hdr.ipv4.protocol = 17;
        hdr.ipv4.dstAddr = meta.vxlan_metadata.peer_vtep_ip;
        hdr.ipv4.srcAddr = meta.vxlan_metadata.vtep_ip;
        hdr.ipv4.hdrChecksum = 0;

        hdr.udp.setValid();
        // The VTEP calculates the source port by performing the hash of the inner Ethernet frame's header.
        hash(hdr.udp.srcPort, HashAlgorithm.crc16, (bit<13>)0, { hdr.inner_ethernet }, (bit<32>)65536);
        hdr.udp.dstPort = 4800;
        hdr.udp.len = hdr.ipv4.totalLen + (UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.udp.csum = 0;

        hdr.vxlan_gpe.setValid();
        hdr.vxlan_gpe.flags = 0;
        hdr.vxlan_gpe.rsvd0 = 0;
        hdr.vxlan_gpe.next_proto = 0x82;
        hdr.vxlan_gpe.vni = meta.vxlan_metadata.vxlan_vni;
        hdr.vxlan_gpe.rsvd1 = 0;
    }

    action vxlan_tcp_encap() {

        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_ipv4.protocol = 6;

        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();

        hdr.ethernet.setValid();

        hdr.ipv4.setValid();
        hdr.ipv4.version = IP_VERSION_4;
        hdr.ipv4.ihl = IPV4_MIN_IHL;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen
                            + (ETH_HDR_SIZE + IPV4_HDR_SIZE + UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.ipv4.id = 0x1513; /* From NGIC */
        hdr.ipv4.flags = 0;
        hdr.ipv4.fragOffset = 0;
        hdr.ipv4.ttl = 64;
        hdr.ipv4.protocol = 17;
        hdr.ipv4.dstAddr = meta.vxlan_metadata.peer_vtep_ip;
        hdr.ipv4.srcAddr = meta.vxlan_metadata.vtep_ip;
        hdr.ipv4.hdrChecksum = 0;

        hdr.udp.setValid();
        // The VTEP calculates the source port by performing the hash of the inner Ethernet frame's header.
        hash(hdr.udp.srcPort, HashAlgorithm.crc16, (bit<13>)0, { hdr.inner_ethernet }, (bit<32>)65536);
        hdr.udp.dstPort = 4789;
        hdr.udp.len = hdr.ipv4.totalLen + (UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.udp.csum = 0;

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 0;
        hdr.vxlan.rsvd0 = 0;
        hdr.vxlan.vni = meta.vxlan_metadata.vxlan_vni;
        hdr.vxlan.rsvd1 = 0;
    }

    action vxlan_udp_encap() {

        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_ipv4.protocol = 17;

        hdr.inner_udp= hdr.udp;

        hdr.ethernet.setValid();

        hdr.ipv4.setValid();
        hdr.ipv4.version = IP_VERSION_4;
        hdr.ipv4.ihl = IPV4_MIN_IHL;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen
                            + (ETH_HDR_SIZE + IPV4_HDR_SIZE + UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.ipv4.id = 0x1513; /* From NGIC */
        hdr.ipv4.flags = 0;
        hdr.ipv4.fragOffset = 0;
        hdr.ipv4.ttl = 64;
        hdr.ipv4.protocol = 17;
        hdr.ipv4.dstAddr = meta.vxlan_metadata.peer_vtep_ip;
        hdr.ipv4.srcAddr = meta.vxlan_metadata.vtep_ip;
        hdr.ipv4.hdrChecksum = 0;

        hdr.udp.setValid();
        // The VTEP calculates the source port by performing the hash of the inner Ethernet frame's header.
        hash(hdr.udp.srcPort, HashAlgorithm.crc16, (bit<13>)0, { hdr.inner_ethernet }, (bit<32>)65536);
        hdr.udp.dstPort = 4789;
        hdr.udp.len = hdr.ipv4.totalLen + (UDP_HDR_SIZE + VXLAN_GPE_HDR_SIZE);
        hdr.udp.csum = 0;

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 0;
        hdr.vxlan.rsvd0 = 0;
        hdr.vxlan.vni = meta.vxlan_metadata.vxlan_vni;
        hdr.vxlan.rsvd1 = 0;
    }

    apply {
        if (meta.vxlan_metadata.vxlan_vni != 0) {
            if (hdr.udp.isValid()) {
                if (meta.layer34_metadata.monitored_flow == 1) {
                    vxlan_gpe_udp_encap();
                } else {
                    vxlan_udp_encap();
                }
            }
            if (hdr.tcp.isValid()) {
                if (meta.layer34_metadata.monitored_flow == 1) {
                    vxlan_gpe_tcp_encap();
                } else {
                    vxlan_tcp_encap();
                }
            }
        }
    }

}
