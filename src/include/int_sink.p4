/* -*- P4_16 -*- */


const bit<32> INT_REPORT_MIRROR_SESSION_ID = 500;


// Ingress control block
// If determined egress port is configured to be INT sink port
// set metadata accordingly and clone packet to reporting port (in this app 1)
// for clone operation mirroring_add function in CLI is required
control int_sink_config(inout headers hdr,
                        inout metadata meta,
                        inout standard_metadata_t standard_metadata) {


    action configure_sink(bit<16> sink_reporting_port) {
        meta.int_metadata.remove_int = 1;   // indicate that INT headers must be removed in egress
        meta.int_metadata.sink_reporting_port = (bit<16>)sink_reporting_port;

        clone(CloneType.I2E, INT_REPORT_MIRROR_SESSION_ID);
    }

    //table used to activate INT sink for particular egress port of the switch
    table tb_int_sink {
        actions = {
            configure_sink;
        }
        key = {
            standard_metadata.egress_spec: exact;
        }
        size = 255;
    }

    apply {
        // INT sink must process only INT packets
        if (!hdr.int_header.isValid()) {
            return;
        }

        tb_int_sink.apply();
    }
}


control int_sink(inout headers hdr,
                        inout metadata meta,
                        inout standard_metadata_t standard_metadata) {

    action remove_one_int_stack() {
        hdr.vxlan_gpe_int_shim_header.setInvalid();
        hdr.int_header.setInvalid();
        hdr.int_switch_id.pop_front(1);
        hdr.int_port_id.pop_front(1);
        hdr.int_hop_latency.pop_front(1);
        hdr.int_ingress_tstamp.pop_front(1);
        hdr.int_egress_tstamp.pop_front(1);
    }

    action remove_three_int_stack() {
        hdr.vxlan_gpe_int_shim_header.setInvalid();
        hdr.int_header.setInvalid();
        hdr.int_switch_id.pop_front(3);
        hdr.int_port_id.pop_front(3);
        hdr.int_hop_latency.pop_front(3);
        hdr.int_ingress_tstamp.pop_front(3);
        hdr.int_egress_tstamp.pop_front(3);
    }

    action remove_six_int_stack() {
        hdr.vxlan_gpe_int_shim_header.setInvalid();
        hdr.int_header.setInvalid();
        hdr.int_switch_id.pop_front(6);
        hdr.int_port_id.pop_front(6);
        hdr.int_hop_latency.pop_front(6);
        hdr.int_ingress_tstamp.pop_front(6);
        hdr.int_egress_tstamp.pop_front(6);
    }

    apply {
        // INT sink must process only INT packets
        if (!hdr.int_header.isValid())
            return;

        if (standard_metadata.instance_type == 0 && meta.int_metadata.remove_int == 1) {
            if (hdr.int_header.remaining_hop_cnt == 0) {
                remove_six_int_stack();
            } else if (hdr.int_header.remaining_hop_cnt == 3) {
                remove_three_int_stack();
            } else if (hdr.int_header.remaining_hop_cnt == 5) {
                remove_one_int_stack();
            }
        }
        if (standard_metadata.instance_type == 1) {
            // send original packet to controller port, or better: do nothing
            hdr.int_port_id[0].egress_port_id = (bit<16>)meta.vxlan_metadata.final_egress_port;
        }
    }
}
