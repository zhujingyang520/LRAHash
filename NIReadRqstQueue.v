// =============================================================================
// Module name: NIReadRqstQueue
//
// This file exports the read request queue in the network interface. It
// contains the FIFO stores the read request from the primary port.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module NIReadRqstQueue (
  input wire                    clk,                // system clock
  input wire                    rst,                // system reset

  input wire                    in_data_valid,      // input data valid
  input wire  [`ROUTER_WIDTH-1:0]
                                in_data,            // input data

  input wire                    router_rdy,         // router ready

  output reg                    read_rqst_read_en,  // read request read enable
  output reg                    ni_read_rqst,       // read request enable
  output reg  [`PeActNoBus]     ni_read_addr        // read request read data
);

// ---------------------------------
// Field of the input data
// ---------------------------------
wire [`ROUTER_INFO_WIDTH-1:0] route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] route_addr = in_data[31:16];

// ---------------------------------------------
// Interconnections of the read request FIFO
// ---------------------------------------------
reg read_rqst_write_en;
reg [`PeActNoBus] read_rqst_write_data;
wire [`PeActNoBus] read_rqst_read_data;
wire read_rqst_empty;

// --------------------------------------
// Read request FIFO instantiation
// --------------------------------------
fifo_sync # (
  .BIT_WIDTH          (`PE_ACT_NO_WIDTH),           // bit width
  .FIFO_DEPTH         (`PE_QUEUE_DEPTH)             // fifo depth (power of 2)
) read_rqst_fifo (
  .clk                (clk),                        // system clock
  .rst                (rst),                        // system reset

  // read interface
  .read_en            (read_rqst_read_en),          // read enable
  .read_data          (read_rqst_read_data),        // read data
  // write interface
  .write_en           (read_rqst_write_en),         // write enable
  .write_data         (read_rqst_write_data),       // write data

  // status indicator of FIFO
  .fifo_empty         (read_rqst_empty),            // fifo is empty
  .fifo_full          (/* floating */),             // fifo is full
  // next logic of fifo status flag
  .fifo_empty_next    (/* floating */),
  .fifo_full_next     (/* floating */)
);

// --------------------------------------
// Read request FIFO write path
// --------------------------------------
always @ (*) begin
  if (in_data_valid && route_info == `ROUTER_INFO_READ) begin
    read_rqst_write_en    = 1'b1;
    read_rqst_write_data  = route_addr[`PeActNoBus];
  end else begin
    read_rqst_write_en    = 1'b0;
    read_rqst_write_data  = 0;
  end
end

// -------------------------------------
// Read request FIFO read control path
// -------------------------------------
always @ (*) begin
  if (~read_rqst_empty && router_rdy) begin
    read_rqst_read_en     = 1'b1;
  end else begin
    read_rqst_read_en     = 1'b0;
  end
end

// ------------------------------------------------------------
// Read request FIFO read data path
// Register the read request data to reduce the critical path
// ------------------------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    ni_read_rqst          <= 1'b0;
    ni_read_addr          <= 0;
  end else begin
    ni_read_rqst          <= read_rqst_read_en;
    ni_read_addr          <= read_rqst_read_data;
  end
end

endmodule
