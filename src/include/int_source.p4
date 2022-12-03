/* -*- P4_16 -*- */


control int_source_activation(inout headers hdr,
                              inout metadata meta,
                              inout standard_metadata_t standard_metadata) {


      action activate_source() {
        meta.int_metadata.source = 1;
      }

      // table used to active INT source for a ingress port of the switch
      table tb_activate_source {
          actions = {
              activate_source;
          }
          key = {
              standard_metadata.ingress_port: exact;
          }
          size = 255;
      }

      action mark_monitored_flow() {
          meta.layer34_metadata.monitored_flow = 1;
      }

      table tb_flow_monitor {
          actions = {
              mark_monitored_flow;
          }
          key = {
              hdr.ipv4.srcAddr     : exact;
              hdr.ipv4.dstAddr     : exact;
              meta.layer34_metadata.l4_src: exact;
              meta.layer34_metadata.l4_dst: exact;
          }
          size = 127;
      }

      apply {
            // in case of frame clone for the INT sink reporting
            // ingress timestamp is not available on Egress pipeline
            meta.int_metadata.ingress_tstamp = (bit<48>) standard_metadata.ingress_global_timestamp;
            meta.int_metadata.ingress_port = (bit<16>)standard_metadata.ingress_port;

            // check if packet appeard on ingress port with active INT source
            // If yes, save layer3_4 metadata to meta struct
            if (tb_activate_source.apply().hit) {
                if (hdr.udp.isValid()) {
                    meta.layer34_metadata.l4_src = hdr.udp.srcPort;
                    meta.layer34_metadata.l4_dst = hdr.udp.dstPort;
                }
                if (hdr.tcp.isValid()) {
                    meta.layer34_metadata.l4_src = hdr.tcp.srcPort;
                    meta.layer34_metadata.l4_dst = hdr.tcp.dstPort;
                }
                tb_flow_monitor.apply();
            }
      }

}

control int_source_configure(inout headers hdr,
                             inout metadata meta,
                             inout standard_metadata_t standard_metadata) {

    // Configure parameters of INT source node
    action configure_source() {
        hdr.vxlan_gpe_int_shim_header.setValid();
        hdr.vxlan_gpe_int_shim_header.int_type = INT_TYPE_HOP_BY_HOP;
        hdr.vxlan_gpe_int_shim_header.len = (bit<8>)INT_ALL_HEADER_LEN_BYTES>>2;
        hdr.vxlan_gpe_int_shim_header.next_proto = VXLAN_GPE_INT_SHIM_NEXT_PROTO_INT;

        hdr.int_header.setValid();
        hdr.int_header.ver = INT_VERSION;
        hdr.int_header.rep = 0;
        hdr.int_header.c = 0;
        hdr.int_header.e = 0;
        hdr.int_header.rsvd1 = 0;
        hdr.int_header.rsvd2 = 0;
        hdr.int_header.hop_metadata_len = 4;
        hdr.int_header.remaining_hop_cnt = MAX_HOP_CNT;  //will be decreased immediately by 1 within transit process
        hdr.int_header.instruction_mask_0003 = 0xE;
        hdr.int_header.instruction_mask_0407 = 0xC;

        hdr.ipv4.totalLen = hdr.ipv4.totalLen + INT_ALL_HEADER_LEN_BYTES;  // adding size of INT headers

        hdr.udp.len = hdr.udp.len + INT_ALL_HEADER_LEN_BYTES;
    }

    apply {
        if (meta.int_metadata.source == 1 && meta.layer34_metadata.monitored_flow == 1) {
            configure_source();
        }
    }
}
