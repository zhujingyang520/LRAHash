// =============================================================================
// Module name: LNZD_X
//
// This module exports a series of Leading NonZero Detection units (LNZD). The
// LNZD has X-bit input. It detects the location of the first nonzero element,
// and generates a valid signal to indicate whether the input is of full 0s.
//
// Implementation details:
// Use radix-2 based design to hierarchically construct the X-input LNZD.
// Refererence:
//    An algorithmic and Novel Design of a Leading Zero Detector Circuit:
//    Comparison with Logic Synthesis
// =============================================================================

module LNZD #(
  parameter   BIT_WIDTH           = 8           // bit width (power of 2)
) (
  input wire  [BIT_WIDTH-1:0]     data_in,      // input data to be detected
  output wire [clog2(BIT_WIDTH)-1:0]
                                  position,     // nonzero element position
  output wire                     valid         // existence of nonzero elements
);

genvar g, gg;

// Hierachical Network For N-bit LNZD
generate
for (g = 0; g < clog2(BIT_WIDTH); g = g + 1) begin: gen_lnzd_network
wire valid_i [(BIT_WIDTH/2**(g+1))-1:0];
wire [g:0] position_i [(BIT_WIDTH/2**(g+1))-1:0];
if (g == 0) begin: gen_lnzd_network_l0
  // 1st level: use LNZD2
  for (gg = 0; gg < BIT_WIDTH/2**(g+1); gg = gg + 1) begin: gen_lnzd2
  LNZD2 lnzd2 (
    .data_in  ({data_in[2*gg+1], data_in[2*gg]}),   // input data
    .position (gen_lnzd_network[g].position_i[gg]), // position
    .valid    (gen_lnzd_network[g].valid_i[gg])     // valid
  );
  end
end
else begin: gen_lnzd_network_merge
  for (gg = 0; gg < BIT_WIDTH/2**(g+1); gg = gg + 1) begin: gen_merge
  LNZDMerge #(
    .BIT_WIDTH    (g)                             // bit width of position
  ) lnzd_merge (
    .position_msb (gen_lnzd_network[g-1].position_i[2*gg+1]),
    .valid_msb    (gen_lnzd_network[g-1].valid_i[2*gg+1]),
    .position_lsb (gen_lnzd_network[g-1].position_i[2*gg]),
    .valid_lsb    (gen_lnzd_network[g-1].valid_i[2*gg]),

    .position     (gen_lnzd_network[g].position_i[gg]),
    .valid        (gen_lnzd_network[g].valid_i[gg])
  );
  end
end
end   // for g
endgenerate

// Primary output connections
assign valid = gen_lnzd_network[clog2(BIT_WIDTH)-1].valid_i[0];
assign position = gen_lnzd_network[clog2(BIT_WIDTH)-1].position_i[0];

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

// ==========================================
// Basic module for building the 2-bit LNZD
// ==========================================
module LNZD2 (
  input wire  [1:0]               data_in,      // input data
  output reg                      position,     // position of nonzero element
  output wire                     valid         // valid for nonzero elements
);

// position: the first nonzero element's position
always @ (*) begin
  case (data_in)
    2'b01, 2'b11: begin
      position  = 1'b0;
    end
    2'b10: begin
      position  = 1'b1;
    end
    default: begin
      position  = 1'b0;
    end
  endcase
end

// valid: asserts when any data input is nonzero
assign valid = data_in[0] | data_in[1];

endmodule

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
