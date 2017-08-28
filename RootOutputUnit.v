// =============================================================================
// Module name: RootOutputUnit
//
// The module exports the output unit at the root node. It includes the credit
// count for the downstreaming router, the output port to the quadtree router,
// and the read request FIFO for the primary output of the accelerator.
// =============================================================================

`include "router.vh"
`include "global.vh"

module RootOutputUnit (
  input wire                            clk,                // system clock
  input wire                            rst,                // system reset
  output wire                           router_rdy,         // router ready

  // primary read handshake
  input wire                            read_data_rdy,      // read data ready
  output reg                            read_data_vld,      // read data valid
  output reg  [`ReadDataBus]            read_data,          // read data

  // interfaces of RootCompController
  input wire                            comp_tx_en,         // comp tx enable
  input wire  [`ROUTER_WIDTH-1:0]       comp_tx_data,       // comp tx data

  // interfaces of RootRankController
  input wire                            rank_tx_en,         // rank tx enable
  input wire  [`ROUTER_WIDTH-1:0]       rank_tx_data,       // rank tx data

  // interfaces of the LOCAL port of Root Quadtree router
  // credit interface
  input wire                            downstream_credit,  // dowstream credit
  output reg                            upstream_credit,    // upstream credit
  // data interface
  input wire                            in_data_valid,      // input data valid
  input wire  [`ROUTER_WIDTH-1:0]       in_data,            // input data
  output reg                            out_data_valid,     // output data valid
  output reg  [`ROUTER_WIDTH-1:0]       out_data            // output data
);

// ----------------------------------
// downstream available creidt count
// ----------------------------------
wire credit_count_decre = comp_tx_en | rank_tx_en;
reg [`CREDIT_CNT_WIDTH-1:0] credit_count;

// ----------------------------------
// Hardcode the field of data
// ----------------------------------
wire [`ROUTER_INFO_WIDTH-1:0] in_data_route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] in_data_route_addr = in_data[31:16];
wire [`ROUTER_DATA_WIDTH-1:0] in_data_route_data = in_data[15:0];

// ----------------------------------------------------------------------
// Read operation FIFO: store the read data when the port is not ready
// ----------------------------------------------------------------------
reg read_op_fifo_read_en;
wire [`ReadDataBus] read_op_fifo_read_data;
reg read_op_fifo_write_en;
reg [`ReadDataBus] read_op_fifo_write_data;
wire read_op_fifo_empty;

// ----------------------------------
// Credit count update
// ----------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    credit_count        <= `TOT_FIFO_DEPTH;
  end else begin
    case ({downstream_credit, credit_count_decre})
      2'b01: begin
        credit_count    <= credit_count - 1;
      end
      2'b10: begin
        credit_count    <= credit_count + 1;
      end
      default: begin
        credit_count    <= credit_count;
      end
    endcase
  end
end
// Router ready
assign router_rdy       = (credit_count > 0);

// ----------------------------------
// Output registers
// ----------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    out_data_valid      <= 1'b0;
    out_data            <= 0;
  end else if (comp_tx_en) begin
    out_data_valid      <= 1'b1;
    out_data            <= comp_tx_data;
  end else if (rank_tx_en) begin
    out_data_valid      <= 1'b1;
    out_data            <= rank_tx_data;
  end else begin
    out_data_valid      <= 1'b0;
    out_data            <= 0;
  end
end

// ------------------------------------------------------------
// Upstreaming credit, notifying the credit count to increment
// ------------------------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    upstream_credit     <= 1'b0;
  end else if (in_data_valid && in_data_route_info != `ROUTER_INFO_READ) begin
    // for non-read packet at the Root Node, it can be immediated consumed
    upstream_credit     <= 1'b1;
  end else if (read_op_fifo_read_en) begin
    upstream_credit     <= 1'b1;
  end else begin
    upstream_credit     <= 1'b0;
  end
end

// -------------------------------------------
// Read operation FIFO
// -------------------------------------------
fifo_sync # (
  .BIT_WIDTH            (`READ_DATA_WIDTH),         // bit width
  .FIFO_DEPTH           (`TOT_FIFO_DEPTH)           // fifo depth (power of 2)
) read_op_fifo (
  .clk                  (clk),                      // system clock
  .rst                  (rst),                      // system reset

  // read interface
  .read_en              (read_op_fifo_read_en),     // read enable
  .read_data            (read_op_fifo_read_data),   // read data
  // write interface
  .write_en             (read_op_fifo_write_en),    // write enable
  .write_data           (read_op_fifo_write_data),  // write data

  // status indicator of FIFO
  .fifo_empty           (read_op_fifo_empty),       // fifo is empty
  .fifo_full            (/* floating */),           // fifo is full
  // next logic of fifo status flag
  .fifo_empty_next      (/* floating */),
  .fifo_full_next       (/* floating */)
);
// FIFO read control
always @ (*) begin
  if (~read_op_fifo_empty && read_data_rdy) begin
    read_op_fifo_read_en    = 1'b1;
  end else begin
    read_op_fifo_read_en    = 1'b0;
  end
end
// FIFO write control
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_op_fifo_write_en   <= 1'b0;
    read_op_fifo_write_data <= 0;
  end else if (in_data_valid && in_data_route_info == `ROUTER_INFO_READ) begin
    read_op_fifo_write_en   <= 1'b1;
    read_op_fifo_write_data <= {in_data_route_addr[11:0], in_data_route_data};
  end else begin
    read_op_fifo_write_en   <= 1'b0;
    read_op_fifo_write_data <= 0;
  end
end

// ----------------------------------------------------------
// Primary read data path (valid & ready handshake protocol)
// ----------------------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_data_vld           <= 1'b0;
    read_data               <= 0;
  end else if (~read_op_fifo_empty && read_data_rdy) begin
    read_data_vld           <= 1'b1;
    read_data               <= read_op_fifo_read_data;
  end else begin
    read_data_vld           <= 1'b0;
    read_data               <= 0;
  end
end

endmodule
