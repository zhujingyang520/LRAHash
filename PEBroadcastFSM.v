// =============================================================================
// Module name: PEBroadcastFSM
//
// The module exports the FSM controller for broacast activations to the router.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module PEBroadcastFSM (
  input wire  [5:0]                 PE_IDX,           // PE index
  input wire                        clk,              // system clock
  input wire                        rst,              // system reset

  input wire                        router_rdy,       // router is ready
  input wire                        pe_start_broadcast,
                                                      // start broadcast

  input wire  [`PeActNoBus]         in_act_no,        // input activation no.

  // activation register interface
  output reg                        in_act_read_en,   // input act read enable
  output reg  [`PeActNoBus]         in_act_read_addr, // read address
  input wire  [`PeDataBus]          in_act_read_data, // read data
  input wire  [`PE_ACT_NO-1:0]      in_act_zeros,     // input activation zero

  // network interface
  output reg                        act_send_en,      // activation send enable
  output reg  [`PeDataBus]          act_send_data,    // activation send data
  output reg  [`ROUTER_ADDR_WIDTH-1:0]
                                    act_send_addr     // activation send address
);

// ----------------------
// FSM states definition
// ----------------------
localparam    STATE_IDLE            = 1'd0,           // idle state
              STATE_TRAN_ACT        = 1'd1;           // transfer activation

// Registers
reg state_reg, state_next;
reg [`PeActNoBus] lnzd_start;                         // lnzd start index

// -----------------------------------
// Leading nonzero detection outputs
// -----------------------------------
wire [`PeActNoBus] lnzd_position;
wire lnzd_valid;
// registers to reduce the critical path
reg [`PeActNoBus] lnzd_position_reg;
reg lnzd_valid_reg;

// ---------------------
// FSM state registers
// ---------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg       <= STATE_IDLE;
  end else begin
    state_reg       <= state_next;
  end
end

// --------------------
// Next-state logic
// --------------------
always @ (*) begin
  // keep the original value by default
  state_next        = state_reg;
  in_act_read_en    = 1'b0;
  in_act_read_addr  = 0;
  // activation to send
  act_send_en       = 1'b0;
  act_send_data     = 0;
  act_send_addr     = 0;
  // lnzd start index keep @ original lnzd_position_reg
  lnzd_start        = lnzd_position_reg;

  case (state_reg)
    STATE_IDLE: begin
      if (pe_start_broadcast) begin
        state_next  = STATE_TRAN_ACT;
        lnzd_start  = 0;
      end
    end

    STATE_TRAN_ACT: begin
      // increment the activation register if the router can send the packet
      if (router_rdy) begin
        if (lnzd_valid_reg == 1'b0) begin
          // send the special packet to the root controller that all the local
          // activations have been broadcasted and returned to IDLE state
          state_next      = STATE_IDLE;
          act_send_en     = 1'b1;
          act_send_data   = {10'b0, PE_IDX};
          // guarantee the finish broadcast will be sent with the lowest
          // priority
          act_send_addr[`ROUTER_ADDR_WIDTH-1] = 1'b1;
        end else begin
          state_next      = STATE_TRAN_ACT;
          in_act_read_en  = 1'b1;
          in_act_read_addr= lnzd_position_reg;
          // send the input activation
          act_send_en     = 1'b1;
          act_send_data   = in_act_read_data;
          // address is left shift by 6 bits and plus the index
          act_send_addr   = {4'd0, lnzd_position_reg, PE_IDX};
          // increment to the next start index
          lnzd_start      = lnzd_position_reg + 1;
        end
      end
    end
  endcase
end

// --------------------------------------------
// Input activation leading nonzero detection
// --------------------------------------------
LNZDRange #(
  .BIT_WIDTH          (`PE_ACT_NO)              // bit width (power of 2)
) lnzd_range (
  .data_in            (in_act_zeros),           // input data to be detected
  .start              (lnzd_start),             // start range
  .stop               (in_act_no),              // stop range

  .position           (lnzd_position),          // nonzero position within range
  .valid              (lnzd_valid)              // valid for nonzero element
);
// pipeline the LNZD results
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    lnzd_valid_reg    <= 1'b0;
    lnzd_position_reg <= 0;
  end else if (router_rdy) begin
    lnzd_valid_reg    <= lnzd_valid;
    lnzd_position_reg <= lnzd_position;
  end
end

endmodule
