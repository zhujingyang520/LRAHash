// =============================================================================
// Module name: Add
//
// This file exports the addition pipeline stage of the accelerator. It conducts
// the addition of the multiplication results of activation and weights and the
// output activation value.
// =============================================================================

`include "pe.vh"

module Add (
  input wire  [5:0]           PE_IDX,             // PE index
  input wire                  clk,                // system clock
  input wire                  rst,                // system reset (active high)

  // Input datapath & control path (add stage)
  input wire  [`CompEnBus]    comp_en_add,        // computation enable
  input wire  [`ActRegDataBus]out_act_value_add,  // output activation value
  input wire  [`TruncWidth]   trunc_amount_add,   // truncation scheme
  input wire  [`DoublePeDataBus]
                              mult_result_add,    // multiplication result
  input wire  [`PeActNoBus]   out_act_addr_add,   // output activation address

  // Output datapath & control path (wb stage)
  output reg                  out_act_write_en,   // output act write enable
  output reg  [`PeActNoBus]   out_act_addr_wb,    // output activation address
  output reg  [`ActRegDataBus]add_result_wb       // addition result
);

// ------------------------------
// Intermediate addition results
// ------------------------------
wire [`ActRegDataBus] add_result;
wire [`DoublePeDataBus] mult_result_shift;
wire [`PeDataBus] mult_result_trunc;

// ------------------------------
// Do the truncation here
// ------------------------------
assign mult_result_shift = $signed(mult_result_add) >>> trunc_amount_add;
assign mult_result_trunc = mult_result_shift[`PeDataBus];

// -----------------------------------------------
// Do the addition here. (Rely on Synthesis Tool)
// -----------------------------------------------
assign add_result = out_act_value_add +
  {{(`ACT_REG_DATA_WIDTH-`PE_DATA_WIDTH){mult_result_trunc[`PE_DATA_WIDTH-1]}},
  mult_result_trunc};

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

// ---------------------------------
// Overflow detection
// ---------------------------------
// synopsys translate_off
wire op1_sign = out_act_value_add[`ACT_REG_DATA_WIDTH-1];
wire op2_sign = mult_result_trunc[`PE_DATA_WIDTH-1];
wire result_sign = add_result[`ACT_REG_DATA_WIDTH-1];
always @ (posedge clk) begin
  if (comp_en_add != `COMP_EN_IDLE) begin
    if (op1_sign == op2_sign && result_sign != op1_sign) begin
      $display("[WARNING]: PE[%d] add overflow happens @ %t", PE_IDX, $time);
    end
  end

end
// synopsys translate_on

endmodule
