// =============================================================================
// Module name: NetworkInterface
//
// This module exports the network interface of the processing element and
// quadtree router.
// =============================================================================

`include "router.vh"
`include "pe.vh"

module NetworkInterface (
  input wire  [5:0]               PE_IDX,             // PE index
  input wire                      clk,                // system clock
  input wire                      rst,                // system reset

  // local port of the leaf router
  input wire                      in_data_valid,      // input data valid
  input wire  [`ROUTER_WIDTH-1:0] in_data,            // input data
  output wire                     out_data_valid,     // output data valid
  output wire [`ROUTER_WIDTH-1:0] out_data,           // output data
  input wire                      downstream_credit,  // credit from downstream
  output wire                     upstream_credit,    // credit to upstream

  // configuration interfaces
  // pe status registers
  input wire  [`PeActNoBus]       out_act_no,         // output activation no.
  output wire                     pe_status_we,       // pe status write enable
  output wire [`PeStatusAddrBus]  pe_status_addr,     // pe status write address
  output wire [`PeStatusDataBus]  pe_status_data,     // pe status write data
  input wire                      out_act_relu,       // out act relu
  // input activation configuration
  output wire                     in_act_write_en,    // input act write enable
  output wire [`PeActNoBus]       in_act_write_addr,  // input act write address
  output wire [`ActRegDataBus]    in_act_write_data,  // input act write data

  // read request interface (to activation register file)
  input wire  [`ActRegDataBus]    out_act_read_data,  // output activation read
  input wire  [`ActRegDataBus]    out_act_read_data_relu,
  output wire                     ni_read_rqst,       // read request
  output wire [`PeActNoBus]       ni_read_addr,       // read address

  // PE controller interface
  input wire                      act_send_en,        // act send enable
  input wire  [`ROUTER_ADDR_WIDTH-1:0]
                                  act_send_addr,      // act send address
  input wire  [`PeDataBus]        act_send_data,      // act send data
  input wire                      fin_comp,           // finish computation
  output wire                     pe_start_calc,      // PE start calculation
  output wire                     router_rdy,         // router is ready to send
  output wire                     comp_done,          // layer computation done
  // partial sum broadcast path
  input wire                      part_sum_send_en,   // partial sum send enable
  input wire  [`ROUTER_ADDR_WIDTH-1:0]
                                  part_sum_send_addr, // partial sum send addr
  input wire  [`PeDataBus]        part_sum_send_data, // partial sum send data

  // Activation queue interface
  input wire                      pop_act,            // pop activation
  output wire                     push_act,           // push activation
  output wire [`PEQueueBus]       act                 // activation
);

wire read_rqst_read_en;

// ----------------------------------
// Network interface input unit
// ----------------------------------
NIInputUnit ni_input_unit (
  .PE_IDX                 (PE_IDX),                   // PE index
  .clk                    (clk),                      // system clock
  .rst                    (rst),                      // system reset

  .router_rdy             (router_rdy),               // router ready

  // Input datapath
  .in_data_valid          (in_data_valid),            // input data valid
  .in_data                (in_data),                  // inpu data

  // PE status register interface
  .out_act_no             (out_act_no),               // out act no.
  .pe_status_we           (pe_status_we),             // pe status write enable
  .pe_status_addr         (pe_status_addr),           // pe status address
  .pe_status_data         (pe_status_data),           // pe status data

  // Activation register file interface
  .in_act_write_en        (in_act_write_en),          // in act write enable
  .in_act_write_addr      (in_act_write_addr),        // in act write address
  .in_act_write_data      (in_act_write_data),        // in act write data

  // PE controller interface
  .pe_start_calc          (pe_start_calc),            // pe start calculation
  .comp_done              (comp_done),                // computation done

  // Activation queue in processing element
  .pop_act                (pop_act),                  // pop activation
  .push_act               (push_act),                 // push activation
  .act                    (act),                      // activation to be pushed

  // Read request interface
  .read_rqst_read_en      (read_rqst_read_en),        // read rqst read enable
  .ni_read_rqst           (ni_read_rqst),             // read request enable
  .ni_read_addr           (ni_read_addr),             // read request address

  .upstream_credit        (upstream_credit)           // upstream credit
);

// ----------------------------------
// Network interface output unit
// ----------------------------------
NIOutputUnit ni_output_unit (
  .PE_IDX                 (PE_IDX),                   // PE index
  .clk                    (clk),                      // system clock
  .rst                    (rst),                      // system reset

  // PE controller interface
  .act_send_en            (act_send_en),              // act send enable
  .act_send_addr          (act_send_addr),            // act send address
  .act_send_data          (act_send_data),            // act send data
  .fin_comp               (fin_comp),                 // finish computation
  // partial sum broadcast path
  .part_sum_send_en       (part_sum_send_en),
  .part_sum_send_addr     (part_sum_send_addr),
  .part_sum_send_data     (part_sum_send_data),

  // NI read request interface
  .read_rqst_read_en      (read_rqst_read_en),        // read rqst read enable
  .ni_read_rqst           (ni_read_rqst),             // read request enable
  .ni_read_addr           (ni_read_addr),             // read request address

  // PE status registers
  .out_act_relu           (out_act_relu),             // output act relu

  // Activation register file interface
  .out_act_read_data      (out_act_read_data),        // output act read data
  .out_act_read_data_relu (out_act_read_data_relu),   // out act read data relu

  // Credit input from downstreaming router
  .downstream_credit      (downstream_credit),
  .router_rdy             (router_rdy),               // router ready

  // Output datapath
  .out_data_valid         (out_data_valid),
  .out_data               (out_data)                  // output data
);

endmodule
