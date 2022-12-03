/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parser.p4"
#include "include/int_source.p4"
#include "include/int_transit.p4"
#include "include/int_sink.p4"
#include "include/vxlan.p4"
#include "include/local_forward.p4"

// handling of VXLAN encapped packets
// packets should also have INT headers
// #include "include/vxlan_upstream.p4"
// handling of non-VXLAN encapped packets
// also no INT headers should be available
// #include "include/vxlan_downstream.p4"




control int_vxlan_ingress (inout headers hdr,
                           inout metadata meta,
                           inout standard_metadata_t standard_metadata) {

    apply {
        if (!hdr.udp.isValid() && !hdr.tcp.isValid()) {
            exit;
        }

        // check if dst IP is connected to switch directly
        // or better: if table entry for key IP of connected VM is matched
        local_forward.apply(hdr, meta, standard_metadata);

        if (meta.vxlan_metadata.local_forward == 1) {
            exit;
        }

        // in case of standard packet from SRC VM is incoming
        // -> prepare encapsulation into VXLAN outer headers
        // -> set output port for next hop of then VXLAN encapped packet
        vxlan_ingress_downstream.apply(hdr, meta, standard_metadata);

        // in case of INT source port, set metadata source = 1 to mark
        // for having to add INT headers in egress processing
		    int_source_activation.apply(hdr, meta, standard_metadata);

        // in case of VXLAN encapped packet coming into the switch
        vxlan_ingress_upstream.apply(hdr, meta, standard_metadata);

        // in case of sink node make packet clone I2E in order to create INT report
		    // which will be send to INT reporting port
		    int_sink_config.apply(hdr, meta, standard_metadata);
    }
}

control int_vxlan_egress (inout headers hdr,
                          inout metadata meta,
                          inout standard_metadata_t standard_metadata) {

    apply {
        if (meta.vxlan_metadata.local_forward == 1) {
            exit;
        }

        // if meta.vxlan_vni != 0, packet is being encapsulated
        // checks whether TCP oder UDP is used for setting inner headers accordingly
        vxlan_egress_downstream.apply(hdr, meta, standard_metadata);

        if (hdr.vxlan_gpe.isValid()) {
            int_source_configure.apply(hdr, meta, standard_metadata);

            // checks if more INT data can be written
            // writes INT information based on instructions_masks
            int_transit.apply(hdr, meta, standard_metadata);
        }


        // check if original and meta.tunnel_end == 1, if yes decap packet from VXLAN
        vxlan_egress_upstream.apply(hdr, meta, standard_metadata);

        // check if packet is cloned, or sink or etc.
        // if original, remove INT header stacks and INT headers
        // if cloned, write original outport in int_port_id header and do nothing else
        int_sink.apply(hdr, meta, standard_metadata);
    }
}



V1Switch(
    ParserImpl(),
    verifyChecksum(),
    int_vxlan_ingress(),
    int_vxlan_egress(),
    computeChecksum(),
    DeparserImpl()
) main;
