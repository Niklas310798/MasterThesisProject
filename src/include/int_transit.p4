/* -*- P4_16 -*- */

control int_transit(inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {

    // Configure parameters of INT transit node:
    // switch_id which is used within INT node metadata

    action configure_transit(bit<24> switch_id) {
        meta.int_metadata.switch_id = switch_id;
        meta.int_metadata.insert_byte_cnt = 0;
        meta.int_metadata.int_hdr_word_len = 0;
    }

    table tb_int_transit {
        actions = {
            configure_transit;
        }
    }

    // instruction
    action int_set_header_0() { // switch id
        hdr.int_switch_id.push_front(1);
        hdr.int_switch_id[0].setValid();
        hdr.int_switch_id[0].bos = 0;
        hdr.int_switch_id[0].switch_id = (bit<24>) meta.int_metadata.switch_id;
    }

    action int_set_header_1() {  // ingress and egress ports
        hdr.int_port_id.push_front(1);
        hdr.int_port_id[0].setValid();
        hdr.int_port_id[0].ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_id[0].egress_port_id = (bit<16>)standard_metadata.egress_port;
    }

    action int_set_header_2() { // hop latency
        hdr.int_hop_latency.push_front(1);
        hdr.int_hop_latency[0].setValid();
        hdr.int_hop_latency[0].hop_latency = (bit<32>)standard_metadata.deq_timedelta;//queuing delay
        //or: (bit<32>)(standard_metadata.egress_global_timestamp - (bit<48>)standard_metadata.enq_timestamp);
    }

    action int_set_header_3() { // q occupency

    }

    action int_set_header_4() { //ingress_timestamp
        hdr.int_ingress_tstamp.push_front(1);
        hdr.int_ingress_tstamp[0].setValid();
        hdr.int_ingress_tstamp[0].ingress_tstamp = (bit<48>) standard_metadata.ingress_global_timestamp;
    }

    action int_set_header_5() { //egress_timestamp
        hdr.int_egress_tstamp.push_front(1);
        hdr.int_egress_tstamp[0].setValid();
        hdr.int_egress_tstamp[0].egress_tstamp = (bit<48>) standard_metadata.egress_global_timestamp;
    }

    action int_set_header_6() { //q_congestion

    }

    action int_set_header_7() { //egress_port_tx_utilization

    }

    action add_1() {
        meta.int_metadata.int_hdr_word_len = meta.int_metadata.int_hdr_word_len + 1;
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt + 4;
    }

    action add_2() {
        meta.int_metadata.int_hdr_word_len = meta.int_metadata.int_hdr_word_len + 2;
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt + 8;
    }

    action add_3() {
        meta.int_metadata.int_hdr_word_len = meta.int_metadata.int_hdr_word_len + 3;
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt + 12;
    }

    action add_4() {
        meta.int_metadata.int_hdr_word_len = meta.int_metadata.int_hdr_word_len + 4;
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt + 16;
    }


    action add_5() {
        meta.int_metadata.int_hdr_word_len = meta.int_metadata.int_hdr_word_len + 5;
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt + 20;
    }

    action add_6() {
        meta.int_metadata.int_hdr_word_len = meta.int_metadata.int_hdr_word_len + 6;
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt + 24;
    }

    action int_set_header_0003_i0() {
            ;
    }
    action int_set_header_0003_i1() {
        int_set_header_3();
        add_1();
    }
    action int_set_header_0003_i2() {
        int_set_header_2();
        add_1();
    }
    action int_set_header_0003_i3() {
        int_set_header_5();
        int_set_header_2();
        add_3();
    }
    action int_set_header_0003_i4() {
        int_set_header_1();
        add_1();
    }
    action int_set_header_0003_i5() {
        int_set_header_3();
        int_set_header_1();
        add_2();
    }
    action int_set_header_0003_i6() {
        int_set_header_2();
        int_set_header_1();
        add_2();
    }
    action int_set_header_0003_i7() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        add_3();
    }
    action int_set_header_0003_i8() {
        int_set_header_0();
        add_1();
    }
    action int_set_header_0003_i9() {
        int_set_header_3();
        int_set_header_0();
        add_2();
    }
    action int_set_header_0003_i10() {
        int_set_header_2();
        int_set_header_0();
        add_2();
    }
    action int_set_header_0003_i11() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_0();
        add_3();
    }
    action int_set_header_0003_i12() {
        int_set_header_1();
        int_set_header_0();
        add_2();
    }
    action int_set_header_0003_i13() {
        int_set_header_3();
        int_set_header_1();
        int_set_header_0();
        add_3();
    }
    action int_set_header_0003_i14() {
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
        add_3();
    }
    action int_set_header_0003_i15() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
        add_4();
    }

    table tb_int_inst_0003 {
        actions = {
            int_set_header_0003_i0;
            int_set_header_0003_i1;
            int_set_header_0003_i2;
            int_set_header_0003_i3;
            int_set_header_0003_i4;
            int_set_header_0003_i5;
            int_set_header_0003_i6;
            int_set_header_0003_i7;
            int_set_header_0003_i8;
            int_set_header_0003_i9;
            int_set_header_0003_i10;
            int_set_header_0003_i11;
            int_set_header_0003_i12;
            int_set_header_0003_i13;
            int_set_header_0003_i14;
            int_set_header_0003_i15;
        }
        key = {
            hdr.int_header.instruction_mask_0003 : exact;
        }
        default_action = int_set_header_0003_i0();
        const entries = {
            0 : int_set_header_0003_i0();
            1 : int_set_header_0003_i1();
            2 : int_set_header_0003_i2();
            3 : int_set_header_0003_i3();
            4 : int_set_header_0003_i4();
            5 : int_set_header_0003_i5();
            6 : int_set_header_0003_i6();
            7 : int_set_header_0003_i7();
            8 : int_set_header_0003_i8();
            9 : int_set_header_0003_i9();
            10 : int_set_header_0003_i10();
            11 : int_set_header_0003_i11();
            12 : int_set_header_0003_i12();
            13 : int_set_header_0003_i13();
            14 : int_set_header_0003_i14(); // 0, 1 & 2
            15 : int_set_header_0003_i15();
        }
    }

    action int_set_header_0407_i0() {
        ;
    }
    action int_set_header_0407_i1() {
        int_set_header_7();
        add_1();
    }
    action int_set_header_0407_i2() {
        int_set_header_6();
        add_1();
    }
    action int_set_header_0407_i3() {
        int_set_header_7();
        int_set_header_6();
        add_2();
    }
    action int_set_header_0407_i4() {
        int_set_header_5();
        add_2();
    }
    action int_set_header_0407_i5() {
        int_set_header_7();
        int_set_header_5();
        add_3();
    }
    action int_set_header_0407_i6() {
        int_set_header_6();
        int_set_header_5();
        add_3();
    }
    action int_set_header_0407_i7() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
        add_4();
    }
    action int_set_header_0407_i8() {
        int_set_header_4();
        add_2();
    }
    action int_set_header_0407_i9() {
        int_set_header_7();
        int_set_header_4();
        add_3();
    }
    action int_set_header_0407_i10() {
        int_set_header_6();
        int_set_header_4();
        add_3();
    }
    action int_set_header_0407_i11() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_4();
        add_4();
    }
    action int_set_header_0407_i12() {
        int_set_header_5();
        int_set_header_4();
        add_4();
    }
    action int_set_header_0407_i13() {
        int_set_header_7();
        int_set_header_5();
        int_set_header_4();
        add_5();
    }
    action int_set_header_0407_i14() {
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
        add_5();
    }
    action int_set_header_0407_i15() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
        add_6();
    }


    table tb_int_inst_0407 {
        key = {
            hdr.int_header.instruction_mask_0407 : exact;
        }
        actions = {
            int_set_header_0407_i0;
            int_set_header_0407_i1;
            int_set_header_0407_i2;
            int_set_header_0407_i3;
            int_set_header_0407_i4;
            int_set_header_0407_i5;
            int_set_header_0407_i6;
            int_set_header_0407_i7;
            int_set_header_0407_i8;
            int_set_header_0407_i9;
            int_set_header_0407_i10;
            int_set_header_0407_i11;
            int_set_header_0407_i12;
            int_set_header_0407_i13;
            int_set_header_0407_i14;
            int_set_header_0407_i15;
        }
        default_action = int_set_header_0407_i0();
        const entries = {
            0 : int_set_header_0407_i0();
            1 : int_set_header_0407_i1();
            2 : int_set_header_0407_i2();
            3 : int_set_header_0407_i3();
            4 : int_set_header_0407_i4();
            5 : int_set_header_0407_i5();
            6 : int_set_header_0407_i6();
            7 : int_set_header_0407_i7();
            8 : int_set_header_0407_i8();
            9 : int_set_header_0407_i9();
            10 : int_set_header_0407_i10();
            11 : int_set_header_0407_i11();
            12 : int_set_header_0407_i12();
            13 : int_set_header_0407_i13();
            14 : int_set_header_0407_i14();
            15 : int_set_header_0407_i15();
        }
    }

    action int_hop_cnt_increment() {
        hdr.int_header.remaining_hop_cnt = hdr.int_header.remaining_hop_cnt - 1;
    }
    action int_hop_exceeded() {
        hdr.int_header.e = 1w1;
    }
    action int_update_ipv4_ac() {
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + (bit<16>)meta.int_metadata.insert_byte_cnt;
    }
    action int_update_shim_ac() {
        hdr.vxlan_gpe_int_shim_header.len = hdr.vxlan_gpe_int_shim_header.len + (bit<8>)meta.int_metadata.int_hdr_word_len;
    }
    action int_update_udp_ac() {
       hdr.udp.len = hdr.udp.len + (bit<16>)meta.int_metadata.insert_byte_cnt;
    }


    apply {
        // INT transit must process only INT packets
        if (!hdr.int_header.isValid())
            return;

        //TODO: check if hop-by-hop INT or destination INT

        // check if INT transit can add a new INT node metadata
        if (hdr.int_header.remaining_hop_cnt == 0 || hdr.int_header.e == 1) {
            int_hop_exceeded();
            return;
        }

        int_hop_cnt_increment();

        // if int should be removed (sink) and original packet arrives, do nothing
        if (meta.int_metadata.remove_int == 1 && standard_metadata.instance_type == 0) {

        } else {
            // add INT node metadata headers based on INT instruction_mask
            tb_int_transit.apply();
            tb_int_inst_0003.apply();
            tb_int_inst_0407.apply();

            if (hdr.int_header.remaining_hop_cnt == (MAX_HOP_CNT - 1)) {
                if (hdr.int_switch_id[0].isValid()) {
                    hdr.int_switch_id[0].bos = 1;
                }
            }
        }

        //update length fields in IPv4, UDP and INT
        int_update_ipv4_ac();

        if (hdr.udp.isValid())
            int_update_udp_ac();

        if (hdr.vxlan_gpe_int_shim_header.isValid())
                int_update_shim_ac();
    }
}
