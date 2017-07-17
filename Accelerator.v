// =============================================================================
// Module name: Accelerator
//
// The top module of LRAHash accelerator.
// =============================================================================

`include "global.vh"
`include "router.vh"

module Accelerator (
  input wire                      clk,          // system clock
  input wire                      rst,          // system reset (active high)

  // interface of write operation (configuration)
  input wire                      write_en,     // write enable (active high)
  output wire                     write_rdy,    // write ready (active high)
  input wire  [`AddrBus]          write_addr,   // write address
  input wire  [`DataBus]          write_data,   // write data

  // interface of read operation (read data from accelerator)
  input wire                      read_en,      // read enable (active high)
  output wire                     read_rdy,     // read ready (active high)
  input wire  [`AddrBus]          read_addr,    // read address
  input wire                      read_data_rdy,// read data ready (active high)
  output wire                     read_data_vld,// read data valid (active high)
  output wire [`DataBus]          read_data     // read data
);

genvar g;

// ---------------------------------------------------
// Interconnections for 64 PEs and quadtree routers
// ---------------------------------------------------
// Root node interconnections
wire [`DIRECTION-2:0] root_node_in_data_valid;
wire [(`DIRECTION-1)*`ROUTER_WIDTH-1:0] root_node_in_data;
wire [`DIRECTION-2:0] root_node_out_data_valid;
wire [(`DIRECTION-1)*`ROUTER_WIDTH-1:0] root_node_out_data;
wire [`DIRECTION-2:0] root_node_downstream_credit;
wire [`DIRECTION-2:0] root_node_upstream_credit;
// Internal node interconnections
wire [`DIRECTION-2:0] internal_node_in_data_valid [3:0];
wire [(`DIRECTION-1)*`ROUTER_WIDTH-1:0] internal_node_in_data [3:0];
wire [`DIRECTION-2:0] internal_node_out_data_valid [3:0];
wire [(`DIRECTION-1)*`ROUTER_WIDTH-1:0] internal_node_out_data [3:0];
wire [`DIRECTION-2:0] internal_node_downstream_credit [3:0];
wire [`DIRECTION-2:0] internal_node_upstream_credit [3:0];
// Leaf node interconnections
wire [`DIRECTION-2:0] leaf_node_in_data_valid [15:0];
wire [(`DIRECTION-1)*`ROUTER_WIDTH-1:0] leaf_node_in_data [15:0];
wire [`DIRECTION-2:0] leaf_node_out_data_valid [15:0];
wire [(`DIRECTION-1)*`ROUTER_WIDTH-1:0] leaf_node_out_data [15:0];
wire [`DIRECTION-2:0] leaf_node_downstream_credit [15:0];
wire [`DIRECTION-2:0] leaf_node_upstream_credit [15:0];

// ---------------------------------
// Quadtree broadcast network
// ---------------------------------
// 1 root node
RootNode root_node (
  .clk                    (clk),            // system clock
  .rst                    (rst),            // system reset (active high)

  // interface of the write operation
  .write_en               (write_en),       // write enable (active high)
  .write_data             (write_data),     // write data,
  .write_addr             (write_addr),     // write address
  .write_rdy              (write_rdy),      // write ready

  // interface of the read operation
  .read_en                (read_en),        // read enable (active high)
  .read_rdy               (read_rdy),       // read ready (active high)
  .read_addr              (read_addr),      // read address
  .read_data_rdy          (read_data_rdy),  // read data ready
  .read_data_vld          (read_data_vld),  // read data valid
  .read_data              (read_data),      // read data

  // 4 childed directions {NW, NE, SE, SW}
  // data path
  .in_data_valid          (root_node_in_data_valid),
  .in_data                (root_node_in_data),
  .out_data_valid         (root_node_out_data_valid),
  .out_data               (root_node_out_data),
  // credit path (backpressure)
  .downstream_credit      (root_node_downstream_credit),
  .upstream_credit        (root_node_upstream_credit)
);
// 4 internal nodes
generate
for (g = 0; g < 4; g = g + 1) begin: gen_internal_node
InternalNode internal_node (
  .clk                    (clk),            // system clock
  .rst                    (rst),            // system reset (active high)

  // data path
  .in_data_valid          ({root_node_out_data_valid[g],
                            internal_node_in_data_valid[g]}),
  .in_data                ({root_node_out_data[g*`ROUTER_WIDTH+:`ROUTER_WIDTH],
                            internal_node_in_data[g]}),
  .out_data_valid         ({root_node_in_data_valid[g],
                            internal_node_out_data_valid[g]}),
  .out_data               ({root_node_in_data[g*`ROUTER_WIDTH+:`ROUTER_WIDTH],
                            internal_node_out_data[g]}),

  // credit path
  .downstream_credit      ({root_node_upstream_credit[g],
                            internal_node_downstream_credit[g]}),
  .upstream_credit        ({root_node_downstream_credit[g],
                            internal_node_upstream_credit[g]})
);
end
endgenerate
// 16 leaf nodes
generate
for (g = 0; g < 16; g = g + 1) begin: gen_leaf_node
LeafNode leaf_node (
  .clk                    (clk),            // system clock
  .rst                    (rst),            // system reset (active high)

  // data path
  .in_data_valid          ({internal_node_out_data_valid[g/4][g%4],
                            leaf_node_in_data_valid[g]}),
  .in_data                ({internal_node_out_data[g/4][(g%4)*`ROUTER_WIDTH
                              +:`ROUTER_WIDTH],
                            leaf_node_in_data[g]}),
  .out_data_valid         ({internal_node_in_data_valid[g/4][g%4],
                            leaf_node_out_data_valid[g]}),
  .out_data               ({internal_node_in_data[g/4][(g%4)*`ROUTER_WIDTH
                              +:`ROUTER_WIDTH],
                            leaf_node_out_data[g]}),

  // credit path
  .downstream_credit      ({internal_node_upstream_credit[g/4][g%4],
                            leaf_node_downstream_credit[g]}),
  .upstream_credit        ({internal_node_downstream_credit[g/4][g%4],
                            leaf_node_upstream_credit[g]})
);
end
endgenerate

// ---------------------------------
// 64 Processing Elements
// ---------------------------------
generate
for (g = 0; g < 64; g = g + 1) begin: gen_processing_element
ProcessingElement #(
  .PE_IDX                 (g)               // PE index
) processing_element (
  .clk                    (clk),            // system clock
  .rst                    (rst),            // syetem reset (active high)

  // data path from/to router
  .in_data_valid          (leaf_node_out_data_valid[g/4][g%4]),
  .in_data                (leaf_node_out_data[g/4][(g%4)*`ROUTER_WIDTH
                              +:`ROUTER_WIDTH]),
  .out_data_valid         (leaf_node_in_data_valid[g/4][g%4]),
  .out_data               (leaf_node_in_data[g/4][(g%4)*`ROUTER_WIDTH
                              +:`ROUTER_WIDTH]),       // output data

  // credit path from/to router
  .downstream_credit      (leaf_node_upstream_credit[g/4][g%4]),
  .upstream_credit        (leaf_node_downstream_credit[g/4][g%4])
);
end
endgenerate

endmodule
