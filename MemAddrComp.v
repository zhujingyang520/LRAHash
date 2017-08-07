// =============================================================================
// Module name: MemAddrComp
//
// This module exports the on-chip SRAM address computation
// =============================================================================

`include "pe.vh"

module MemAddrComp (
  input wire  [5:0]           PE_IDX,           // PE index
  input wire                  clk,              // system clock
  input wire                  rst,              // system reset (active high)

  // Input datapath & control path
  input wire                  comp_en,          // computation enable
  input wire  [`PeLayerNoBus] layer_idx,        // layer index
  input wire  [`PeAddrBus]    in_act_idx,       // input activation index
  input wire  [`PeActNoBus]   out_act_addr,     // output activation address
  input wire  [`PeAddrBus]    col_dim,          // column dimension
  input wire  [`WMemAddrBus]  w_mem_offset,     // weight memory address offset
  input wire  [`PeDataBus]    in_act_value,     // input activation value

  // Output datapath & control path (memory stage)
  output reg                  comp_en_mem,      // computation enable
  output reg  [`PeDataBus]    in_act_value_mem, // input activation value
  output reg  [`PeActNoBus]   out_act_addr_mem, // output activation address

  // Weight memory interfaces (active low)
  output reg                  w_mem_cen,        // weight memory enable
  output reg                  w_mem_wen,        // weight memory write enable
  output reg  [`WMemAddrBus]  w_mem_addr        // weight memory address
);

// TODO: address computation using pseudo hash
wire [`PeAddrBus] out_act_idx = {out_act_addr, PE_IDX};
wire [`WMemAddrBus] addr = w_mem_offset + out_act_addr * col_dim + in_act_idx;
wire [`WMemAddrBus] hash_result = comp_en ? addr : 0;

// -------------------------------------------
// Pipeline the input datapath & control path
// -------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_mem       <= 1'b0;
    in_act_value_mem  <= 0;
    out_act_addr_mem  <= 0;
  end else begin
    comp_en_mem       <= comp_en;
    in_act_value_mem  <= in_act_value;
    out_act_addr_mem  <= out_act_addr;
  end
end

// ----------------------------------------------
// Generate the weight SRAM control interface
// ----------------------------------------------
// These signals are provided in the current cycle
always @ (*) begin
  w_mem_cen   = ~comp_en;
  w_mem_wen   = 1'b1; // always @ read operation
  w_mem_addr  = hash_result;
end

endmodule
