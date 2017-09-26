// =============================================================================
// Module name: RootRankController
//
// This module exports the root rank controller for the Root Node. It
// coordinates the controlling states of the Rank storage in the Root Node.
// =============================================================================

`include "pe.vh"
`include "global.vh"
`include "router.vh"

module RootRankController (
  input wire                        clk,              // system clock
  input wire                        rst,              // system reset

  // interface of the root controller
  input wire                        router_rdy,       // router ready
  output reg                        rank_tx_en,       // rank transmit enable
  output reg  [`ROUTER_WIDTH-1:0]   rank_tx_data,     // rank transmit data
  input wire                        clear_bias_offset,// clear offset
  input wire                        update_bias_offset, // update offset

  // input data port from the router
  input wire                        in_data_valid,    // input data valid
  input wire  [`ROUTER_WIDTH-1:0]   in_data,          // input data

  // input data port of the write operation (primary output)
  input wire                        write_en,         // write enable
  input wire                        write_rdy,        // write ready
  input wire  [`DataBus]            write_data,       // write data
  input wire  [`AddrBus]            write_addr,       // write address

  // interfaces of the RootRank bias memory
  output reg                        rank_bias_mem_wen,
  output reg                        rank_bias_mem_cen,
  output reg                        rank_bias_mem_oe,
  output reg  [`RankBiasMemAddrBus] rank_bias_mem_addr,
  input wire  [`RankBiasMemDataBus] rank_bias_mem_q,

  // interfaces of RootRank register
  output reg                        rank_we,          // rank write enable
  output reg  [`RankBus]            rank_waddr,       // rank write address
  output reg  [`PeDataBus]          rank_wdata,       // rank write data
  output reg                        rank_re,          // rank read enable
  output reg  [`RankBus]            rank_raddr,       // rank read address
  input wire  [`PeDataBus]          rank_rdata,       // rank read data

  // interfaces of RootRank state register
  output reg                        state_we,         // state write enable
  output reg  [1:0]                 state_waddr,      // state write address
  output reg  [2*`RANK_WIDTH-1:0]   state_wdata,      // state write data
  input wire                        uv_en,            // UV enable
  input wire  [`RANK_WIDTH-1:0]     rank_no           // UV rank number
);

// ----------------------------------------
// Unpack the input data from the router
// ----------------------------------------
// Hardcode the field index
wire [`ROUTER_INFO_WIDTH-1:0] in_data_route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] in_data_route_addr = in_data[31:16];
wire [`ROUTER_DATA_WIDTH-1:0] in_data_route_data = in_data[15:0];

// ------------------------------------------
// Finite state machine registers
// ------------------------------------------
localparam  STATE_IDLE        = 1'b0,                 // idle state
            STATE_TRAN        = 1'b1;                 // transmit state
reg state_reg, state_next;
// registers holding the number rx packet & tx packet
reg [`RankBus] rx_v_cnt_reg, rx_v_cnt_next;
reg [`RankBus] tx_v_idx_reg, tx_v_idx_next;

// ---------------------------------------------------
// Extra pipeline stage of the bias calculation of V
// ---------------------------------------------------
reg [`PeDataBus] rx_rank_data;
reg [`RankBus] rx_rank_addr;
// register holding the offset of the bias memory
reg [`RankBiasMemAddrBus] bias_offset;

// ---------------------------------------------------
// Receiving the calculated rank results (w/o bias)
// ---------------------------------------------------
// Bias memory offset
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    bias_offset               <= 0;
  end else if (clear_bias_offset) begin
    bias_offset               <= 0;
  end else if (update_bias_offset) begin
    bias_offset               <= bias_offset + rank_no;
  end
end
// Bias memory access
always @ (*) begin
  if (in_data_valid && in_data_route_info == `ROUTER_INFO_UV) begin
    rank_bias_mem_cen         = 1'b0;
    rank_bias_mem_wen         = 1'b1;
    rank_bias_mem_addr        = bias_offset + in_data_route_addr[`RankBus];
  end else begin
    rank_bias_mem_cen         = 1'b1;
    rank_bias_mem_wen         = 1'b1;
    rank_bias_mem_addr        = 0;
  end
end
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    rank_bias_mem_oe          <= 1'b1;
  end else begin
    rank_bias_mem_oe          <= rank_bias_mem_cen;
  end
end
// Register the receiving rank data (w/o bias) & the associated address
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    rx_rank_addr              <= 0;
    rx_rank_data              <= 0;
  end else if (in_data_valid && in_data_route_info == `ROUTER_INFO_UV) begin
    rx_rank_addr              <= in_data_route_addr[`RankBus];
    rx_rank_data              <= in_data_route_data;
  end
end
// Adding the results of the bias data & receiving rank data
// and write the results into the register bank
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    rank_we                   <= 1'b0;
    rank_waddr                <= 0;
    rank_wdata                <= 0;
  end else if (rank_bias_mem_oe == 1'b0) begin
    rank_we                   <= 1'b1;
    rank_waddr                <= rx_rank_addr;
    rank_wdata                <= rx_rank_data + rank_bias_mem_q;
  end else begin
    rank_we                   <= 1'b0;
    rank_waddr                <= 0;
    rank_wdata                <= 0;
  end
end

// -------------------------------------------
// Write operation of the rank state register
// Hardcode the field index location
// -------------------------------------------
always @ (*) begin
  if (write_en && write_rdy && write_addr == 38) begin
    state_we                  = 1'b1;
    state_waddr               = 2'b00;
    state_wdata               = {write_data[13:8], write_data[5:0]};
  end
  else if (write_en && write_rdy && write_addr == 40) begin
    state_we                  = 1'b1;
    state_waddr               = 2'b01;
    state_wdata               = {write_data[13:8], write_data[5:0]};
  end
  else if (write_en && write_rdy && write_addr == 42) begin
    state_we                  = 1'b1;
    state_waddr               = 2'b10;
    state_wdata               = {write_data[13:8], write_data[5:0]};
  end
  else if (write_en && write_rdy && write_addr == 68) begin
    state_we                  = 1'b1;
    state_waddr               = 2'b11;
    state_wdata               = write_data[2*`RANK_WIDTH-1:0];
  end
  else begin
    state_we                  = 1'b0;
    state_waddr               = 0;
    state_wdata               = 0;
  end
end

// -------------------------------------------
// Finite state machine definition
// -------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg                 <= STATE_IDLE;
    rx_v_cnt_reg              <= 0;
    tx_v_idx_reg              <= 0;
  end else begin
    state_reg                 <= state_next;
    rx_v_cnt_reg              <= rx_v_cnt_next;
    tx_v_idx_reg              <= tx_v_idx_next;
  end
end
// Next-state logic
always @ (*) begin
  // holding the original values by default
  state_next                  = state_reg;
  rx_v_cnt_next               = rx_v_cnt_reg;
  tx_v_idx_next               = tx_v_idx_reg;
  // disable the read or write path by default
  rank_re                     = 1'b0;
  rank_raddr                  = 0;
  rank_tx_en                  = 1'b0;
  rank_tx_data                = 0;

  case (state_reg)
    STATE_IDLE: begin
      if (uv_en && in_data_valid && in_data_route_info == `ROUTER_INFO_UV) begin
        // if the current layer needs V computation, go to transfer state
        // and receive the UV packets
        state_next            = STATE_TRAN;
        rx_v_cnt_next         = 0;
        tx_v_idx_next         = 0;
      end
    end

    STATE_TRAN: begin
      // update the rx V counter
      if (rank_we) begin
        rx_v_cnt_next         = rx_v_cnt_reg + 1;
      end

      // update the tx index & transfer the packet
      if (tx_v_idx_reg < rx_v_cnt_reg && router_rdy) begin
        tx_v_idx_next         = tx_v_idx_reg + 1;
        rank_re               = 1'b1;
        rank_raddr            = tx_v_idx_reg;
        rank_tx_en            = 1'b1;
        // hardcode the data to be tranmitted
        rank_tx_data[35:32]   = `ROUTER_INFO_UV;
        rank_tx_data[31:16]   = {{(`ROUTER_ADDR_WIDTH-`RANK_WIDTH){1'b0}},
                                  tx_v_idx_reg};
        rank_tx_data[15:0]    = rank_rdata;
      end

      // state transfer
      if (tx_v_idx_next == rank_no) begin
        // all the V results have be transmitted, go to idle
        state_next            = STATE_IDLE;
        rx_v_cnt_next         = 0;
        tx_v_idx_next         = 0;
      end
    end
  endcase
end

// -------------------------------
// Display log info
// -------------------------------
// synopsys translate_off
always @ (posedge clk) begin
  if (rank_re) begin
    $display("@%t Root Rank sends the rank[%d] = %d", $time, rank_raddr,
      $signed(rank_rdata));
  end
end
// synopsys translate_on

endmodule
