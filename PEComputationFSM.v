// =============================================================================
// Module name: PEComputationFSM
//
// The module exports the FSM controller for coordinating the PE computation.
// =============================================================================

`include "pe.vh"

module PEComputationFSM #(
  parameter   PE_IDX                = 0           // PE index
) (
  input wire                        clk,          // system clock
  input wire                        rst,          // system reset (active high)
  input wire                        pe_start_calc,// start calcultion

  // PE status interface
  input wire  [`PeLayerNoBus]       layer_no,     // total layer no.
  input wire  [`PeActNoBus]         out_act_no,   // output activation no.
  output wire [`PeLayerNoBus]       layer_idx,    // current layer index

  // PE activation queue interface
  input wire                        queue_empty,  // activation queue empty
  input wire  [`PEQueueBus]         act_out,      // activation queue output
  output reg                        pop_act,      // activation queue pop
  output reg                        out_act_clear,// output activation clear

  // Computation datapath
  output reg                        comp_en,      // compute enable
  output reg  [`PeAddrBus]          in_act_idx,   // input activation idx
  output reg  [`PeAddrBus]          out_act_idx,  // output activation idx
  output reg  [`PeActNoBus]         out_act_addr, // output activation address
  output reg  [`PeDataBus]          in_act_value  // input activation value
);

// ----------------------
// FSM state definition
// ----------------------
localparam    STATE_IDLE            = 4'd0,       // idle state
              STATE_W_CALC          = 4'd1;       // calculate W state

// FSM state register
reg [3:0] state_reg, state_next;
// Layer index register
reg [`PeLayerNoBus] layer_idx_reg, layer_idx_next;
wire [`PeLayerNoBus] layer_idx_incre = layer_idx_reg + 1;
// Output activation index register
reg [`PeActNoBus] out_act_idx_reg, out_act_idx_next;
wire [`PeActNoBus] out_act_idx_incre = out_act_idx_reg + 1;
// absolute value of activation index (* 64 + pe idx)
wire [`PeAddrBus] abs_out_act_idx = {out_act_idx_reg, 6'b000_000} + PE_IDX;

// -----------------------------
// Register definition
// -----------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg       <= STATE_IDLE;
    layer_idx_reg   <= 0;
    out_act_idx_reg <= 0;
  end else begin
    state_reg       <= state_next;
    layer_idx_reg   <= layer_idx_next;
    out_act_idx_reg <= out_act_idx_next;
  end
end

// FSM next-state logic
always @ (*) begin
  // keep the original values by default
  state_next        = state_reg;
  layer_idx_next    = layer_idx_reg;
  out_act_idx_next  = out_act_idx_reg;

  // disable pop activation queue & output activation clear
  pop_act           = 1'b0;
  out_act_clear     = 1'b0;

  // computation datapath (disable by default)
  comp_en           = 1'b0;
  in_act_idx        = 0;
  out_act_idx       = 0;
  out_act_addr      = 0;
  in_act_value      = 0;
  case (state_reg)
    STATE_IDLE: begin
      if (pe_start_calc) begin
        // transfer to the computation state
        state_next  = STATE_W_CALC;
        layer_idx_next    = 0;
        out_act_idx_next  = 0;
        out_act_clear     = 1'b1;
        // synopsys translate_off
        $display("@%t PE[%d] starts CALC", $time, PE_IDX);
        // synopsys translate_on
      end
    end

    STATE_W_CALC: begin
      if (~queue_empty) begin
        // go to the next activation index
        out_act_idx_next  = (out_act_idx_reg == out_act_no-1) ? 0 :
          out_act_idx_incre;
        // computation enable
        comp_en     = 1'b1;
        in_act_idx  = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
        in_act_value= act_out[`PE_DATA_WIDTH-1:0];
        out_act_idx = abs_out_act_idx;
        out_act_addr= out_act_idx_reg;

        // if all the activation finishes
        if (out_act_idx_reg == out_act_no-1) begin
          pop_act   = 1'b1;
        end
      end else begin
        // wait for the input activation arriving
      end
    end
  endcase
end


// -----------------------------
// Primary output assignment
// -----------------------------
assign layer_idx = layer_idx_reg;

endmodule
