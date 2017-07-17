// =============================================================================
// Module name: MemAccess
//
// This module exports the memory access stage of the computation datapath.
// =============================================================================

`include "pe.vh"

module MemAccess (
  input wire                  clk,              // system clock
  input wire                  rst,              // system reset

  // Input datapath (memory stage)
  input wire                  comp_en_mem,      // computation enable (mem)
  input wire  [`PeDataBus]    in_act_value_mem, // input activation value (mem)
  input wire  [`PeActNoBus]   out_act_addr_mem, // output activation address
  input wire                  w_mem_cen,        // weight memory enable
  input wire                  w_mem_wen,        // weight memory write enable
  input wire  [`WMemAddrBus]  w_mem_addr,       // weight memory address

  // output datapath (mac stage)
  output reg                  comp_en_mac,      // computation enable (mac)
  output reg  [`PeDataBus]    in_act_value_mac, // input activation value (mac)
  output wire [`PeDataBus]    w_value_mac,      // weight value (mac)
  output reg  [`PeActNoBus]   out_act_addr_mac  // output activation address
);

// -------------------------------
// Pipeline stage of the datapath
// -------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_mac       <= 1'b0;
    in_act_value_mac  <= 0;
    out_act_addr_mac  <= 0;
  end else if (comp_en_mem) begin
    comp_en_mac       <= 1'b1;
    in_act_value_mac  <= in_act_value_mem;
    out_act_addr_mac  <= out_act_addr_mem;
  end else begin
    comp_en_mac       <= 1'b0;
    in_act_value_mac  <= 0;
    out_act_addr_mac  <= 0;
  end
end

// ----------------------------------------------------------------
// Instantiate the on-chip SRAM (TODO: replace the behavior model)
// ----------------------------------------------------------------
spram_behav # (
  .MEM_WIDTH          (`W_MEM_DATA_WIDTH),      // memory (bus) width
  .MEM_DEPTH          (2**`W_MEM_ADDR_WIDTH)    // memory depth
) w_mem (
  .clk                (clk),                    // system clock
  .cen                (w_mem_cen),              // chip enable (active low)
  .wen                (w_mem_wen),              // write enable (active low)
  .addr               (w_mem_addr),             // read/write address
  .d                  (`W_MEM_ADDR_WIDTH'd0),   // data input (write op)
  .q                  (w_value_mac)             // data output (read op)
);

endmodule
