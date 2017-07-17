// =============================================================================
// Module name: LNZDRange
//
// This module exports the Leading nonzero detection of the specified range:
// [start, stop]
// =============================================================================

module LNZDRange #(
  parameter   BIT_WIDTH           = 8           // bit width (power of 2)
) (
  input wire  [BIT_WIDTH-1:0]     data_in,      // input data to be detected
  input wire  [clog2(BIT_WIDTH)-1:0]
                                  start,        // start range
  input wire  [clog2(BIT_WIDTH)-1:0]
                                  stop,         // stop range

  output wire [clog2(BIT_WIDTH)-1:0]
                                  position,     // nonzero position within range
  output wire                     valid         // valid for nonzero element
);

genvar g;

// Mask the data input out of the specified range
wire [BIT_WIDTH-1:0] data_in_mask;

// -----------------
// Mask data input
// -----------------
generate
for (g = 0; g < BIT_WIDTH; g = g + 1) begin: gen_data_mask
  assign data_in_mask[g] = (g >= start && g <= stop) ? data_in[g] : 1'b0;
end
endgenerate

// LNZD instance
LNZD #(
  .BIT_WIDTH      (BIT_WIDTH)           // bit width (power of 2)
) lnzd (
  .data_in        (data_in_mask),       // input data to be detected
  .position       (position),           // nonzero element position
  .valid          (valid)               // existence of nonzero elements
);

// --------------------------------
// Function: clog2
// Returns the ceil of the log2(x)
// --------------------------------
function integer clog2(input integer x);
  integer i;
  begin
    clog2 = 0;
    for (i = x - 1; i > 0; i = i >> 1) begin
      clog2 = clog2 + 1;
    end
  end
endfunction

endmodule
