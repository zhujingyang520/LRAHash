// =============================================================================
// Module name: RootController
//
// The FSM controller at the root node (central control unit). It determines
// the global system state during computation.
// =============================================================================

`include "router.vh"
`include "global.vh"

module RootController (
  input wire                      clk,            // system clock
  input wire                      rst,            // system reset (active high)

  // interfaces of write operation
  input wire                      write_en,       // write enable (active high)
  input wire  [`DataBus]          write_data,     // write data
  input wire  [`AddrBus]          write_addr,     // write address
  output wire                     write_rdy,      // write ready

  // interfaces of LOCAL port of quadtree router
  input wire                      in_data_valid,  // input data valid
  input wire  [`ROUTER_WIDTH-1:0] in_data,        // input data
  output reg                      out_data_valid, // output data valid
  output reg  [`ROUTER_WIDTH-1:0] out_data,       // output data
  input wire                      downstream_credit,  // downstream credit
  output reg                      upstream_credit     // upstream credit
);

// -----------------------
// FSM state definition
// -----------------------
localparam    STATE_IDLE          = 2'b00,        // idle state
              STATE_COMPUTE       = 2'b01;        // compute state

// registers holding FSM state and next state logic
reg [1:0] state_reg, state_next;
// dowstream available FIFO
reg [`CREDIT_CNT_WIDTH-1:0] downstream_credit_count;
// downstream credit decrement
reg downstream_credit_count_decre;
// read data field
wire [`ROUTER_INFO_WIDTH-1:0] in_data_route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] in_data_route_addr = in_data[31:16];
wire [`ROUTER_DATA_WIDTH-1:0] in_data_route_data = in_data[15:0];

// ------------------
// FSM read datapath
// ------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    upstream_credit     <= 1'b0;
  end else if (in_data_valid) begin
    if (in_data_route_info == `ROUTER_INFO_FIN_BROADCAST) begin
      // synopsys translate_off
      $display("@%t Root Controller receives fin broadcast from PE[%d]",
        $time, in_data_route_data);
      // synopsys translate_on
      upstream_credit   <= 1'b1;
    end else begin
      // synopsys translate_off
      $display("[ERROR]: Unexpected routing type @ root controller!");
      // synopsys translate_on
    end
  end else begin
    upstream_credit     <= 1'b0;
  end
end

// ---------------------------------------------
// Credit count of the downstreaming LOCAL port
// ---------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    downstream_credit_count     <= `ROUTER_FIFO_DEPTH;
  end else begin
    case ({downstream_credit, downstream_credit_count_decre})
      2'b01: begin
        downstream_credit_count <= downstream_credit_count - 1;
      end
      2'b10: begin
        downstream_credit_count <= downstream_credit_count + 1;
      end
      default: begin
        downstream_credit_count <= downstream_credit_count;
      end
    endcase
  end
end

// ----------------
// FSM definition
// ----------------
// FSM state registers
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg <= STATE_IDLE;
  end else begin
    state_reg <= state_next;
  end
end

// FSM next-state logics
always @ (*) begin
  // hold the previous state by default
  state_next        = state_reg;
  downstream_credit_count_decre = 1'b0;
  out_data_valid    = 1'b0;
  out_data          = 0;

  case (state_reg)
    STATE_IDLE: begin
      if (write_en && write_rdy && write_addr == {`ADDR_WIDTH{1'b1}}) begin
        state_next      = STATE_COMPUTE;
        out_data_valid  = 1'b1;
        out_data[35:32] = `ROUTER_INFO_CALC;
        out_data[31:0]  = 0;
        downstream_credit_count_decre = 1'b1;
      end
      else if (write_en && write_rdy) begin
        // configure the PE. Hardcode the data packet to send
        out_data_valid  = 1'b1;
        out_data[35:32] = `ROUTER_INFO_CONFIG;
        out_data[31:16] = write_addr;
        out_data[15:0]  = write_data;
        downstream_credit_count_decre = 1'b1;
      end
    end

    STATE_COMPUTE: begin
      // TODO
      state_next      = STATE_COMPUTE;
    end
  endcase
end

// Output combinational logic
assign write_rdy = (downstream_credit_count > 0) && (state_reg == STATE_IDLE);

endmodule
