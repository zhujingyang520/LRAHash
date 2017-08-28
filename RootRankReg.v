// =============================================================================
// Module name: RootRankReg
//
// This file exports the module @ the root node. It consists of a bank of
// registers store the merging results of V computation results.
// =============================================================================

`include "pe.vh"

module RootRankReg (
  input wire                            clk,          // system clock
  input wire                            rst,          // system reset
  input wire                            rank_we,      // rank write enable
  input wire  [`RankBus]                rank_waddr,   // rank write address
  input wire  [`PeDataBus]              rank_wdata,   // rank write data

  input wire                            rank_re,      // rank read enable
  input wire  [`RankBus]                rank_raddr,   // rank read address
  output reg  [`PeDataBus]              rank_rdata    // rank read data
);

integer i;

// ------------------------------------
// Internal registers holding the rank
// ------------------------------------
reg [`PeDataBus] rank_reg [2**`RANK_WIDTH-1:0];

// ------------------------------------
// Write operation
// ------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    for (i = 0; i < 2**`RANK_WIDTH; i = i + 1) begin
      rank_reg[i]         <= 0;
    end
  end else if (rank_we) begin
    rank_reg[rank_waddr]  <= rank_wdata;
  end
end

// ------------------------------------
// Read operation (Combinational)
// ------------------------------------
always @ (*) begin
  if (rank_re) begin
    // there is no RAW data hazard
    rank_rdata            = rank_reg[rank_raddr];
  end else begin
    rank_rdata            = 0;
  end
end

endmodule
