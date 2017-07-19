// =============================================================================
// Module name: PEBroadcastFSM
//
// The module exports the FSM controller for broacast activations to the router.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module PEBroadcastFSM #(
  parameter   PE_IDX                = 0               // PE index
) (
  input wire                        clk,              // system clock
  input wire                        rst,              // system reset

  input wire                        router_rdy,       // router is ready
  input wire                        pe_start_calc,    // start calculation

  input wire  [`PeActNoBus]         in_act_no,        // input activation no.

  // activation register interface
  output reg                        in_act_read_en,   // input act read enable
  output reg  [`PeActNoBus]         in_act_read_addr, // read address
  input wire  [`PeDataBus]          in_act_read_data, // read data

  // network interface
  output reg                        act_send_en,      // activation send enable
  output reg  [`PeDataBus]          act_send_data,    // activation send data
  output reg  [`ROUTER_ADDR_WIDTH-1:0]
                                    act_send_addr     // activation send address
);

// ----------------------
// FSM states definition
// ----------------------
localparam    STATE_IDLE            = 4'd0,           // idle state
              STATE_TRAN_ACT        = 4'd1,           // transfer activation
              STATE_WAIT_COMP       = 4'd2;           // wait for computation

// Registers
reg [3:0] state_reg, state_next;
reg [`PeActNoBus] in_act_idx_reg, in_act_idx_next;    // in activation index

// ---------------------
// FSM state registers
// ---------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg       <= STATE_IDLE;
    in_act_idx_reg  <= 0;
  end else begin
    state_reg       <= state_next;
    in_act_idx_reg  <= in_act_idx_next;
  end
end

// --------------------
// Next-state logic
// --------------------
always @ (*) begin
  // keep the original value by default
  state_next        = state_reg;
  in_act_idx_next   = in_act_idx_reg;
  in_act_read_en    = 1'b0;
  in_act_read_addr  = 0;
  // activation to send
  act_send_en       = 1'b0;
  act_send_data     = 0;
  act_send_addr     = 0;

  case (state_reg)
    STATE_IDLE: begin
      if (pe_start_calc) begin
        state_next      = STATE_TRAN_ACT;
        in_act_idx_next = 0;
      end
    end

    STATE_TRAN_ACT: begin
      // increment the activation register if the router can send the packet
      if (router_rdy) begin
        if (in_act_idx_reg == in_act_no) begin
          // send the special packet to the root controller that all the local
          // activations have been broadcasted
          state_next    = STATE_WAIT_COMP;
          act_send_en   = 1'b1;
          act_send_data = PE_IDX;
          act_send_addr[`ROUTER_ADDR_WIDTH-1] = 1'b1;
        end else begin
          state_next    = STATE_TRAN_ACT;
          in_act_idx_next = in_act_idx_reg + 1;
          in_act_read_en  = 1'b1;
          in_act_read_addr= in_act_idx_reg;
          // send the input activation
          act_send_en     = 1'b1;
          act_send_data   = in_act_read_data;
          // address is left shift by 6 bits and plus the index
          act_send_addr   = PE_IDX + {in_act_idx_reg, 6'b000_000};
        end
      end
    end

    STATE_WAIT_COMP: begin
      // TODO
    end
  endcase
end

endmodule
