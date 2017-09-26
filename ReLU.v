// =============================================================================
// Module name: ReLU
//
// This module exports the Rectified Linear Unit (ReLU) circuit.
// =============================================================================

module ReLU #(
  parameter   BIT_WIDTH         = 16          // datapath bit width
) (
  input wire  [BIT_WIDTH-1:0]   in_data,      // input data
  output wire [BIT_WIDTH-1:0]   out_data      // output data
);

// sign bit: MSB
assign out_data = in_data[BIT_WIDTH-1] ? 0 : in_data;

endmodule
