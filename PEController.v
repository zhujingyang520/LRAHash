// =============================================================================
// Module name: PEController
//
// This module exports the FSM controller to coordinate the data path in each
// processing element.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module PEController (
  input wire  [5:0]             PE_IDX,             // PE index
  input wire                    clk,                // system clock
  input wire                    rst,                // system reset

  // interfaces of network interface
  input wire                    pe_start_calc,      // start calculation
  input wire                    comp_done,          // layer computation done
  output wire                   fin_comp,           // finish computation

  // interfaces of PE state registers
  input wire  [`PeLayerNoBus]   layer_no,           // total layer no.
  output wire [`PeLayerNoBus]   layer_idx,          // layer index
  input wire  [`PeActNoBus]     in_act_no,          // input activation no.
  input wire  [`PeActNoBus]     out_act_no,         // output activation no.

  // interfaces of activation register file
  output wire                   act_regfile_dir,    // act regfile direction

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
  input wire  [`PE_ACT_NO-1:0]  in_act_zeros,       // in act zero flags

  // interfaces of PE activation queue
  input wire                    queue_empty,        // activation queue empty
  input wire                    queue_empty_next,
  input wire  [`PEQueueBus]     act_out,            // activation queue output
  output wire                   pop_act,            // activation queue pop
  output wire                   out_act_clear,      // output activation clear

  // computation datapath
  output wire                   comp_en,            // compute enable
  output wire [`PeAddrBus]      in_act_idx,         // input activation idx
  output wire [`PeActNoBus]     out_act_addr,       // output activation address
  output wire [`PeDataBus]      in_act_value        // input activation value
);

// ------------------------------
// Interconnections
// ------------------------------
wire pe_start_broadcast;

// ------------------------------
// Two FSM controllers
// ------------------------------
// Computation FSM
PEComputationFSM pe_computation_fsm (
  .PE_IDX                       (PE_IDX),           // PE index
  .clk                          (clk),              // system clock
  .rst                          (rst),              // system reset
  .pe_start_calc                (pe_start_calc),    // start calcultion
  .pe_start_broadcast           (pe_start_broadcast),
                                                    // start broadcast
  .fin_comp                     (fin_comp),         // finish computation
  .comp_done                    (comp_done),        // layer computation done

  // PE status interface
  .layer_no                     (layer_no),         // total layer no.
  .out_act_no                   (out_act_no),       // output activation no.
  .layer_idx                    (layer_idx),        // current layer index

  // Activation register file
  .act_regfile_dir              (act_regfile_dir),

  // PE activation queue interface
  .queue_empty                  (queue_empty),      // activation queue empty
  .queue_empty_next             (queue_empty_next),
  .act_out                      (act_out),          // activation queue output
  .pop_act                      (pop_act),          // activation queue pop
  .out_act_clear                (out_act_clear),    // output activation clear

  // Computation datapath
  .comp_en                      (comp_en),          // compute enable
  .in_act_idx                   (in_act_idx),       // input activation idx
  .out_act_addr                 (out_act_addr),     // output activation address
  .in_act_value                 (in_act_value)      // input activation value
);

// Broadcast FSM
PEBroadcastFSM pe_broadcast_fsm (
  .PE_IDX                       (PE_IDX),           // PE index
  .clk                          (clk),              // system clock
  .rst                          (rst),              // system reset

  .router_rdy                   (router_rdy),       // router is ready
  .pe_start_broadcast           (pe_start_broadcast),
                                                    // start broadcast

  .in_act_no                    (in_act_no),        // input activation no.

  // activation register interface
  .in_act_read_en               (in_act_read_en),   // input act read enable
  .in_act_read_addr             (in_act_read_addr), // read address
  .in_act_read_data             (in_act_read_data), // read data
  .in_act_zeros                 (in_act_zeros),     // input activation zero

  // network interface
  .act_send_en                  (act_send_en),      // activation send enable
  .act_send_data                (act_send_data),    // activation send data
  .act_send_addr                (act_send_addr)     // activation send address
);

endmodule
