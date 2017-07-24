// =============================================================================
// Module name: NetworkInterface
//
// This module exports the network interface of the processing element and
// quadtree router.
// =============================================================================

`include "router.vh"
`include "pe.vh"

module NetworkInterface (
  input wire  [5:0]               PE_IDX,             // PE index
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
  input wire  [`PeActNoBus]       out_act_no,         // output activation no.
  // input activation configuration
  output reg                      in_act_write_en,    // input act write enable
  output reg  [`PeActNoBus]       in_act_write_addr,  // input act write address
  output reg  [`PeDataBus]        in_act_write_data,  // input act write data

  // read request interface (to activation register file)
  output reg                      ni_read_rqst,       // read request
  output reg  [`PeActNoBus]       ni_read_addr,       // read address
  input wire  [`PeDataBus]        out_act_read_data,  // output activation read

  // PE controller interface
  output reg                      pe_start_calc,      // PE start calculation
  output reg                      fin_broadcast,      // finish broadcast act
  output wire                     router_rdy,         // router is ready to send
  input wire                      fin_comp,           // finish computation
  input wire                      act_send_en,        // act send enable
  input wire  [`ROUTER_ADDR_WIDTH-1:0]
                                  act_send_addr,      // act send address
  input wire  [`PeDataBus]        act_send_data,      // act send data
  output reg                      layer_done,         // layer computation done

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


// -------------------
// Read request FIFO
// -------------------
reg read_rqst_fifo_read_en;
reg read_rqst_fifo_write_en;
reg [`PeActNoBus] read_rqst_fifo_write_data;
wire [`PeActNoBus] read_rqst_fifo_read_data;
wire read_rqst_fifo_empty_next;

fifo_sync # (
  .BIT_WIDTH        (`PE_ACT_NO_WIDTH),           // bit width
  .FIFO_DEPTH       (`PE_QUEUE_DEPTH)             // fifo depth (power of 2)
) read_rqst_fifo (
  .clk              (clk),                        // system clock
  .rst              (rst),                        // system reset

  // read interface
  .read_en          (read_rqst_fifo_read_en),     // read enable
  .read_data        (read_rqst_fifo_read_data),   // read data
  // write interface
  .write_en         (read_rqst_fifo_write_en),    // write enable
  .write_data       (read_rqst_fifo_write_data),  // write data

  // status indicator of FIFO
  .fifo_empty       (/* floating */),             // fifo is empty
  .fifo_full        (/* floating */),             // fifo is full
  // next logic of fifo status flag
  .fifo_empty_next  (read_rqst_fifo_empty_next),
  .fifo_full_next   (/* floating */)
);

// Read Request FIFO control path
// write path
always @ (*) begin
  if (in_data_valid && route_info == `ROUTER_INFO_READ) begin
    read_rqst_fifo_write_en   = 1'b1;
    read_rqst_fifo_write_data = route_addr[`PeActNoBus];
  end else begin
    read_rqst_fifo_write_en   = 1'b0;
    read_rqst_fifo_write_data = 0;
  end
end
// read path
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_rqst_fifo_read_en  <= 1'b0;
    ni_read_rqst            <= 0;
    ni_read_addr            <= 0;
  end else if (~read_rqst_fifo_empty_next && router_rdy) begin
    read_rqst_fifo_read_en  <= 1'b1;
    ni_read_rqst            <= 1'b1;
    ni_read_addr            <= read_rqst_fifo_read_data;
  end else begin
    read_rqst_fifo_read_en  <= 1'b0;
    ni_read_rqst            <= 0;
    ni_read_addr            <= 0;
  end
end

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
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    fin_broadcast     <= 1'b0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
    fin_broadcast     <= 1'b1;
  end else begin
    fin_broadcast     <= 1'b0;
  end
end
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    layer_done        <= 1'b0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_FIN_COMP) begin
    layer_done        <= 1'b1;
  end else begin
    layer_done        <= 1'b0;
  end
end

// ---------------------
// Upstream credit send
// ---------------------
// corner case wrapper: receive broadcast finish packet & pop packet
// simultaneously
reg upstream_credit_borrow_reg;
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    upstream_credit_borrow_reg  <= 1'b0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_FIN_BROADCAST
      && pop_act) begin
    upstream_credit_borrow_reg  <= 1'b1;
  end else if (upstream_credit_borrow_reg && !pop_act) begin
    upstream_credit_borrow_reg  <= 1'b0;
  end
end

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    upstream_credit   <= 1'b0;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CONFIG) begin
    // release 1 credit asap when configuration
    upstream_credit   <= 1'b1;
  end else if (read_rqst_fifo_read_en) begin
    // release 1 credit asap the read request FIFO has been issued
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_CALC) begin
    // release 1 credit asap when start calculation
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
    // release 1 credit asap for finishing broadcast
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_FIN_COMP) begin
    // release 1 credit asap for finishing computation
    upstream_credit   <= 1'b1;
  end else if (in_data_valid && route_info == `ROUTER_INFO_BROADCAST &&
    out_act_no == 0) begin
    // release 1 credit asap when no computation is allocated for the current PE
    upstream_credit   <= 1'b1;
  end else if (pop_act) begin
    // release 1 credit iff the downstreaming activation queue is popped
    upstream_credit   <= 1'b1;
  end else if (upstream_credit_borrow_reg) begin
    // release the extra borrow credit
    upstream_credit   <= 1'b1;
  end else begin
    upstream_credit   <= 1'b0;
  end
end

// synopsys translate_off
always @ (posedge clk) begin
  if (in_data_valid && route_info == `ROUTER_INFO_FIN_BROADCAST && pop_act)
  begin
    $display("@%t [ERROR]: Upstream Credit overload in PE[%d]", $time, PE_IDX);
  end
end
// synopsys translate_on

// ----------------------
// Activation queue
// ----------------------
always @ (*) begin
  if (in_data_valid && route_info == `ROUTER_INFO_BROADCAST &&
      out_act_no > 0) begin
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

always @ (posedge clk) begin
  if (in_data_valid && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
    $display("@%t PE[%d] receives FIN BROADCAST", $time, PE_IDX);
  end
end

always @ (posedge clk) begin
  if (in_data_valid && route_info == `ROUTER_INFO_FIN_COMP) begin
    $display("@%t PE[%d] receives FIN COMP", $time, PE_IDX);
  end
end
// synopsys translate_on

// ------------------------
// Downstream credit count
// ------------------------
// 3 cases for sending downstreaming a packet
// a) act_send_en: broadcast the local non-zero input activation & finish
//    broadcast
// b) fin_comp: send the finish computation
// c) read_rqst_fifo_read_en: send the local output activations to primary
//    output
wire credit_decre = act_send_en | fin_comp | read_rqst_fifo_read_en;
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    credit_count      <= `ROUTER_FIFO_DEPTH;
  end else begin
    case ({downstream_credit, credit_decre})
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
  end else if (fin_comp) begin
    out_data_valid    <= 1'b1;
    out_data[35:32]   <= `ROUTER_INFO_FIN_COMP;
    out_data[31:16]   <= 0;
    out_data[15:0]    <= {10'b0, PE_IDX};

    // synopsys translate_off
    $display("@%t PE[%d] FIN COMP", $time, PE_IDX);
    // synopsys translate_on
  end else if (read_rqst_fifo_read_en) begin
    // send a read request result
    out_data_valid    <= 1'b1;
    out_data[35:32]   <= `ROUTER_INFO_READ;
    out_data[31:16]   <= {4'b0, read_rqst_fifo_read_data, PE_IDX};
    out_data[15:0]    <= out_act_read_data;
  end else begin
    out_data_valid    <= 1'b0;
    out_data          <= 0;
  end
end

assign router_rdy = (credit_count > 0);

endmodule
