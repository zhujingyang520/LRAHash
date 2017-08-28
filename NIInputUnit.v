// =============================================================================
// Module name: NIInputUnit
//
// This module exports the input unit for the network interface of the
// processing element.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module NIInputUnit (
  input wire  [5:0]               PE_IDX,             // PE index
  input wire                      clk,                // system clock
  input wire                      rst,                // system reset

  input wire                      router_rdy,         // router ready

  // Input datapath
  input wire                      in_data_valid,      // input data valid
  input wire  [`ROUTER_WIDTH-1:0] in_data,            // inpu data

  // PE status register interface
  input wire  [`PeActNoBus]       out_act_no,         // out act no.
  output reg                      pe_status_we,       // pe status write enable
  output reg  [`PeStatusAddrBus]  pe_status_addr,     // pe status address
  output reg  [`PeStatusDataBus]  pe_status_data,     // pe status data

  // Activation register file interface
  output reg                      in_act_write_en,    // in act write enable
  output reg  [`PeActNoBus]       in_act_write_addr,  // in act write address
  output reg  [`PeDataBus]        in_act_write_data,  // in act write data

  // PE controller interface
  output reg                      pe_start_calc,      // pe start calculation
  output reg                      comp_done,          // computation done

  // Activation queue in processing element
  input wire                      pop_act,            // pop activation
  output reg                      push_act,           // push activation
  output reg  [`PEQueueBus]       act,                // activation to be pushed

  // Read request interface
  output wire                     read_rqst_read_en,  // read request read enable
  output wire                     ni_read_rqst,       // read request enable
  output wire [`PeActNoBus]       ni_read_addr,       // read request address

  output reg                      upstream_credit     // upstream credit
);

// ---------------------------------
// Field of the input data
// ---------------------------------
wire [`ROUTER_INFO_WIDTH-1:0] route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] route_addr = in_data[31:16];
wire [`ROUTER_DATA_WIDTH-1:0] route_data = in_data[15:0];

// ---------------------------------
// Read request FIFO
// ---------------------------------
NIReadRqstQueue ni_read_rqst_queue (
  .clk                (clk),                  // system clock
  .rst                (rst),                  // system reset

  .in_data_valid      (in_data_valid),        // input data valid
  .in_data            (in_data),              // input data

  .router_rdy         (router_rdy),           // router ready

  .read_rqst_read_en  (read_rqst_read_en),    // read request read enable
  .ni_read_rqst       (ni_read_rqst),         // read request enable
  .ni_read_addr       (ni_read_addr)          // read request read data
);

// ---------------------------------
// PE status registers interface
// ---------------------------------
always @ (*) begin
  if (in_data_valid && route_info == `ROUTER_INFO_CONFIG &&
      route_addr[7] == 1'b0) begin
    // write to the PE status registers ([7] = 1'b0)
    pe_status_we    = 1'b1;
    pe_status_addr  = route_addr[`PeStatusAddrBus];
    pe_status_data  = route_data;
  end else begin
    pe_status_we    = 1'b0;
    pe_status_addr  = 0;
    pe_status_data  = 0;
  end
end

// ---------------------------------------
// PE register file of input activations
// ---------------------------------------
always @ (*) begin
  if (in_data_valid && route_info == `ROUTER_INFO_CONFIG &&
      route_addr[7] == 1'b1) begin
    in_act_write_en   = 1'b1;
    in_act_write_addr = route_addr[6:1];
    in_act_write_data = route_data;
  end else begin
    in_act_write_en   = 1'b0;
    in_act_write_addr = 0;
    in_act_write_data = 0;
  end
end

// ------------------------------------
// PE controller interfaces
// ------------------------------------
always @ (*) begin
  pe_start_calc       = 1'b0;
  comp_done           = 1'b0;
  if (in_data_valid && route_info == `ROUTER_INFO_CALC) begin
    pe_start_calc     = 1'b1;
  end

  if (in_data_valid && route_info == `ROUTER_INFO_FIN_COMP) begin
    comp_done         = 1'b1;
  end
end

// ------------------------------------
// Activation queue interface
// ------------------------------------
always @ (*) begin
  if (in_data_valid && route_info == `ROUTER_INFO_BROADCAST &&
      out_act_no > 0) begin
    // push the activation into PE queue when there is computation associated
    // with the current PE
    push_act          = 1'b1;
    act               = {route_addr[`PE_ADDR_WIDTH-1:0], route_data};
  end else if (in_data_valid && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
    // it is possible that activation queue is non-empty when receiving
    // the broadcast finish packet
    push_act          = 1'b1;
    act               = 0;  // full 0s packet
    // synopsys translate_off
    $display("@%t PE[%d] receives finish broadcast packet", $time, PE_IDX);
    // synopsys translate_on
  end else if (in_data_valid && route_info == `ROUTER_INFO_UV) begin
    // push the V calculation results into the activation queue as well
    push_act          = 1'b1;
    act               = {route_addr[`PE_ADDR_WIDTH-1:0], route_data};
    // synopsys translate_off
    $display("@%t PE[%d] receives UV[%d] = %d", $time, PE_IDX, route_addr,
      $signed(route_data));
    // synopsys translate_on
  end else begin
    push_act          = 1'b0;
    act               = 0;
  end
end

// ----------------------------------
// Upstream credit transfer
// ----------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    upstream_credit   <= 1'b0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CONFIG) begin
    // local PE consumes CONFIG packet instantly
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CALC) begin
    // local PE consumes CALC packet instantly
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_FIN_COMP) begin
    // local PE consumes FIN COMP instantly
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_BROADCAST &&
      out_act_no == 0) begin
    // release 1 upstreaming FIFO when activation no. = 0
    upstream_credit   <= 1'b1;
  end else if (pop_act) begin
    // release 1 upstreaming FIFO when consumes 1 element in PE queue
    upstream_credit   <= 1'b1;
  end else if (read_rqst_read_en) begin
    // release 1 upstreaming FIFO when issue 1 read request
    upstream_credit   <= 1'b1;
  end else begin
    upstream_credit   <= 1'b0;
  end
end

// ----------------------------------
// Display info of the local PE
// ----------------------------------
// synopsys translate_off
always @ (posedge clk) begin
  if (in_data_valid && route_info == `ROUTER_INFO_BROADCAST) begin
    $display("@%t PE[%d] received BROADCAST: addr = %d, data = %d",
      $time, PE_IDX, route_addr, $signed(route_data));
  end

  if (in_data_valid && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
    $display("@%t PE[%d] received FIN BROADCAST", $time, PE_IDX);
  end

  if (in_data_valid && route_info == `ROUTER_INFO_FIN_COMP) begin
    $display("@%t PE[%d] recieved FIN COMP", $time, PE_IDX);
  end
end
// synopsys translate_on

endmodule
