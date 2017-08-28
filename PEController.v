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
  input wire                    uv_en,              // UV enable for cur layer
  input wire  [`RankBus]        rank_no,            // rank number
  input wire  [`WMemAddrBus]    w_mem_offset,       // W memory offset
  input wire  [`UMemAddrBus]    u_mem_offset,       // U memory offset
  input wire  [`VMemAddrBus]    v_mem_offset,       // V memory offset

  // interfaces of activation register file
  output wire                   act_regfile_dir,    // act regfile direction

  // interfaces of network interfaces
  input wire                    router_rdy,         // router ready
  output wire                   act_send_en,        // act send enable
  output wire [`ROUTER_ADDR_WIDTH-1:0]
                                act_send_addr,      // act send address
  output wire [`PeDataBus]      act_send_data,      // act send data
  output wire                   part_sum_send_en,   // partial sum send enable
  output wire [`PeDataBus]      part_sum_send_data, // partial sum send data
  output wire [`ROUTER_ADDR_WIDTH-1:0]
                                part_sum_send_addr, // partial sum send address

  // activation register file
  input wire  [`PeDataBus]      in_act_read_data,   // in act read data
  output wire                   in_act_read_en,     // in act read enable
  output wire [`PeActNoBus]     in_act_read_addr,   // in act read address
  input wire  [`PE_ACT_NO-1:0]  in_act_zeros,       // in act zero flags
  input wire  [`PE_ACT_NO-1:0]  out_act_g_zeros,    // out act > 0 zero flags
  // secondary activation read port
  output wire                   out_act_read_en_s,  // read enable
  output wire [`PeActNoBus]     out_act_read_addr_s,// read address
  input wire  [`PeDataBus]      out_act_read_data_s,// read data

  // interfaces of PE activation queue
  input wire                    queue_empty,        // activation queue empty
  input wire                    queue_empty_next,
  input wire  [`PEQueueBus]     act_out,            // activation queue output
  output wire                   pop_act,            // activation queue pop
  output wire                   out_act_clear,      // output activation clear

  // computation datapath
  output wire [`CompEnBus]      comp_en,            // compute enable
  output wire [`PeAddrBus]      in_act_idx,         // input activation idx
  output wire [`PeActNoBus]     out_act_addr,       // output activation address
  output wire [`PeDataBus]      in_act_value,       // input activation value
  output wire [`WMemAddrBus]    mem_offset          // memory offset
);

// ------------------------------
// Interconnections
// ------------------------------
wire pe_start_broadcast;
wire in_act_read_en_comp, in_act_read_en_broadcast;
wire [`PeActNoBus] in_act_read_addr_comp, in_act_read_addr_broadcast;
wire part_sum_done;
wire fin_tx_part_sum;

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
  .part_sum_done                (part_sum_done),    // done one partial sum
  .fin_tx_part_sum              (fin_tx_part_sum),  // finish tx partial sum

  // PE status interface
  .layer_no                     (layer_no),         // total layer no.
  .in_act_no                    (in_act_no),        // input activation no.
  .out_act_no                   (out_act_no),       // output activation no.
  .uv_en                        (uv_en),            // UV enable for cur layer
  .rank_no                      (rank_no),          // rank number
  .layer_idx                    (layer_idx),        // current layer index
  .w_mem_offset                 (w_mem_offset),     // W memory offset
  .u_mem_offset                 (u_mem_offset),     // U memory offset
  .v_mem_offset                 (v_mem_offset),     // V memory offset

  // Activation register file
  .in_act_zeros                 (in_act_zeros),     // input activation zero
  .act_regfile_dir              (act_regfile_dir),
  .in_act_read_en               (in_act_read_en_comp),
  .in_act_read_addr             (in_act_read_addr_comp),
  .in_act_read_data             (in_act_read_data), // input act read data
  .out_act_g_zeros              (out_act_g_zeros),  // output act > zeros

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
  .in_act_value                 (in_act_value),     // input activation value
  .mem_offset                   (mem_offset)        // memory offset
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
  .in_act_read_en               (in_act_read_en_broadcast),
  .in_act_read_addr             (in_act_read_addr_broadcast),
  .in_act_read_data             (in_act_read_data), // read data
  .in_act_zeros                 (in_act_zeros),     // input activation zero

  // network interface
  .act_send_en                  (act_send_en),      // activation send enable
  .act_send_data                (act_send_data),    // activation send data
  .act_send_addr                (act_send_addr)     // activation send address
);

// Mux stage
PEControllerMux pe_controller_mux (
  // COMP FSM
  .in_act_read_en_comp          (in_act_read_en_comp),
  .in_act_read_addr_comp        (in_act_read_addr_comp),
  // BROADCAST FSM
  .in_act_read_en_broadcast     (in_act_read_en_broadcast),
  .in_act_read_addr_broadcast   (in_act_read_addr_broadcast),

  // To register file
  .in_act_read_en               (in_act_read_en),   // read enable
  .in_act_read_addr             (in_act_read_addr)  // read address
);

// ----------------------------------------------------------
// FSM for broadcasting the partial sum during V computation
// ----------------------------------------------------------
PEBroadcastPartSumFSM pe_broadcast_part_sum_fsm (
  .PE_IDX                       (PE_IDX),           // PE index
  .clk                          (clk),              // system clock
  .rst                          (rst),              // system reset

  .router_rdy                   (router_rdy),       // router is ready
  .part_sum_done                (part_sum_done),    // one partial sum done
  .rank_no                      (rank_no),          // rank number
  .fin_tx_part_sum              (fin_tx_part_sum),  // finish tx partial sum

  // output activations of the register file
  // use secondary read port
  .out_act_read_en_s            (out_act_read_en_s),  // read enable
  .out_act_read_addr_s          (out_act_read_addr_s),// read address
  .out_act_read_data_s          (out_act_read_data_s),// read data

  // interfaces of network interface
  .part_sum_send_en             (part_sum_send_en),   // partial sum send enable
  .part_sum_send_data           (part_sum_send_data), // partial sum send data
  .part_sum_send_addr           (part_sum_send_addr)  // partial sum send address
);

endmodule
