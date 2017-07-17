// =============================================================================
// Module name: InternalNode
//
// It is the second level of node in the broadcasting network.
// =============================================================================

`include "router.vh"

module InternalNode (
  input wire                    clk,            // system clock
  input wire                    rst,            // system reset (active high)

  // data path
  input wire  [`DIRECTION-1:0]  in_data_valid,  // input data valid
  input wire  [`DIRECTION*`ROUTER_WIDTH-1:0]
                                in_data,        // input data
  output wire [`DIRECTION-1:0]  out_data_valid, // output data valid
  output wire [`DIRECTION*`ROUTER_WIDTH-1:0]
                                out_data,       // output data

  // credit path
  input wire  [`DIRECTION-1:0]  downstream_credit,  // credit from downstream
  output wire [`DIRECTION-1:0]  upstream_credit     // credit to upstream
);

// ----------------
// Internal router
// ----------------
QuadtreeRouter #(
  .level            (`LEVEL_INTERNAL)             // router level
) internal_router (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset (active high)
  // input data path
  .in_data_valid    (in_data_valid),              // input data valid
  .in_data          (in_data),                    // input data
  .in_credit        (upstream_credit),            // upstreaming output credit

  .out_data_valid   (out_data_valid),             // output data valid
  .out_data         (out_data),                   // output data
  .out_credit       (downstream_credit)           // dowstreaming input credit
);

endmodule
