#include <core.p4>
#include <v1model.p4>

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<16> portNum_t;
typedef bit<9>  egressSpec_t;
typedef bit<2> Value_t;

const bit<16> SERVER_PORT = 80;







header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

// IPv4 header _with_ options
header ipv4_t {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      totalLen;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      fragOffset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdrChecksum;
    ip4Addr_t  srcAddr;
    ip4Addr_t  dstAddr;
    varbit<320>  options;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum; // Includes Pseudo Hdr + TCP segment (hdr + payload)
    bit<16> urgentPtr;
    varbit<320>  options;
}

header IPv4_up_to_ihl_only_h {
    bit<4>       version;
    bit<4>       ihl;
}

header tcp_upto_data_offset_only_h {
    portNum_t srcPort;
    portNum_t dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    // dataOffset in TCP hdr uses 4 bits but needs padding.
    // If 4 bits are used for it, p4c-bm2-ss complains the header
    // is not a multiple of 8 bits.
    bit<4>  dataOffset;
    bit<4>  dontCare;
}


struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    tcp_t      tcp;
}

struct mystruct1_t {
    bit<4>  a;
    bit<4>  b;
}

struct metadata {
    mystruct1_t mystruct1;
    bit<16>     l4Len; // includes TCP hdr len + TCP payload len in bytes.
}

typedef tuple<
    bit<4>,
    bit<4>,
    bit<8>,
    varbit<56>
    > myTuple1;

// Declare user-defined errors that may be signaled during parsing
error {
    IPv4HeaderTooShort,
    TCPHeaderTooShort,
    IPv4IncorrectVersion,
    IPv4ChecksumError
}



parser MyParser(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        // The 4-bit IHL field of the IPv4 base header is the number
        // of 32-bit words in the entire IPv4 header.  It is an error
        // for it to be less than 5.  There are only IPv4 options
        // present if the value is at least 6.  The length of the IPv4
        // options alone, without the 20-byte base header, is thus ((4
        // * ihl) - 20) bytes, or 8 times that many bits.
        packet.extract(hdr.ipv4,
                    (bit<32>)
                    (8 *
                     (4 * (bit<9>) (packet.lookahead<IPv4_up_to_ihl_only_h>().ihl)
                      - 20)));
        verify(hdr.ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(hdr.ipv4.ihl >= 4w5, error.IPv4HeaderTooShort);
        meta.l4Len = hdr.ipv4.totalLen - (bit<16>)(hdr.ipv4.ihl)*4;
        transition select (hdr.ipv4.protocol) {
            6: parse_tcp;
            default: accept;
        }
    }

    state parse_tcp {
        // The 4-bit dataOffset field of the TCP base header is the number
        // of 32-bit words in the entire TCP header.  It is an error
        // for it to be less than 5.  There are only TCP options
        // present if the value is at least 6.  The length of the TCP
        // options alone, without the 20-byte base header, is thus ((4
        // * dataOffset) - 20) bytes, or 8 times that many bits.
        packet.extract(hdr.tcp,
                    (bit<32>)
                    (8 *
                     (4 * (bit<9>) (packet.lookahead<tcp_upto_data_offset_only_h>().dataOffset)
                      - 20)));
        verify(hdr.tcp.dataOffset >= 4w5, error.TCPHeaderTooShort);
        transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

    register<bit<1>>(1) state_var1;
    register<Value_t>(65535) port_map;

    
    bit<1> state1;
    bit<32> server_index;
    bit<1> isAssigned;
    Value_t value_register;
    


     action send_to_server(macAddr_t src_mac, 
                        macAddr_t dst_mac, 
                        ip4Addr_t dst_ip, 
                        egressSpec_t egress_port, 
                        portNum_t server_port ) {

        hdr.ipv4.dstAddr = dst_ip;
        hdr.tcp.dstPort = server_port;
        //set the src mac address as the previous dst
        hdr.ethernet.srcAddr = src_mac;

        //set the destination mac address that we got from the match in the table
        hdr.ethernet.dstAddr = dst_mac;

        //set the output port that we also get from the table
        standard_metadata.egress_spec = egress_port;

        //decrease ttl by 1
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action send_to_client(macAddr_t src_mac, 
                        macAddr_t dst_mac, 
                        ip4Addr_t src_ip, 
                        egressSpec_t egress_port){

                // Reverse NAT for response packets
                
                hdr.ipv4.srcAddr = src_ip; 
                //set the src mac address as the previous dst
                hdr.ethernet.srcAddr = src_mac;

                //set the destination mac address that we got from the match in the table
                hdr.ethernet.dstAddr = dst_mac;
                
                 //set the output port that we also get from the table
                standard_metadata.egress_spec = egress_port;
                //decrease ttl by 1
                hdr.ipv4.ttl = hdr.ipv4.ttl - 1;


    }

    table forward_nat{
        key = {
            state1: exact;
            server_index: exact;
            standard_metadata.ingress_port : exact;

        }
        actions = {
            send_to_server;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table reverse_nat{
        key = {
            standard_metadata.ingress_port : exact;
            hdr.tcp.srcPort : exact; //should be 80
        }
        actions = {
            send_to_client;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply{

        if (hdr.ipv4.isValid() && hdr.tcp.isValid()){
        
            //read the current state
            state_var1.read(state1, 0);

            if(standard_metadata.ingress_port == 0){
                
                port_map.read(value_register,(bit<32>)hdr.tcp.srcPort);
                
                //read the current issAssigned, server_index
                isAssigned = value_register[0:0];
                server_index = (bit<32>)value_register[1:1]; // typecasting
                
                if(hdr.tcp.syn==1){
                    //invalidate the previous entry
                    isAssigned = 0;
                }
                

                if(isAssigned==0){
                    if(state1==0){ 
                        server_index = 0;
                        isAssigned = 1;
                    }
                    if(state1==1){
                        hash(server_index, HashAlgorithm.crc16, (bit<16>)0, {hdr.tcp.srcPort}, (bit<32>)2);
                        isAssigned = 1;
                    }
                }

                //read again after writing
                state_var1.read(state1, 0);
                
                
                //update the port map register
                bit<2> temp;
                if(server_index == 0){
                    temp = 0;
                }
                else {
                    temp = 1;

                }
                
                value_register = temp<<1 | (bit<2>)isAssigned;
                port_map.write((bit<32>)hdr.tcp.srcPort, value_register);
                
                
                forward_nat.apply();
            }
            else{
            
                 reverse_nat.apply();

            }
            
            
       



        }
    }
}
            
control MyEgress(inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata) {
        apply {  }
}





control MyComputeChecksum(inout headers hdr,
           inout metadata meta)
{
    apply {
        update_checksum(true,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.options
            },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);

        update_checksum_with_payload(hdr.tcp.isValid(),
            { hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                8w0,
                hdr.ipv4.protocol,
                meta.l4Len,
                hdr.tcp.srcPort,
                hdr.tcp.dstPort,
                hdr.tcp.seqNo,
                hdr.tcp.ackNo,
                hdr.tcp.dataOffset,
                hdr.tcp.res,
                hdr.tcp.ecn,
                hdr.tcp.urg,
                hdr.tcp.ack,
                hdr.tcp.psh,
                hdr.tcp.rst,
                hdr.tcp.syn,
                hdr.tcp.fin,
                hdr.tcp.window,
                hdr.tcp.urgentPtr,
                hdr.tcp.options
            },
            hdr.tcp.checksum, HashAlgorithm.csum16);
    }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;