// =============================================================================
// Module name: InputUnitController
//
// The controller within the input unit of router. It coordinates the datapath
// within router
// =============================================================================

`include "router.vh"

module InputUnitController (
  input wire                      clk,            // system clock
  input wire                      rst,            // system reset (active high)
  input wire                      fifo_write_en,  // fifo write enable
  input wire                      fifo_empty,     // channel buffer empty
  input wire                      fifo_empty_next,// channel buffer empty
  input wire  [`ROUTER_WIDTH-1:0] fifo_data,      // channel buffer data
  output reg                      fifo_read_en,   // fifo read enable

  // credit-based flow control
  input wire  [`DIRECTION-1:0]    out_credit_avail, // downstreaming port credit
  output wire                     in_credit,      // notifying upstreaming node
  output reg [`DIRECTION-1:0]     out_credit_decre, // downstreaming credit decrement

  // routing computation interface
  input wire                      rc_grant,       // rc grant
  output reg                      rc_request,     // rc request
  output reg  [`ROUTER_INFO_WIDTH-1:0]
                                  route_info,     // routing info
  output reg  [`ROUTER_ADDR_WIDTH-1:0]
                                  route_addr,     // routing address
  input wire  [`DIRECTION-1:0]    route_port,     // routing results

  // switch arbiter
  output reg                      sa_request,     // SA request
  output reg  [`ROUTER_INFO_WIDTH-1:0]
                                  sa_info,        // SA info
  output reg  [`ROUTER_ADDR_WIDTH-1:0]
                                  sa_addr,        // SA address
  input wire                      sa_grant,       // SA grant

  // switch traversal
  output wire [`ROUTER_WIDTH-1:0] st_data_in,     // ST data input
  output wire [`DIRECTION-1:0]    st_ctrl_in      // ST control input
);

// -----------
// FSM states
// -----------
localparam  STATE_IDLE              = 2'b00,
            STATE_ROUTING           = 2'b01,
            STATE_ACTIVE            = 2'b10;

// FSM state register
reg [1:0] state_reg, state_next;
// routing result register
reg [`DIRECTION-1:0] route_reg, route_next;
// credit of the input (upstreaming) port
reg in_credit_reg, in_credit_next;
// switch traversal interfaces
reg [`DIRECTION-1:0] st_ctrl_in_reg, st_ctrl_in_next;
reg [`ROUTER_WIDTH-1:0] st_data_in_reg, st_data_in_next;
// switch traversal register (reduce the critical path)
reg [`ROUTER_INFO_WIDTH-1:0] route_info_reg, route_info_next;
reg [`ROUTER_ADDR_WIDTH-1:0] route_addr_reg, route_addr_next;

// SA routing registers
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    route_info_reg    <= 0;
    route_addr_reg    <= 0;
  end else begin
    route_info_reg    <= route_info_next;
    route_addr_reg    <= route_addr_next;
  end
end

// -----------
// FSM states
// -----------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg   <= STATE_IDLE;
  end else begin
    state_reg   <= state_next;
  end
end

// routing register results
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    route_reg   <= 0;
  end else begin
    route_reg   <= route_next;
  end
end

// input credit
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    in_credit_reg <= 0;
  end else begin
    in_credit_reg <= in_credit_next;
  end
end
assign in_credit = in_credit_reg;

// switch traversal data & control
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    st_ctrl_in_reg  <= 0;
    st_data_in_reg  <= 0;
  end else begin
    st_ctrl_in_reg  <= st_ctrl_in_next;
    st_data_in_reg  <= st_data_in_next;
  end
end
assign st_data_in = st_data_in_reg;
assign st_ctrl_in = st_ctrl_in_reg;

// FSM next state logic & control signal
always @ (*) begin
  // default value: keep @ original value
  state_next        = state_reg;
  fifo_read_en      = 1'b0;
  in_credit_next    = 1'b0;
  out_credit_decre  = 0;
  route_next        = route_reg;
  rc_request        = 1'b0;
  route_info        = 0;
  route_addr        = 0;
  sa_request        = 1'b0;
  sa_info           = 0;
  sa_addr           = 0;
  st_ctrl_in_next   = 0;
  st_data_in_next   = 0;

  route_info_next   = route_info_reg;
  route_addr_next   = route_addr_reg;

  case (state_reg)
    STATE_IDLE: begin
      if (fifo_write_en || !fifo_empty) begin
        state_next  = STATE_ROUTING;
      end
    end

    STATE_ROUTING: begin
      // hardcode the bit location
      rc_request    = 1'b1;
      route_info    = fifo_data[35:32];
      route_addr    = fifo_data[31:16];
      // store the info & address
      route_info_next = fifo_data[35:32];
      route_addr_next = fifo_data[31:16];
      if (rc_grant) begin
        // use the routing results computated by RC module
        route_next  = route_port;
        // state next: go to wait for credit or active stage
        state_next  = STATE_ACTIVE;
      end
    end

    STATE_ACTIVE: begin
      // hardcode the address index
      sa_info           = route_info_reg;
      sa_addr           = route_addr_reg;
      if ((out_credit_avail & route_reg) == route_reg) begin
        sa_request      = 1'b1;
      end else begin
        sa_request      = 1'b0;
      end
      if (sa_grant) begin
        if (!fifo_empty_next) begin
          state_next    = STATE_ROUTING;
        end else begin
          state_next    = STATE_IDLE;
        end
        out_credit_decre= route_reg;  // credits of routed port decrements
        st_ctrl_in_next = route_reg;
        st_data_in_next = fifo_data;
        fifo_read_en    = 1'b1; // pop the data from input FIFO
        in_credit_next  = 1'b1; // release the input FIFO
                                // notify the upstreaming node
      end
    end
  endcase
end

endmodule
