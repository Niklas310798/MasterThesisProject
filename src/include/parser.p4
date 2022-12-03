/*************************************************************************
*  parser
*************************************************************************/
#define UDP_PORT_VXLAN 4789
#define UDP_PORT_VXLAN_GPE 4790
#define DEFAULT_VXLAN_VNI 100

parser ParserImpl (packet_in packet,
                 out headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    state start {
        transition parse_ethernet;
    }

    /* Ethernet */
    state parse_ethernet {
    packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800  : parse_ipv4;
            default : accept;
        }
    }

    /* IPv4 */
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6       : parse_tcp;
            17      : parse_udp;
            default : accept;
        }
    }

    /* UDP */
    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            UDP_PORT_VXLAN  : parse_vxlan;
            4800            : parse_vxlan_gpe;   // will be followed by INT Shim Header, Meta Header and INT Metadata Stack
            default         : accept;
        }
    }

    /* TCP */
    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

    /* VXLAN */
    state parse_vxlan {
        packet.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    /* VXLAN GPE */
    state parse_vxlan_gpe {
        packet.extract(hdr.vxlan_gpe);
        transition select(hdr.vxlan_gpe.next_proto) {
            0x82    : parse_vxlan_gpe_int_shim_header;
            default : accept;
        }
    }

    /* GPE INT SHIM */
    state parse_vxlan_gpe_int_shim_header {
        packet.extract(hdr.vxlan_gpe_int_shim_header);
        transition select(hdr.vxlan_gpe_int_shim_header.next_proto) {
            0x3    : parse_int_header;
            default : accept;
        }
    }

    /* INT */
    state parse_int_header {
        packet.extract(hdr.int_header);
        transition parse_int_meta_value_stack;
    }

    /* INT Metadata Value Stack */
    state parse_int_meta_value_stack {
        packet.extract(hdr.int_switch_id.next);
        packet.extract(hdr.int_port_id.next);
        packet.extract(hdr.int_hop_latency.next);
        packet.extract(hdr.int_ingress_tstamp.next);
        packet.extract(hdr.int_egress_tstamp.next);
        transition select(hdr.int_switch_id.last.bos) {
            1       : parse_inner_ethernet;
            default : parse_int_meta_value_stack;
        }
    }

    /* Inner Ethernet */
    state parse_inner_ethernet {
        packet.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            0x800   : parse_inner_ipv4;
            default : accept;
        }
    }

    /* Inner IPv4 */
    state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            6       : parse_inner_tcp;
            17      : parse_inner_udp;
            default : accept;
        }
    }

    /* Inner UDP */
    state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        transition accept;
    }

    /* Inner TCP */
    state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        transition accept;
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {

        // original headers
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);

        // VXLAN headers
        packet.emit(hdr.vxlan);
        packet.emit(hdr.vxlan_gpe);

        // INT headers
        packet.emit(hdr.vxlan_gpe_int_shim_header);
        packet.emit(hdr.int_header);

        // local INT node metadata
        packet.emit(hdr.int_switch_id[0]);                   // bit 1
        packet.emit(hdr.int_port_id[0]);                     // bit 2
        packet.emit(hdr.int_hop_latency[0]);                 // bit 3
        packet.emit(hdr.int_q_occupancy[0]);                 // bit 4
        packet.emit(hdr.int_ingress_tstamp[0]);              // bit 5
        packet.emit(hdr.int_egress_tstamp[0]);               // bit 6
        packet.emit(hdr.int_q_congestion[0]);                // bit 7
        packet.emit(hdr.int_egress_port_tx_utilization[0]);  // bit 8

        // local INT node metadata
        packet.emit(hdr.int_switch_id[1]);                   // bit 1
        packet.emit(hdr.int_port_id[1]);                     // bit 2
        packet.emit(hdr.int_hop_latency[1]);                 // bit 3
        packet.emit(hdr.int_q_occupancy[1]);                 // bit 4
        packet.emit(hdr.int_ingress_tstamp[1]);              // bit 5
        packet.emit(hdr.int_egress_tstamp[1]);               // bit 6
        packet.emit(hdr.int_q_congestion[1]);                // bit 7
        packet.emit(hdr.int_egress_port_tx_utilization[1]);  // bit 8

        // local INT node metadata
        packet.emit(hdr.int_switch_id[2]);                   // bit 1
        packet.emit(hdr.int_port_id[2]);                     // bit 2
        packet.emit(hdr.int_hop_latency[2]);                 // bit 3
        packet.emit(hdr.int_q_occupancy[2]);                 // bit 4
        packet.emit(hdr.int_ingress_tstamp[2]);              // bit 5
        packet.emit(hdr.int_egress_tstamp[2]);               // bit 6
        packet.emit(hdr.int_q_congestion[2]);                // bit 7
        packet.emit(hdr.int_egress_port_tx_utilization[2]);  // bit 8

        // local INT node metadata
        packet.emit(hdr.int_switch_id[3]);                   // bit 1
        packet.emit(hdr.int_port_id[3]);                     // bit 2
        packet.emit(hdr.int_hop_latency[3]);                 // bit 3
        packet.emit(hdr.int_q_occupancy[3]);                 // bit 4
        packet.emit(hdr.int_ingress_tstamp[3]);              // bit 5
        packet.emit(hdr.int_egress_tstamp[3]);               // bit 6
        packet.emit(hdr.int_q_congestion[3]);                // bit 7
        packet.emit(hdr.int_egress_port_tx_utilization[3]);  // bit 8

        // local INT node metadata
        packet.emit(hdr.int_switch_id[4]);                   // bit 1
        packet.emit(hdr.int_port_id[4]);                     // bit 2
        packet.emit(hdr.int_hop_latency[4]);                 // bit 3
        packet.emit(hdr.int_q_occupancy[4]);                 // bit 4
        packet.emit(hdr.int_ingress_tstamp[4]);              // bit 5
        packet.emit(hdr.int_egress_tstamp[4]);               // bit 6
        packet.emit(hdr.int_q_congestion[4]);                // bit 7
        packet.emit(hdr.int_egress_port_tx_utilization[4]);  // bit 8

        // local INT node metadata
        packet.emit(hdr.int_switch_id[5]);                   // bit 1
        packet.emit(hdr.int_port_id[5]);                     // bit 2
        packet.emit(hdr.int_hop_latency[5]);                 // bit 3
        packet.emit(hdr.int_q_occupancy[5]);                 // bit 4
        packet.emit(hdr.int_ingress_tstamp[5]);              // bit 5
        packet.emit(hdr.int_egress_tstamp[5]);               // bit 6
        packet.emit(hdr.int_q_congestion[5]);                // bit 7
        packet.emit(hdr.int_egress_port_tx_utilization[5]);  // bit 8

        // Inner VXLAN headers
        packet.emit(hdr.inner_ethernet);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_udp);
        packet.emit(hdr.inner_tcp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(
            hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.totalLen,
                hdr.ipv4.id,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr
            },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16
        );

        update_checksum_with_payload(
            hdr.udp.isValid(),
            {  hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                8w0,
                hdr.ipv4.protocol,
                hdr.udp.len,
                hdr.udp.srcPort,
                hdr.udp.dstPort,
                hdr.udp.len
            },
            hdr.udp.csum,
            HashAlgorithm.csum16
        );
    }
}
