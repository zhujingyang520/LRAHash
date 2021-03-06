// =============================================================================
// Module name: RootRank
//
// This file exports the rank module in the Root Node
// =============================================================================

`include "pe.vh"
`include "global.vh"
`include "router.vh"

module RootRank (
  input wire                        clk,              // system clock
  input wire                        rst,              // system reset

  // interface of the root node
  input wire                        router_rdy,       // router ready
  input wire  [`PeLayerNoBus]       layer_idx,        // layer index
  output wire                       rank_tx_en,       // rank transmit enable
  output wire [`ROUTER_WIDTH-1:0]   rank_tx_data,     // rank transmit data
  input wire                        clear_bias_offset,// clear offset
  input wire                        update_bias_offset, // update offset

  // input data port (LOCAL) from the quadtree router
  input wire                        in_data_valid,    // input data valid
  input wire  [`ROUTER_WIDTH-1:0]   in_data,          // input data

  // interface of the write operation
  input wire                        write_en,         // write enable
  input wire                        write_rdy,        // write ready
  input wire  [`DataBus]            write_data,       // write data
  input wire  [`AddrBus]            write_addr        // write address
);

// -------------------------------------------
// Interconnections
// -------------------------------------------
// rank no. registers
wire rank_we;
wire [`RankBus] rank_waddr;
wire [`PeDataBus] rank_wdata;
wire rank_re;
wire [`RankBus] rank_raddr;
wire [`PeDataBus] rank_rdata;
// rank state registers
wire state_we;
wire [1:0] state_waddr;
wire [2*`RANK_WIDTH-1:0] state_wdata;
wire uv_en;
wire [`RANK_WIDTH-1:0] rank_no;
// rank bias memory interface
wire rank_bias_mem_wen;
wire rank_bias_mem_cen;
wire rank_bias_mem_oe;
wire [`RankBiasMemAddrBus] rank_bias_mem_addr;
wire [`RankBiasMemDataBus] rank_bias_mem_q;

// -------------------------------------------
// Root Rank Controller
// -------------------------------------------
RootRankController root_rank_controller (
  .clk                  (clk),                        // system clock
  .rst                  (rst),                        // system reset

  // interface of the root controller
  .router_rdy           (router_rdy),                 // router ready
  .rank_tx_en           (rank_tx_en),                 // rank transmit enable
  .rank_tx_data         (rank_tx_data),               // rank transmit data
  .clear_bias_offset    (clear_bias_offset),          // clear offset
  .update_bias_offset   (update_bias_offset),         // update offset

  // input data port from the router
  .in_data_valid        (in_data_valid),              // input data valid
  .in_data              (in_data),                    // input data

  // input data port of the write operation (primary output)
  .write_en             (write_en),                   // write enable
  .write_rdy            (write_rdy),                  // write ready
  .write_data           (write_data),                 // write data
  .write_addr           (write_addr),                 // write address

  // interfaces of the RootRank bias memory
  .rank_bias_mem_wen    (rank_bias_mem_wen),          // write enable
  .rank_bias_mem_cen    (rank_bias_mem_cen),          // chip enable
  .rank_bias_mem_oe     (rank_bias_mem_oe),           // output enable
  .rank_bias_mem_addr   (rank_bias_mem_addr),         // address
  .rank_bias_mem_q      (rank_bias_mem_q),            // read data

  // interfaces of RootRank register
  .rank_we              (rank_we),                    // rank write enable
  .rank_waddr           (rank_waddr),                 // rank write address
  .rank_wdata           (rank_wdata),                 // rank write data
  .rank_re              (rank_re),                    // rank read enable
  .rank_raddr           (rank_raddr),                 // rank read address
  .rank_rdata           (rank_rdata),                 // rank read data

  // interfaces of RootRank state register
  .state_we             (state_we),                   // state write enable
  .state_waddr          (state_waddr),                // state write address
  .state_wdata          (state_wdata),                // state write data
  .uv_en                (uv_en),                      // UV enable
  .rank_no              (rank_no)                     // UV rank number
);

// ---------------------------------
// Root Rank state register
// ---------------------------------
RootRankState root_rank_state (
  .clk                  (clk),                        // system clock
  .rst                  (rst),                        // system reset
  // write operation (configuration, 2 data in parallel)
  .state_we             (state_we),                   // state write enable
  .state_waddr          (state_waddr),                // state write address
  .state_wdata          (state_wdata),                // state write data

  // read operation
  .layer_idx            (layer_idx),                  // state read address
  .rank_no              (rank_no),                    // rank number
  .uv_en                (uv_en)                       // UV bypass enable
);

// ---------------------------------
// Root Rank register
// ---------------------------------
RootRankReg root_rank_reg (
  .clk                  (clk),                        // system clock
  .rst                  (rst),                        // system reset
  .rank_we              (rank_we),                    // rank write enable
  .rank_waddr           (rank_waddr),                 // rank write address
  .rank_wdata           (rank_wdata),                 // rank write data

  .rank_re              (rank_re),                    // rank read enable
  .rank_raddr           (rank_raddr),                 // rank read address
  .rank_rdata           (rank_rdata)                  // rank read data
);

// ---------------------------------
// Root Rank bias memory (2kb)
// ---------------------------------
SRAM_16x128_1P rank_bias_mem (
  .CE1                  (clk),                        // system clock
  .WEB1                 (rank_bias_mem_wen),          // write enable
  .CSB1                 (rank_bias_mem_cen),          // chip enable
  .OEB1                 (rank_bias_mem_oe),           // output enable
  .A1                   (rank_bias_mem_addr),         // read/write address
  .I1                   ({`RANK_BIAS_MEM_DATA_WIDTH{1'b0}}),
  .O1                   (rank_bias_mem_q)             // data output (read op)
);

endmodule
