// =============================================================================
// Module name: RootNode
//
// The module is the root node @ accelerator
// =============================================================================

`include "global.vh"
`include "pe.vh"
`include "router.vh"

module RootNode (
  input wire                      clk,            // system clock
  input wire                      rst,            // system reset (active high)

  output wire                     interrupt,      // interrupt

  // interface of the write operation
  input wire                      write_en,       // write enable (active high)
  input wire  [`DataBus]          write_data,     // write data,
  input wire  [`AddrBus]          write_addr,     // write address
  output wire                     write_rdy,      // write ready

  // interface of the read operation
  input wire                      read_en,        // read enable (active high)
  output wire                     read_rdy,       // read ready (active high)
  input wire  [`AddrBus]          read_addr,      // read address
  input wire                      read_data_rdy,  // read data ready
  output wire                     read_data_vld,  // read data valid
  output wire [`ReadDataBus]      read_data,      // read data

  // 4 childed directions {NW, NE, SE, SW}
  // data path
  input wire  [`DIRECTION-2:0]    in_data_valid,  // input data valid
  input wire  [(`DIRECTION-1)*`ROUTER_WIDTH-1:0]
                                  in_data,        // input data
  output wire [`DIRECTION-2:0]    out_data_valid, // output data valid
  output wire [(`DIRECTION-1)*`ROUTER_WIDTH-1:0]
                                  out_data,       // output data
  // credit path (backpressure)
  input wire  [`DIRECTION-2:0]    downstream_credit,  // credit from downstream
  output wire [`DIRECTION-2:0]    upstream_credit // credit to upstream
);

// ---------------------------------------------
// Interconnections of the local port of router
// ---------------------------------------------
wire in_data_valid_local;
wire [`ROUTER_WIDTH-1:0] in_data_local;
wire out_data_valid_local;
wire [`ROUTER_WIDTH-1:0] out_data_local;
wire downstream_credit_local;
wire upstream_credit_local;
// ---------------------------------------------
// Interconnections of the root controller
// ---------------------------------------------
wire router_rdy;
wire comp_tx_en;
wire [`ROUTER_WIDTH-1:0] comp_tx_data;
wire rank_tx_en;
wire [`ROUTER_WIDTH-1:0] rank_tx_data;
wire [`PeLayerNoBus] layer_idx;

/*
// -------------------
// Root controller
// -------------------
RootController root_controller (
  .clk                (clk),                      // system clock
  .rst                (rst),                      // system reset (active high)

  .interrupt          (interrupt),                // interrupt for done

  // interfaces of write operation
  .write_en           (write_en),                 // write enable (active high)
  .write_data         (write_data),               // write data
  .write_addr         (write_addr),               // write address
  .write_rdy          (write_rdy),                // write ready

  // interfaces of read operation
  .read_en            (read_en),                  // read enable (active high)
  .read_rdy           (read_rdy),                 // read ready (active high)
  .read_addr          (read_addr),                // read address
  .read_data_rdy      (read_data_rdy),            // read data ready
  .read_data_vld      (read_data_vld),            // read data valid
  .read_data          (read_data),                // read data bus

  // interfaces of LOCAL port of quadtree router
  .in_data_valid      (in_data_valid_local),      // input data valid
  .in_data            (in_data_local),            // input data
  .out_data_valid     (out_data_valid_local),     // output data valid
  .out_data           (out_data_local),           // output data
  .downstream_credit  (downstream_credit_local),  // downstream credit
  .upstream_credit    (upstream_credit_local)     // upstream credit
);*/

// --------------------------------
// Root computation FSM controller
// --------------------------------
RootCompController root_comp_controller (
  .clk                (clk),                      // system clock
  .rst                (rst),                      // system reset

  // primary interfaces
  .interrupt          (interrupt),                // interrupt
  // write request handshake
  .write_en           (write_en),                 // write enable
  .write_data         (write_data),               // write data
  .write_addr         (write_addr),               // write address
  .write_rdy          (write_rdy),                // write ready
  // read request handshake
  .read_en            (read_en),                  // read enable
  .read_rdy           (read_rdy),                 // read ready
  .read_addr          (read_addr),                // read address

  // interfaces of the LOCAL port of the quadtree router
  .in_data_valid      (in_data_valid_local),      // input data valid
  .in_data            (in_data_local),            // input data

  // interfaces of root node
  .router_rdy         (router_rdy),               // router ready
  .layer_idx          (layer_idx),                // layer index
  .comp_tx_en         (comp_tx_en),               // comp tx enable
  .comp_tx_data       (comp_tx_data)              // comp tx data
);

// --------------------------------
// Root rank controller
// --------------------------------
RootRank root_rank (
  .clk                (clk),                      // system clock
  .rst                (rst),                      // system reset

  // interface of the root node
  .router_rdy         (router_rdy),               // router ready
  .layer_idx          (layer_idx),                // layer index
  .rank_tx_en         (rank_tx_en),               // rank transmit enable
  .rank_tx_data       (rank_tx_data),             // rank transmit data

  // input data port (LOCAL) from the quadtree router
  .in_data_valid      (in_data_valid_local),      // input data valid
  .in_data            (in_data_local),            // input data

  // interface of the write operation
  .write_en           (write_en),                 // write enable
  .write_rdy          (write_rdy),                // write ready
  .write_data         (write_data),               // write data
  .write_addr         (write_addr)                // write address
);

// ------------------------------
// Root output unit
// ------------------------------
RootOutputUnit root_output_unit (
  .clk                (clk),                      // system clock
  .rst                (rst),                      // system reset
  .router_rdy         (router_rdy),               // router ready

  // primary read handshake
  .read_data_rdy      (read_data_rdy),            // read data ready
  .read_data_vld      (read_data_vld),            // read data valid
  .read_data          (read_data),                // read data

  // interfaces of RootCompController
  .comp_tx_en         (comp_tx_en),               // comp tx enable
  .comp_tx_data       (comp_tx_data),             // comp tx data

  // interfaces of RootRankController
  .rank_tx_en         (rank_tx_en),               // rank tx enable
  .rank_tx_data       (rank_tx_data),             // rank tx data

  // interfaces of the LOCAL port of Root Quadtree router
  // credit interface
  .downstream_credit  (downstream_credit_local),  // dowstream credit
  .upstream_credit    (upstream_credit_local),    // upstream credit
  // data interface
  .in_data_valid      (in_data_valid_local),      // input data valid
  .in_data            (in_data_local),            // input data
  .out_data_valid     (out_data_valid_local),     // output data valid
  .out_data           (out_data_local)            // output data
);

// ---------------------
// Root quadtree router
// ---------------------
QuadtreeRouter #(
  .level              (`LEVEL_ROOT)               // router level
) root_quadtree_router (
  .clk                (clk),                      // system clock
  .rst                (rst),                      // system reset (active high)
  // input data path
  .in_data_valid      ({out_data_valid_local, in_data_valid}),
  .in_data            ({out_data_local, in_data}), // input data
  .in_credit          ({downstream_credit_local, upstream_credit}),

  .out_data_valid     ({in_data_valid_local, out_data_valid}),
  .out_data           ({in_data_local, out_data}),
  .out_credit         ({upstream_credit_local, downstream_credit})
);

endmodule
