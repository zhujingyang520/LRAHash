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
  output wire [`ROUTER_INFO_WIDTH-1:0]
                                  sa_info,        // SA info
  output wire [`ROUTER_ADDR_WIDTH-1:0]
                                  sa_addr,        // SA address
  input wire                      sa_grant,       // SA grant

  // switch traversal
  output wire [`ROUTER_WIDTH-1:0] st_data_in,     // ST data input
  output wire [`DIRECTION-1:0]    st_ctrl_in      // ST control input
);

genvar g;

// ----------------------------------------
// interconnections
// ----------------------------------------
// Credit
wire [`ROUTER_FIFO_SPLIT-1:0] in_credit_split;
wire [`ROUTER_FIFO_SPLIT*`DIRECTION-1:0] out_credit_decre_split;
// FIFO
wire [`ROUTER_FIFO_SPLIT-1:0] fifo_read_en;
wire [`ROUTER_FIFO_SPLIT-1:0] fifo_write_en;
wire [`ROUTER_WIDTH-1:0] fifo_read_data [`ROUTER_FIFO_SPLIT-1:0];
wire fifo_empty [`ROUTER_FIFO_SPLIT-1:0];
wire fifo_full [`ROUTER_FIFO_SPLIT-1:0];
wire fifo_empty_next [`ROUTER_FIFO_SPLIT-1:0];
wire fifo_full_next [`ROUTER_FIFO_SPLIT-1:0];
// RC
wire [`ROUTER_FIFO_SPLIT-1:0] rc_request_split;
wire [`ROUTER_FIFO_SPLIT-1:0] rc_grant_split;
wire [`ROUTER_FIFO_SPLIT*`ROUTER_INFO_WIDTH-1:0] route_info_split;
wire [`ROUTER_FIFO_SPLIT*`ROUTER_ADDR_WIDTH-1:0] route_addr_split;
// SA
wire [`ROUTER_FIFO_SPLIT-1:0] sa_request_split;
wire [`ROUTER_FIFO_SPLIT-1:0] sa_grant_split;
wire [`ROUTER_FIFO_SPLIT*`ROUTER_INFO_WIDTH-1:0] sa_info_split;
wire [`ROUTER_FIFO_SPLIT*`ROUTER_ADDR_WIDTH-1:0] sa_addr_split;
// ST
wire [`ROUTER_FIFO_SPLIT*`ROUTER_WIDTH-1:0] st_data_in_split;
wire [`ROUTER_FIFO_SPLIT*`DIRECTION-1:0] st_ctrl_in_split;

// --------------------------------------------------
// Input FIFO DeMux: selectively push into 2 splits
// --------------------------------------------------
InputUnitDemux input_unit_demux (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset
  .in_data_valid    (in_data_valid),              // input data valid
  .fifo_read_en     (fifo_read_en),               // fifo read enable
  .fifo_write_en    (fifo_write_en)               // fifo write enable
);

// ---------------------------------------
// Input FIFO: holding the arriving flits
// ---------------------------------------
generate
for (g = 0; g < `ROUTER_FIFO_SPLIT; g = g + 1) begin: gen_input_fifo
fifo_sync # (
  .BIT_WIDTH        (`ROUTER_WIDTH),              // bit width
  .FIFO_DEPTH       (`ROUTER_FIFO_DEPTH)          // fifo depth (power of 2)
) input_fifo (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset

  // read interface
  .read_en          (fifo_read_en[g]),            // read enable
  .read_data        (fifo_read_data[g]),          // read data
  // write interface
  .write_en         (fifo_write_en[g]),           // write enable
  .write_data       (in_data),                    // write data

  // status indicator of FIFO
  .fifo_empty       (fifo_empty[g]),              // fifo is empty
  .fifo_full        (fifo_full[g]),               // fifo is full
  // next logic of fifo status flag
  .fifo_empty_next  (fifo_empty_next[g]),
  .fifo_full_next   (fifo_full_next[g])
);
end
endgenerate

// ----------------------------------------
// Input unit controller & state registers
// ----------------------------------------
// The state register & controller are associated with each input FIFO
generate
for (g = 0; g < `ROUTER_FIFO_SPLIT; g = g + 1) begin: gen_input_controller
InputUnitController input_unit_controller (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset (active high)
  .fifo_write_en    (fifo_write_en[g]),           // input data valid
  .fifo_empty       (fifo_empty[g]),              // channel buffer empty
  .fifo_empty_next  (fifo_empty_next[g]),         // channel buffer empty
  .fifo_data        (fifo_read_data[g]),          // channel buffer data
  .fifo_read_en     (fifo_read_en[g]),            // fifo read enable

  // credit-based flow control
  .out_credit_avail (out_credit_avail),           // downstreaming port credit
  .in_credit        (in_credit_split[g]),         // notifying upstreaming node
  .out_credit_decre (out_credit_decre_split[g*`DIRECTION
                      +:`DIRECTION]),             // downstreaming credit decrement

  // routing computation interface
  .rc_grant         (rc_grant_split[g]),          // rc grant
  .rc_request       (rc_request_split[g]),        // rc request
  .route_info       (route_info_split[g*`ROUTER_INFO_WIDTH
                      +:`ROUTER_INFO_WIDTH]),     // routing info
  .route_addr       (route_addr_split[g*`ROUTER_ADDR_WIDTH
                      +:`ROUTER_ADDR_WIDTH]),     // routing address
  .route_port       (route_port),                 // routing results

  // switch arbiter
  .sa_request       (sa_request_split[g]),        // SA request
  .sa_info          (sa_info_split[g*`ROUTER_INFO_WIDTH
                      +:`ROUTER_INFO_WIDTH]),     // SA info
  .sa_addr          (sa_addr_split[g*`ROUTER_ADDR_WIDTH
                      +:`ROUTER_ADDR_WIDTH]),     // SA address
  .sa_grant         (sa_grant_split[g]&sa_grant), // SA grant

  // switch traversal
  .st_data_in       (st_data_in_split[g*`ROUTER_WIDTH
                      +:`ROUTER_WIDTH]),          // ST data input
  .st_ctrl_in       (st_ctrl_in_split[g*`DIRECTION
                      +:`DIRECTION])              // ST control input
);
end
endgenerate

// ------------------------------------
// Arbitration of Routing Computation
// ------------------------------------
generate
if (`ROUTER_FIFO_SPLIT == 1) begin: gen_rc_arbiter_split_one
assign rc_grant_split = rc_request_split;
end else begin: gen_rc_arbiter_split_non_one
RoundRobinArbiter #(
  .N                (`ROUTER_FIFO_SPLIT)          // bit number
) rc_arbiter (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset
  .request          (rc_request_split),           // request
  .grant            (rc_grant_split)              // grant
);
end
endgenerate

// ------------------------------------
// Arbitration of Switch Allocation
// ------------------------------------
/*
RoundRobinArbiter #(
  .N                (`ROUTER_FIFO_SPLIT)          // bit number
) sa_arbiter (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset
  .request          (sa_request_split),           // request
  .grant            (sa_grant_split)              // grant
);
*/

wire [`ROUTER_FIFO_SPLIT-1:0] sa_priority;
generate
if (`ROUTER_FIFO_SPLIT == 1) begin: gen_sa_priority_split_1
  assign sa_priority = 1'b1;
end else if (`ROUTER_FIFO_SPLIT == 2) begin: gen_sa_priority_split_2
  wire [`ROUTER_INFO_WIDTH+12-1:0]  split_0_priority,
                                    split_1_priority;
  assign split_0_priority = {
    sa_info_split[`ROUTER_INFO_WIDTH-1:0],
    // Hardcode the index
    sa_addr_split[11:0]
  };
  assign split_1_priority = {
    sa_info_split[2*`ROUTER_INFO_WIDTH-1:`ROUTER_INFO_WIDTH],
    // Hardcode the index
    sa_addr_split[`ROUTER_ADDR_WIDTH+11:`ROUTER_ADDR_WIDTH]
  };
  assign sa_priority = (split_0_priority < split_1_priority) ? 2'b01 : 2'b10;
end
else begin: gen_sa_priority_undef_split
  // synopsys translate_off
  initial begin
    $display("ERROR: undefined input buffer split");
    $finish;
  end
  // synopsys translate_on
end
endgenerate
PriorityArbiter # (
  .N                (`ROUTER_FIFO_SPLIT)          // bit number
) sa_arbiter (
  .request          (sa_request_split),           // request
  .p                (sa_priority),                // priority (one-hot encoding)
  .grant            (sa_grant_split)              // grant
);

// --------------------------------------------------------------
// Input Unit Mux: select the arbitrated signals from the splits
// --------------------------------------------------------------
InputUnitMux input_unit_mux (
  // Credit
  .in_credit_split  (in_credit_split),            // upstream credit
  .out_credit_decre_split
                    (out_credit_decre_split),
  .in_credit        (in_credit),                  // upstream credit
  .out_credit_decre (out_credit_decre),           // downstream credit

  // Routing Computation
  .rc_grant_split   (rc_grant_split),             // RC grant
  .route_info_split (route_info_split),           // routing info
  .route_addr_split (route_addr_split),           // routing addr

  .rc_en            (rc_en),                      // RC enable
  .route_info       (route_info),                 // routing info
  .route_addr       (route_addr),                 // routing addr

  // Switch Allocation
  .sa_grant_split   (sa_grant_split),             // SA grant
  .sa_info_split    (sa_info_split),              // SA info
  .sa_addr_split    (sa_addr_split),              // SA address

  .sa_request       (sa_request),                 // SA request
  .sa_info          (sa_info),                    // SA info
  .sa_addr          (sa_addr),                    // SA address

  // Switch Traversal
  .st_data_in_split (st_data_in_split),           // ST data
  .st_ctrl_in_split (st_ctrl_in_split),           // ST control
  .st_data_in       (st_data_in),                 // ST data
  .st_ctrl_in       (st_ctrl_in)                  // ST control
);

endmodule
