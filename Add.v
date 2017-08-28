// =============================================================================
// Module name: Add
//
// This file exports the addition pipeline stage of the accelerator. It conducts
// the addition of the multiplication results of activation and weights and the
// output activation value.
// =============================================================================

`include "pe.vh"

module Add (
  input wire                  clk,                // system clock
  input wire                  rst,                // system reset (active high)

  // Input datapath & control path (add stage)
  input wire  [`CompEnBus]    comp_en_add,        // computation enable
  input wire  [`PeDataBus]    out_act_value_add,  // output activation value
  input wire  [`PeDataBus]    mult_result_add,    // multiplication result
  input wire  [`PeActNoBus]   out_act_addr_add,   // output activation address

  // Output datapath & control path (wb stage)
  output reg                  out_act_write_en,   // output act write enable
  output reg  [`PeActNoBus]   out_act_addr_wb,    // output activation address
  output reg  [`PeDataBus]    add_result_wb       // addition result
);

// ------------------------------
// Intermediate addition results
// ------------------------------
wire [`PeDataBus] add_result;

// -----------------------------------------------
// Do the addition here. (Rely on Synthesis Tool)
// -----------------------------------------------
assign add_result = out_act_value_add + mult_result_add;

// -----------------------
// Output pipeline stage
// -----------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    out_act_write_en  <= 1'b0;
    out_act_addr_wb   <= 0;
    add_result_wb     <= 0;
  end else begin
    out_act_write_en  <= (comp_en_add != `COMP_EN_IDLE);
    out_act_addr_wb   <= out_act_addr_add;
    add_result_wb     <= add_result;
  end
end

endmodule
