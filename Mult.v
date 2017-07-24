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
  input wire                  comp_en_mult,       // computation enable
  input wire  [`PeDataBus]    in_act_value_mult,  // input activation value
  input wire  [`PeDataBus]    w_value_mult,       // weight value
  input wire  [`PeActNoBus]   out_act_addr_mult,  // output activation address

  // Output datapath & control path (add stage)
  output reg                  comp_en_add,        // computation enable
  output reg  [`PeActNoBus]   out_act_addr_add,   // output activation address
  output reg  [`PeDataBus]    mult_result_add     // multiplication result
);

// ------------------------------------
// Intermediate multiplication results
// ------------------------------------
wire [`PeDataBus] mult_result;

// -----------------------------------------------------------------------------
// Do the multiplication here. (Rely on the Synethsize Tool, e.g. Designware, to
// infer a constrain-driven design.
// -----------------------------------------------------------------------------
assign mult_result = $signed(in_act_value_mult) * $signed(w_value_mult);

// -----------------------
// Output pipeline stage
// -----------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_add       <= 1'b0;
    out_act_addr_add  <= 0;
    mult_result_add   <= 0;
  end else begin
    comp_en_add       <= comp_en_mult;
    out_act_addr_add  <= out_act_addr_mult;
    mult_result_add   <= mult_result;
  end
end

endmodule
