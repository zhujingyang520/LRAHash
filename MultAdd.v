// =============================================================================
// Module name: MultAdd
//
// The file exports the basic module for doing the multiplication & addition.
// This module do the following computation:
//
//  y = a * b + c
//
// It is similar to the GEMM operation in BLAS.
// =============================================================================

module MultAdd #(
  parameter         BIT_WIDTH             = 16
) (
  input wire signed [BIT_WIDTH-1:0]       a,
  input wire signed [BIT_WIDTH-1:0]       b,
  input wire signed [BIT_WIDTH-1:0]       c,
  output wire signed [BIT_WIDTH-1:0]      y
);

assign y = a * b + c;

endmodule
