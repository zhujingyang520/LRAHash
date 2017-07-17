// =============================================================================
// Module name: HashEngine
//
// This module exports the HashEngine, which is used for the computation of the
// physical address in the memory. It is the first pipeline stage of the
// computation datapath.
// =============================================================================

`include "pe.vh"

module HashEngine # (
  parameter   PE_IDX          = 0               // PE index
) (
  input wire                  clk,              // system clock
  input wire                  rst,              // system reset (active high)

  // Input datapath
  input wire                  comp_en,          // computation enable
  input wire  [`PeLayerNoBus] layer_idx,        // layer index
  input wire  [`PeAddrBus]    in_act_idx,       // input activation index
  input wire  [`PeAddrBus]    out_act_idx,      // output activation index
  input wire  [`PeActNoBus]   out_act_addr,     // output activation address
  input wire  [`PeDataBus]    in_act_value,     // input activation value

  // Output datapath (memory stage)
  output reg                  comp_en_mem,      // computation enable
  output reg  [`PeDataBus]    in_act_value_mem, // input activation value
  output reg  [`PeActNoBus]   out_act_addr_mem, // output activation address

  // Weight memory interfaces (active low)
  output reg                  w_mem_cen,        // weight memory enable
  output reg                  w_mem_wen,        // weight memory write enable
  output reg  [`WMemAddrBus]  w_mem_addr        // weight memory address
);

// TODO: address computation using pseudo hash
wire [`WMemAddrBus] hash_result = 0;

// ----------------------------
// Pipeline the input datapath
// ----------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_mem       <= 1'b0;
    in_act_value_mem  <= 0;
    out_act_addr_mem  <= 0;
  end else if (comp_en == 1'b1) begin
    comp_en_mem       <= 1'b1;
    in_act_value_mem  <= in_act_value;
    out_act_addr_mem  <= out_act_addr;
  end else begin
    comp_en_mem       <= 1'b0;
    in_act_value_mem  <= 0;
    out_act_addr_mem  <= 0;
  end
end

// -----------------------------------
// Generate the weight SRAM interface
// -----------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    w_mem_cen         <= 1'b1;
    w_mem_wen         <= 1'b1;
    w_mem_addr        <= 0;
  end else if (comp_en == 1'b1) begin
    w_mem_cen         <= 1'b0;
    w_mem_wen         <= 1'b1;
    w_mem_addr        <= hash_result;
  end else begin
    w_mem_cen         <= 1'b1;
    w_mem_wen         <= 1'b1;
    w_mem_addr        <= 0;
  end
end

endmodule
