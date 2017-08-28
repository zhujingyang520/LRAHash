// =============================================================================
// Module name: RootRankState
//
// This file exports the state register in the root rank module. It includes the
// rank dimension in each stage.
// =============================================================================

`include "pe.vh"

module RootRankState (
  input wire                          clk,            // system clock
  input wire                          rst,            // system reset
  // write operation (configuration, 2 data in parallel)
  input wire                          state_we,       // state write enable
  input wire  [1:0]                   state_waddr,    // state write address
  input wire  [2*`RANK_WIDTH-1:0]     state_wdata,    // state write data

  // read operation
  input wire  [`PeLayerNoBus]         layer_idx,      // state read address
  output wire [`RANK_WIDTH-1:0]       rank_no,        // rank number
  output wire                         uv_en           // UV bypass enable
);

// Max layer no: 2 ^ layer no bus width
localparam integer MAX_LAYER_NO = 2**`PE_LAYER_NO_WIDTH;

integer i;

// state registers storing the rank number
reg [`RankBus] rank_no_reg [MAX_LAYER_NO-3:0];
// UV enable register
reg [MAX_LAYER_NO-1:0] uv_en_reg;

// ------------------------------------
// Write operation of the rank number
// Hardcode the write location
// ------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    for (i = 0; i < MAX_LAYER_NO-2; i = i + 1) begin
      rank_no_reg[i]    <= 0;
    end
    uv_en_reg           <= 0;
  end else if (state_we) begin
    case (state_waddr)
      2'b00: begin
        rank_no_reg[0]  <= state_wdata[`RANK_WIDTH-1:0];
        rank_no_reg[1]  <= state_wdata[2*`RANK_WIDTH-1:`RANK_WIDTH];
      end
      2'b01: begin
        rank_no_reg[2]  <= state_wdata[`RANK_WIDTH-1:0];
        rank_no_reg[3]  <= state_wdata[2*`RANK_WIDTH-1:`RANK_WIDTH];
      end
      2'b10: begin
        rank_no_reg[4]  <= state_wdata[`RANK_WIDTH-1:0];
        rank_no_reg[5]  <= state_wdata[2*`RANK_WIDTH-1:`RANK_WIDTH];
      end
      2'b11: begin
        uv_en_reg       <= state_wdata[MAX_LAYER_NO-1:0];
      end
    endcase
  end
end

// --------------------------------------
// read operation (combinational)
// --------------------------------------
assign rank_no = rank_no_reg[layer_idx];
assign uv_en = uv_en_reg[layer_idx];

endmodule
