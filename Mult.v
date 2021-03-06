// =============================================================================
// Module name: Mult
//
// This file exports the multiplication pipeline stage for the accelerator. It
// conducts the multiplication of an input activation and a synaptic weight.
// =============================================================================

`include "pe.vh"

module Mult (
  input wire                  clk,                // system clock
  input wire                  rst,                // system reset (active high)

  // Input datapath & control path (mult stage)
  input wire  [`CompEnBus]    comp_en_mult,       // computation enable
  input wire  [`PeDataBus]    in_act_value_mult,  // input activation value
  input wire  [`PeDataBus]    mem_value_mult,     // memory value
  input wire  [`PeActNoBus]   out_act_addr_mult,  // output activation address
  // Truncation scheme
  input wire  [`TruncWidth]   trunc_amount_mult,  // truncation scheme

  // Output datapath & control path (add stage)
  output reg  [`CompEnBus]    comp_en_add,        // computation enable
  output reg  [`PeActNoBus]   out_act_addr_add,   // output activation address
  output reg  [`TruncWidth]   trunc_amount_add,   // truncation scheme
  output reg  [`DoublePeDataBus]
                              mult_result_add     // multiplication result
);

// ------------------------------------
// Intermediate multiplication results
// ------------------------------------
wire [2*`PE_DATA_WIDTH-1:0] mult_result;

// -----------------------------------------------------------------------------
// Do the multiplication here. (Rely on the Synethsize Tool, e.g. Designware, to
// infer a constrain-driven design.
// -----------------------------------------------------------------------------
assign mult_result = $signed(in_act_value_mult) * $signed(mem_value_mult);

// -----------------------------------------------------
// Do the truncation of 32-bit multiplication result
// In adding stage (critical path here)
// -----------------------------------------------------

// -----------------------
// Output pipeline stage
// -----------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_add       <= `COMP_EN_IDLE;
    out_act_addr_add  <= 0;
    mult_result_add   <= 0;
    trunc_amount_add  <= 0;
  end else begin
    comp_en_add       <= comp_en_mult;
    out_act_addr_add  <= out_act_addr_mult;
    mult_result_add   <= mult_result;
    trunc_amount_add  <= trunc_amount_mult;
  end
end

endmodule
