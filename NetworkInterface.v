// =============================================================================
// Module name: NetworkInterface
//
// This module exports the network interface of the processing element and
// quadtree router.
// =============================================================================

`include "router.vh"
`include "pe.vh"

module NetworkInterface # (
  parameter   PE_IDX              = 0                 // PE index
) (
  input wire                      clk,                // system clock
  input wire                      rst,                // system reset

  // local port of the leaf router
  input wire                      in_data_valid,      // input data valid
  input wire  [`ROUTER_WIDTH-1:0] in_data,            // input data
  output reg                      out_data_valid,     // output data valid
  output reg  [`ROUTER_WIDTH-1:0] out_data,           // output data
  input wire                      downstream_credit,  // credit from downstream
  output reg                      upstream_credit,    // credit to upstream

  // configuration interfaces
  // pe status registers
  output reg                      pe_status_we,       // pe status write enable
  output reg  [`PeStatusAddrBus]  pe_status_addr,     // pe status write address
  output reg  [`PeStatusDataBus]  pe_status_data,     // pe status write data
  // input activation configuration
  output reg                      in_act_write_en,    // input act write enable
  output reg  [`PeActNoBus]       in_act_write_addr,  // input act write address
  output reg  [`PeDataBus]        in_act_write_data,  // input act write data

  // PE controller interface
  output reg                      pe_start_calc,      // PE start calculation
  output wire                     router_rdy,         // router is ready to send
  input wire                      act_send_en,        // act send enable
  input wire  [`ROUTER_ADDR_WIDTH-1:0]
                                  act_send_addr,      // act send address
  input wire  [`PeDataBus]        act_send_data,      // act send data

  // Activation queue interface
  input wire                      pop_act,            // pop activation
  output reg                      push_act,           // push activation
  output reg [`PEQueueBus]        act                 // activation
);

// ------------------------
// Field of the input data
// ------------------------
wire [`ROUTER_INFO_WIDTH-1:0] route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] route_addr = in_data[31:16];
wire [`ROUTER_DATA_WIDTH-1:0] route_data = in_data[15:0];

// Downstream router FIFO credit
reg [`CREDIT_CNT_WIDTH-1:0] credit_count;

// ---------------------------------------------
// configuration interface: pe status register
// ---------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    pe_status_we    <= 1'b0;
    pe_status_addr  <= 0;
    pe_status_data  <= 0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CONFIG) begin
    if (route_addr[7] == 1'b0) begin
      pe_status_we    <= 1'b1;
      pe_status_addr  <= route_addr[3:0];
      pe_status_data  <= route_data;
    end else begin
      pe_status_we    <= 1'b0;
      pe_status_addr  <= 0;
      pe_status_data  <= 0;
    end
  end else begin
    pe_status_we    <= 1'b0;
    pe_status_addr  <= 0;
    pe_status_data  <= 0;
  end
end

// -------------------------------------------
// configuration interfaces: input activation
// -------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    in_act_write_en   <= 1'b0;
    in_act_write_addr <= 0;
    in_act_write_data <= 0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CONFIG) begin
    if (route_addr[7] == 1'b1) begin
      in_act_write_en   <= 1'b1;
      in_act_write_addr <= route_addr[6:1];
      in_act_write_data <= route_data;
    end else begin
      in_act_write_en   <= 1'b0;
      in_act_write_addr <= 0;
      in_act_write_data <= 0;
    end
  end else begin
    in_act_write_en   <= 1'b0;
    in_act_write_addr <= 0;
    in_act_write_data <= 0;
  end
end

// -------------------------
// PE controller interfaces
// -------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    pe_start_calc     <= 1'b0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CALC) begin
    pe_start_calc     <= 1'b1;
  end else begin
    pe_start_calc     <= 1'b0;
  end
end

// ---------------------
// Upstream credit send
// ---------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    upstream_credit   <= 1'b0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CONFIG) begin
    // release 1 credit asap when configuration
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CALC) begin
    // release 1 credit asap when start calculation
    upstream_credit   <= 1'b1;
  end else if (pop_act) begin
    // release 1 credit iff the downstreaming activation queue is popped
    upstream_credit   <= 1'b1;
  end else begin
    upstream_credit   <= 1'b0;
  end
end

// ----------------------
// Activation queue
// ----------------------
always @ (*) begin
  if (in_data_valid && route_info == `ROUTER_INFO_BROADCAST) begin
    push_act          = 1'b1;
    act               = {route_addr[`PE_ADDR_WIDTH-1:0], route_data};
  end else begin
    push_act          = 1'b0;
    act               = 0;
  end
end

// synopsys translate_off
always @ (posedge clk) begin
  if (in_data_valid && route_info == `ROUTER_INFO_BROADCAST) begin
    $display("@%t PE[%d] receives BROADCAST: addr = %d, data = %d",
      $time, PE_IDX, route_addr, route_data);
  end
end
// synopsys translate_on

// ------------------------
// Downstream credit count
// ------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    credit_count      <= `ROUTER_FIFO_DEPTH;
  end else begin
    case ({downstream_credit, act_send_en})
      2'b01: begin
        credit_count  <= credit_count - 1;
      end
      2'b10: begin
        credit_count  <= credit_count + 1;
      end
      default: begin
        credit_count  <= credit_count;
      end
    endcase
  end
end

// -----------------------------
// Output datapath: output FIFO
// -----------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    out_data_valid    <= 1'b0;
    out_data          <= 0;
  end else if (act_send_en) begin
    if (act_send_addr[`ROUTER_ADDR_WIDTH-1] == 1'b1) begin
      out_data_valid  <= 1'b1;
      out_data[35:32] <= `ROUTER_INFO_FIN_BROADCAST;
      out_data[31:16] <= act_send_addr;
      out_data[15:0]  <= act_send_data;
    end else begin
      out_data_valid  <= 1'b1;
      out_data[35:32] <= `ROUTER_INFO_BROADCAST;
      out_data[31:16] <= act_send_addr;
      out_data[15:0]  <= act_send_data;
    end
  end else begin
    out_data_valid    <= 1'b0;
    out_data          <= 0;
  end
end

assign router_rdy = (credit_count > 0);

endmodule
