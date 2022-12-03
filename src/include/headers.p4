/* -*- P4_16 -*- */


typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

/********************************************************************
*  Regular headers
*******************************************************************/

/* ethernet header: 14 bytes */
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/* ipv4 header: 20 bytes */
header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> totalLen;
    bit<16> id;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

/* udp header: 8 bytes */
header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> len;
    bit<16> csum;
}

/* tcp header: 20 bytes */
header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNum;
    bit<32> ackNum;
    bit<4>  dataOffset;
    bit<3>  reserved;
    bit<9>  flags;
    bit<16> winSize;
    bit<16> csum;
    bit<16> urgPoint;
}


/********************************************************************
*  VXLAN Encapsulation headers
*******************************************************************/

/* vxlan header: 8 bytes */
header vxlan_t {
    bit<8>  flags;
    bit<24> rsvd0;
    bit<24> vni;
    bit<8>  rsvd1;
}

const bit<8> VXLAN_GPE_NEXT_PROTO_INT = 0x82;

/* vxlan generic protocol extension (GPE) header: 8 bytes */
header vxlan_gpe_t {
    bit<8>  flags;
    bit<16> rsvd0; // be set to 0 on transmission, ignored on receipt.
    bit<8>  next_proto;
    bit<24> vni;
    bit<8>  rsvd1;
}

const bit<16> VXLAN_GPE_INT_SHIM_HEADER_LEN_BYTES = 4;
const bit<8> INT_TYPE_HOP_BY_HOP = 1;
const bit<8> VXLAN_GPE_INT_SHIM_NEXT_PROTO_INT = 0x3;

/* VxLan GPE shim header: 4 bytes */
header vxlan_gpe_int_shim_header_t {
    bit<8>  int_type;
    bit<8>  len;
    bit<8>  rsvd;
    bit<8>  next_proto; // as next_proto, 0x05 for INT
}


/********************************************************************
*  INT headers
*******************************************************************/

const bit<16> INT_HEADER_LEN_BYTES = 8;
const bit<4>  INT_VERSION = 2;
const bit<8>  MAX_HOP_CNT = 6;

/* INT header: 8 bytes */
header int_header_t {
    bit<4>  ver;
    bit<2>  rep;
    bit<1>  c;
    bit<1>  e;
    bit<1>  m;
    bit<7>  rsvd1;
    bit<3>  rsvd2;
    bit<5>  hop_metadata_len;   // the length of the metadata added by a single INT node (4-byte words)
    bit<8>  remaining_hop_cnt;  // how many switches can still add INT metadata
    bit<4>  instruction_mask_0003; // check instructions from bit 0 to bit 3
    bit<4>  instruction_mask_0407; // check instructions from bit 4 to bit 7
    bit<4>  instruction_mask_0811; // check instructions from bit 8 to bit 11
    bit<4>  instruction_mask_1215; // check instructions from bit 12 to bit 15
    bit<16> rsvd3;
}

const bit<16> INT_ALL_HEADER_LEN_BYTES = VXLAN_GPE_INT_SHIM_HEADER_LEN_BYTES + INT_HEADER_LEN_BYTES;

/* INT meta­value headers ­- different header for each value type */
header int_switch_id_t {
    bit<8>  bos;
    bit<24> switch_id;
}
header int_port_id_t {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}
header int_hop_latency_t {
    bit<32> hop_latency;
}
header int_q_occupancy_t {
    bit<8>  q_occupancy_id;
    bit<24> q_occupancy;
}
header int_ingress_tstamp_t {
    bit<48> ingress_tstamp;
}
header int_egress_tstamp_t {
    bit<48> egress_tstamp;
}
header int_q_congestion_t {
    bit<32> q_congestion;
}
header int_egress_port_tx_utilization_t {
    bit<32> egress_port_tx_utilization;
}


/********************************************************************
*  General structs
*******************************************************************/

struct int_metadata_t {
    bit<1>  source;               // is INT source functionality enabled
    bit<1>  sink;                 // is INT sink functionality enabled
    bit<24> switch_id;            // INT switch id is configured by network controller
    bit<16> insert_byte_cnt;      // counter of inserted INT bytes
    bit<8>  int_hdr_word_len;     // counter of inserted INT words
    bit<1>  remove_int;           // indicator that all INT headers and data must be removed at egress for the processed packet
    bit<16> sink_reporting_port;  // on which port INT reports must be send to INT collector
    bit<48> ingress_tstamp;       // pass ingress timestamp from Ingress pipeline to Egress pipeline
    bit<16> ingress_port;         // pass ingress port from Ingress pipeline to Egress pipeline
}

struct layer34_metadata_t {
    bit<32> ip_src;
    bit<32> ip_dst;
    bit<8>  ip_ver;
    bit<16> l4_src;
    bit<16> l4_dst;
    bit<8>  l4_proto;
    bit<1>  monitored_flow;
}

struct vxlan_metadata_t {
    bit<24> vxlan_vni;
    bit<32> peer_vtep_ip;
    bit<32> vtep_ip;
    bit<1>  tunnel_end;
    bit<9>  final_egress_port;
    bit<1>  local_forward;
}

struct metadata {
    int_metadata_t                int_metadata;
    vxlan_gpe_int_shim_header_t   vxlan_gpe_int_shim_header;
    vxlan_metadata_t              vxlan_metadata;
    layer34_metadata_t            layer34_metadata;
}

struct headers {
    // normal headers
    ethernet_t                    ethernet;
    ipv4_t                        ipv4;
    tcp_t                         tcp;
    udp_t                         udp;

    // VXLAN headers
    vxlan_t                       vxlan;
    vxlan_gpe_t                   vxlan_gpe;

    // INT headers
    vxlan_gpe_int_shim_header_t   vxlan_gpe_int_shim_header;
    int_header_t                  int_header;

    // INT metadata stacks
    int_switch_id_t[MAX_HOP_CNT]                  int_switch_id;
    int_port_id_t[MAX_HOP_CNT]                    int_port_id;
    int_hop_latency_t[MAX_HOP_CNT]                int_hop_latency;
    int_q_occupancy_t[MAX_HOP_CNT]                int_q_occupancy;
    int_ingress_tstamp_t[MAX_HOP_CNT]             int_ingress_tstamp;
    int_egress_tstamp_t[MAX_HOP_CNT]              int_egress_tstamp;
    int_q_congestion_t[MAX_HOP_CNT]               int_q_congestion;
    int_egress_port_tx_utilization_t[MAX_HOP_CNT] int_egress_port_tx_utilization;

    // inner headers
    ethernet_t                                    inner_ethernet;
    ipv4_t                                        inner_ipv4;
    tcp_t                                         inner_tcp;
    udp_t                                         inner_udp;
}
