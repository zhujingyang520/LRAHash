// =============================================================================
// Module name: QuadtreeRouter
//
// This module implements the quadtree router which support the data
// broadcasting between {NW, NE, SE, SW} & LOCAL.
//
// The router is accept a single flit packet with credit-based flow control.
// There is no virtual channel in the router.
// =============================================================================

`include "router.vh"

module QuadtreeRouter #(
  parameter   level             = `LEVEL_ROOT     // router level
) (
  input wire                    clk,              // system clock
  input wire                    rst,              // system reset (active high)
  // input data path
  input wire  [`DIRECTION-1:0]  in_data_valid,    // input data valid
  input wire  [`DIRECTION*`ROUTER_WIDTH-1:0]
                                in_data,          // input data
  output wire [`DIRECTION-1:0]  in_credit,        // upstreaming output credit

  output wire [`DIRECTION-1:0]  out_data_valid,   // output data valid
  output wire [`DIRECTION*`ROUTER_WIDTH-1:0]
                                out_data,         // output data
  input wire  [`DIRECTION-1:0]  out_credit        // dowstreaming input credit
);

genvar g;

// ------------------
// Interconnections
// ------------------
wire [`DIRECTION-1:0] out_credit_avail;
wire [`DIRECTION-1:0] out_credit_decre [`DIRECTION-1:0];
wire [`DIRECTION-1:0] credit_decre;
// RC
wire [`DIRECTION-1:0] rc_en;
wire [`ROUTER_INFO_WIDTH-1:0] route_info [`DIRECTION-1:0];
wire [`ROUTER_ADDR_WIDTH-1:0] route_addr [`DIRECTION-1:0];
wire [`DIRECTION-1:0] route_port [`DIRECTION-1:0];
// SA
wire [`DIRECTION-1:0] sa_request;
wire [`DIRECTION*`ROUTER_INFO_WIDTH-1:0] sa_info;
wire [`DIRECTION*`ROUTER_ADDR_WIDTH-1:0] sa_addr;
wire [`DIRECTION-1:0] sa_grant;
// ST
wire [`DIRECTION*`ROUTER_WIDTH-1:0] st_data_in;
wire [`DIRECTION*`DIRECTION-1:0] st_ctrl_in;
// Output unit
wire [`DIRECTION-1:0] out_unit_en;
wire [`DIRECTION*`ROUTER_WIDTH-1:0] st_data_out;

// ------------
// Input unit
// ------------
generate
for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_input_unit
InputUnit input_unit (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset (active high)
  // input data of one channel from upstreaming router
  .in_data_valid    (in_data_valid[g]),           // input data valid
  .in_data          (in_data[g*`ROUTER_WIDTH+:`ROUTER_WIDTH]),

  // credit-based flow control
  .out_credit_avail (out_credit_avail),           // downstreaming credit
  .in_credit        (in_credit[g]),               // upstreaming credit update
  .out_credit_decre (out_credit_decre[g]),        // downstreaming credit decrement

  // routing computation (RC) interface
  .rc_en            (rc_en[g]),                   // RC enable
  .route_info       (route_info[g]),              // routing info
  .route_addr       (route_addr[g]),              // routing address
  .route_port       (route_port[g]),              // routing results

  // switch arbiter
  .sa_request       (sa_request[g]),              // SA request
  .sa_info          (sa_info[g*`ROUTER_INFO_WIDTH +: `ROUTER_INFO_WIDTH]),
  .sa_addr          (sa_addr[g*`ROUTER_ADDR_WIDTH +: `ROUTER_ADDR_WIDTH]),
  .sa_grant         (sa_grant[g]),                // SA grant

  // switch traversal
  .st_data_in       (st_data_in[`ROUTER_WIDTH*g +: `ROUTER_WIDTH]),
  .st_ctrl_in       (st_ctrl_in[`DIRECTION*g +: `DIRECTION])
);
end
endgenerate

// -------------------------
// Routing computation (RC)
// -------------------------
generate
for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_rc
RoutingComputer #(
  .level            (level)                       // level of the router
) rc (
  .direction        (g[2:0]),                     // input direction
  .rc_en            (rc_en[g]),                   // routing enable
  .route_info       (route_info[g]),              // routing info
  .route_addr       (route_addr[g]),              // routing address

  .route_port       (route_port[g])               // direction to be routed
);

end
endgenerate

// -----------------------
// Switch allocator (SA)
// -----------------------
SwitchAllocator sa (
  .sa_request       (sa_request),                 // SA request
  .sa_info          (sa_info),                    // SA info
  .sa_addr          (sa_addr),                    // SA address
  .sa_grant         (sa_grant)                    // SA grant
);

// -----------
// Switch
// -----------
Switch switch (
  .st_data_in       (st_data_in),                 // switch input data
  .st_ctrl_in       (st_ctrl_in),                 // switch control

  .out_unit_en      (out_unit_en),                // output unit enable
  .st_data_out      (st_data_out)                 // switch output
);

// --------------
// Output unit
// --------------
// Credit decrements: aggregate all the 5 ports results using OR
assign credit_decre = out_credit_decre[`DIR_NW] | out_credit_decre[`DIR_NE] |
                      out_credit_decre[`DIR_SE] | out_credit_decre[`DIR_SW] |
                      out_credit_decre[`DIR_LOCAL];
generate
for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_output_unit
OutputUnit #(
  .level            (level),                      // router level
  .direction        (g)                           // output unit's direction
) output_unit (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset (active high)

  // credit datapath
  .credit_decre     (credit_decre[g]),            // decrement credit
  .credit_incre     (out_credit[g]),              // increment credit
  .credit_avail     (out_credit_avail[g]),        // credit available (> 0)

  // data path
  .out_unit_en      (out_unit_en[g]),             // output unit update enable
  .st_data_out      (st_data_out[g*`ROUTER_WIDTH +: `ROUTER_WIDTH]),
  .out_data         (out_data[g*`ROUTER_WIDTH +: `ROUTER_WIDTH]),
  .out_data_valid   (out_data_valid[g])           // output unit data valid
);
end
endgenerate

endmodule
