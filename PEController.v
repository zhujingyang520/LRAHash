// =============================================================================
// Module name: PEController
//
// This module exports the FSM controller to coordinate the data path in each
// processing element.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module PEController #(
  parameter   PE_IDX            = 0                 // PE index
) (
  input wire                    clk,                // system clock
  input wire                    rst,                // system reset

  input wire                    pe_start_calc,      // start calculation

  // interfaces of PE state registers
  input wire  [`PeLayerNoBus]   layer_no,           // total layer no.
  output wire [`PeLayerNoBus]   layer_idx,          // layer index
  input wire  [`PeActNoBus]     in_act_no,          // input activation no.
  input wire  [`PeActNoBus]     out_act_no,         // output activation no.

  // interfaces of network interfaces
  input wire                    router_rdy,         // router ready
  output wire                   act_send_en,        // act send enable
  output wire [`ROUTER_ADDR_WIDTH-1:0]
                                act_send_addr,      // act send address
  output wire [`PeDataBus]      act_send_data,      // act send data

  // activation register file
  input wire  [`PeDataBus]      in_act_read_data,   // in act read data
  output wire                   in_act_read_en,     // in act read enable
  output wire [`PeActNoBus]     in_act_read_addr,   // in act read address

  // interfaces of PE activation queue
  input wire                    queue_empty,        // activation queue empty
  input wire  [`PEQueueBus]     act_out,            // activation queue output
  output wire                   pop_act,            // activation queue pop
  output wire                   out_act_clear,      // output activation clear

  // computation datapath
  output wire                   comp_en,            // compute enable
  output wire [`PeAddrBus]      in_act_idx,         // input activation idx
  output wire [`PeAddrBus]      out_act_idx,        // output activation idx
  output wire [`PeActNoBus]     out_act_addr,       // output activation address
  output wire [`PeDataBus]      in_act_value        // input activation value
);

// ------------------------------
// Two FSM controllers
// ------------------------------
// Computation FSM
PEComputationFSM #(.PE_IDX(PE_IDX)) pe_computation_fsm (
  .clk                          (clk),              // system clock
  .rst                          (rst),              // system reset
  .pe_start_calc                (pe_start_calc),    // start calcultion

  // PE status interface
  .layer_no                     (layer_no),         // total layer no.
  .out_act_no                   (out_act_no),       // output activation no.
  .layer_idx                    (layer_idx),        // current layer index

  // PE activation queue interface
  .queue_empty                  (queue_empty),      // activation queue empty
  .act_out                      (act_out),          // activation queue output
  .pop_act                      (pop_act),          // activation queue pop
  .out_act_clear                (out_act_clear),    // output activation clear

  // Computation datapath
  .comp_en                      (comp_en),          // compute enable
  .in_act_idx                   (in_act_idx),       // input activation idx
  .out_act_idx                  (out_act_idx),      // output activation idx
  .out_act_addr                 (out_act_addr),     // output activation address
  .in_act_value                 (in_act_value)      // input activation value
);

// Broadcast FSM
PEBroadcastFSM #(.PE_IDX(PE_IDX)) pe_broadcast_fsm (
  .clk                          (clk),              // system clock
  .rst                          (rst),              // system reset

  .router_rdy                   (router_rdy),       // router is ready
  .pe_start_calc                (pe_start_calc),    // start calculation

  .in_act_no                    (in_act_no),        // input activation no.

  // activation register interface
  .in_act_read_en               (in_act_read_en),   // input act read enable
  .in_act_read_addr             (in_act_read_addr), // read address
  .in_act_read_data             (in_act_read_data), // read data

  // network interface
  .act_send_en                  (act_send_en),      // activation send enable
  .act_send_data                (act_send_data),    // activation send data
  .act_send_addr                (act_send_addr)     // activation send address
);

endmodule
