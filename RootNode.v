// =============================================================================
// Module name: RootNode
//
// The module is the root node @ accelerator
// =============================================================================

`include "global.vh"
`include "router.vh"

module RootNode (
  input wire                      clk,            // system clock
  input wire                      rst,            // system reset (active high)

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
  output wire [`DataBus]          read_data,      // read data

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

// interconnections of the local port of router
wire in_data_valid_local;
wire [`ROUTER_WIDTH-1:0] in_data_local;
wire out_data_valid_local;
wire [`ROUTER_WIDTH-1:0] out_data_local;
wire downstream_credit_local;
wire upstream_credit_local;

// -------------------
// Root controller
// -------------------
RootController root_controller (
  .clk                (clk),                      // system clock
  .rst                (rst),                      // system reset (active high)

  // interfaces of write operation
  .write_en           (write_en),                 // write enable (active high)
  .write_data         (write_data),               // write data
  .write_addr         (write_addr),               // write address
  .write_rdy          (write_rdy),                // write ready

  // interfaces of LOCAL port of quadtree router
  .in_data_valid      (in_data_valid_local),      // input data valid
  .in_data            (in_data_local),            // input data
  .out_data_valid     (out_data_valid_local),     // output data valid
  .out_data           (out_data_local),           // output data
  .downstream_credit  (downstream_credit_local),  // downstream credit
  .upstream_credit    (upstream_credit_local)     // upstream credit
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
