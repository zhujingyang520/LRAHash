// ====================================================================
// Basic module for merging position and valid of one-level up in LNZD
// ====================================================================

module LNZDMerge #(
  parameter   BIT_WIDTH           = 1           // bit width of position
) (
  input wire  [BIT_WIDTH-1:0]     position_msb, // position of MSB
  input wire                      valid_msb,    // valid of MSB
  input wire  [BIT_WIDTH-1:0]     position_lsb, // position of LSB
  input wire                      valid_lsb,    // valid of LSB

  output reg  [BIT_WIDTH:0]       position,     // one-level up of position
  output wire                     valid         // one-level up of valid
);

always @ (*) begin
  if (valid_lsb) begin
    // there exists 1 in LSB
    position = {1'b0, position_lsb};
  end else begin
    // no 1s in LSB
    position = {1'b1, position_msb};
  end
end

// valid: assert when either valid in MSB or LSB is asserted
assign valid = valid_msb | valid_lsb;

endmodule
