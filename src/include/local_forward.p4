/* -*- P4_16 -*- */

control local_forward (inout headers hdr,
                       inout metadata meta,
                       inout standard_metadata_t standard_metadata) {

    action local_fwd(bit<9> outPort) {
        standard_metadata.egress_spec = outPort;
        meta.vxlan_metadata.local_forward = 1;
    }

    table tb_local_forward {
        key = {
            hdr.ipv4.dstAddr : exact;
        }
        actions = {
            local_fwd;
        }
    }

    apply {
        tb_local_forward.apply();
    }
}
