// =============================================================================
// Module name: InputUnit
//
// Input unit of the router. It contains the FIFO of one channel. The FIFO will
// hold arriving flits until they can be forwarded.
// =============================================================================

`include "router.vh"

module InputUnit (
  input wire                      clk,            // system clock
  input wire                      rst,            // system reset (active high)
  // input data of one channel from upstreaming router
  input wire                      in_data_valid,  // input data valid
  input wire  [`ROUTER_WIDTH-1:0] in_data,        // input data

  // credit-based flow control
  input wire  [`DIRECTION-1:0]    out_credit_avail, // downstreaming credit
  output wire                     in_credit,      // upstreaming credit update
  output wire [`DIRECTION-1:0]    out_credit_decre, // downstreaming credit decrement

  // routing computation (RC) interface
  output wire                     rc_en,          // RC enable
  output wire [`ROUTER_INFO_WIDTH-1:0]
                                  route_info,     // routing info
  output wire [`ROUTER_ADDR_WIDTH-1:0]
                                  route_addr,     // routing address
  input wire  [`DIRECTION-1:0]    route_port,     // routing results

  // switch arbiter
  output wire                     sa_request,     // SA request
  output wire [`ROUTER_ADDR_WIDTH-1:0]
                                  sa_addr,        // SA address
  input wire                      sa_grant,       // SA grant

  // switch traversal
  output wire [`ROUTER_WIDTH-1:0] st_data_in,     // ST data input
  output wire [`DIRECTION-1:0]    st_ctrl_in      // ST control input
);

// interconnections
wire fifo_read_en;
wire [`ROUTER_WIDTH-1:0] fifo_read_data;
wire fifo_empty, fifo_full;
wire fifo_empty_next, fifo_full_next;

// ---------------------------------------
// Input FIFO: holding the arriving flits
// ---------------------------------------
fifo_sync # (
  .BIT_WIDTH        (`ROUTER_WIDTH),              // bit width
  .FIFO_DEPTH       (`ROUTER_FIFO_DEPTH)          // fifo depth (power of 2)
) input_fifo (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset

  // read interface
  .read_en          (fifo_read_en),               // read enable
  .read_data        (fifo_read_data),             // read data
  // write interface
  .write_en         (in_data_valid),              // write enable
  .write_data       (in_data),                    // write data

  // status indicator of FIFO
  .fifo_empty       (fifo_empty),                 // fifo is empty
  .fifo_full        (fifo_full),                  // fifo is full
  // next logic of fifo status flag
  .fifo_empty_next  (fifo_empty_next),
  .fifo_full_next   (fifo_full_next)
);

// ----------------------------------------
// Input unit controller & state registers
// ----------------------------------------
InputUnitController input_unit_controller (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset (active high)
  .in_data_valid    (in_data_valid),              // input data valid
  .fifo_empty       (fifo_empty),                 // channel buffer empty
  .fifo_empty_next  (fifo_empty_next),            // channel buffer empty
  .fifo_data        (fifo_read_data),             // channel buffer data
  .fifo_read_en     (fifo_read_en),               // fifo read enable

  // credit-based flow control
  .out_credit_avail (out_credit_avail),           // downstreaming port credit
  .in_credit        (in_credit),                  // notifying upstreaming node
  .out_credit_decre (out_credit_decre),           // downstreaming credit decrement

  // routing computation interface
  .rc_en            (rc_en),                      // rc enable
  .route_info       (route_info),                 // routing info
  .route_addr       (route_addr),                 // routing address
  .route_port       (route_port),                 // routing results

  // switch arbiter
  .sa_request       (sa_request),                 // SA request
  .sa_addr          (sa_addr),                    // SA address
  .sa_grant         (sa_grant),                   // SA grant

  // switch traversal
  .st_data_in       (st_data_in),                 // ST data input
  .st_ctrl_in       (st_ctrl_in)                  // ST control input
);

endmodule
