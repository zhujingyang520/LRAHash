// =============================================================================
// Module name: PEComputationFSM
//
// The module exports the FSM controller for coordinating the PE computation.
// =============================================================================

`include "pe.vh"

module PEComputationFSM (
  input wire  [5:0]                 PE_IDX,       // PE index
  input wire                        clk,          // system clock
  input wire                        rst,          // system reset (active high)
  input wire                        pe_start_calc,// start calcultion
  output wire                       pe_start_broadcast,
                                                  // pe start broadcast
  output reg                        fin_comp,     // finish computation
  input wire                        comp_done,    // layer computation done

  // PE status interface
  input wire  [`PeLayerNoBus]       layer_no,     // total layer no.
  input wire  [`PeActNoBus]         out_act_no,   // output activation no.
  output wire [`PeLayerNoBus]       layer_idx,    // current layer index

  // Activation register file
  output wire                       act_regfile_dir,

  // PE activation queue interface
  input wire                        queue_empty,  // activation queue empty
  input wire                        queue_empty_next,
  input wire  [`PEQueueBus]         act_out,      // activation queue output
  output reg                        pop_act,      // activation queue pop
  output wire                       out_act_clear,// output activation clear

  // Computation datapath
  output reg                        comp_en,      // compute enable
  output reg  [`PeAddrBus]          in_act_idx,   // input activation idx
  output reg  [`PeActNoBus]         out_act_addr, // output activation address
  output reg  [`PeDataBus]          in_act_value  // input activation value
);

// ----------------------
// FSM state definition
// ----------------------
localparam    STATE_IDLE            = 4'd0,       // idle state
              STATE_W_CALC          = 4'd1,       // W calculation state
              STATE_W_DRAIN         = 4'd2,       // Drain existing act in queue
              STATE_LAYER_SYNC      = 4'd3;       // layer synchronization

// FSM state register
reg [3:0] state_reg, state_next;
// Broadcast starting flag
reg pe_start_broadcast_reg, pe_start_broadcast_next;
// Layer index register
reg [`PeLayerNoBus] layer_idx_reg, layer_idx_next;
wire [`PeLayerNoBus] layer_idx_incre = layer_idx_reg + 1;
// Activation register file direction
reg act_regfile_dir_reg, act_regfile_dir_next;
// Output activation index register
reg [`PeActNoBus] out_act_idx_reg, out_act_idx_next;
wire [`PeActNoBus] out_act_idx_incre = out_act_idx_reg + 1;
// Output activation clear
reg out_act_clear_reg, out_act_clear_next;
// Computation datapath (DFF d input)
reg comp_en_d;
reg [`PeAddrBus] in_act_idx_d;
reg [`PeActNoBus] out_act_addr_d;
reg [`PeDataBus] in_act_value_d;

// -----------------------------
// Register definition
// -----------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg           <= STATE_IDLE;
    layer_idx_reg       <= 0;
    act_regfile_dir_reg <= `ACT_DIR_0;
    out_act_clear_reg   <= 1'b0;
    out_act_idx_reg     <= 0;
    pe_start_broadcast_reg  <= 1'b0;
  end else begin
    state_reg           <= state_next;
    layer_idx_reg       <= layer_idx_next;
    act_regfile_dir_reg <= act_regfile_dir_next;
    out_act_clear_reg   <= out_act_clear_next;
    out_act_idx_reg     <= out_act_idx_next;
    pe_start_broadcast_reg  <= pe_start_broadcast_next;
  end
end

// FSM next-state logic
always @ (*) begin
  // keep the original values by default
  state_next            = state_reg;
  layer_idx_next        = layer_idx_reg;
  act_regfile_dir_next  = act_regfile_dir_reg;
  out_act_idx_next      = out_act_idx_reg;
  // disable start broadcast
  pe_start_broadcast_next = 1'b0;
  // disable finish computation
  fin_comp              = 1'b0;

  // disable pop activation queue & output activation clear
  pop_act               = 1'b0;
  out_act_clear_next    = 1'b0;

  // computation datapath (disable by default)
  comp_en_d             = 1'b0;
  in_act_idx_d          = 0;
  out_act_addr_d        = 0;
  in_act_value_d        = 0;
  case (state_reg)
    STATE_IDLE: begin
      if (pe_start_calc) begin
        // next state, we go to W calculation stage
        state_next        = STATE_W_CALC;
        layer_idx_next    = 0;
        out_act_idx_next  = 0;
        out_act_clear_next= 1'b1;
        pe_start_broadcast_next = 1'b1;
        // synopsys translate_off
        $display("@%t PE[%d] starts CALC Layer[%d]", $time, PE_IDX,
          layer_idx_next);
        // synopsys translate_on
      end
    end

    STATE_W_CALC: begin
      if (~queue_empty) begin
        if (act_out != 0) begin
          // go to the next activation index
          out_act_idx_next  = (out_act_idx_reg == out_act_no-1) ? 0 :
            out_act_idx_incre;
          // computation enable
          comp_en_d     = 1'b1;
          in_act_idx_d  = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
          in_act_value_d= act_out[`PE_DATA_WIDTH-1:0];
          out_act_addr_d= out_act_idx_reg;

          // if all the activation finishes
          if (out_act_idx_reg == out_act_no-1) begin
            pop_act   = 1'b1;
          end
        end else begin
          // receive full 0s packet: represents the broadcast has finished
          pop_act     = 1'b1;
          if (queue_empty_next) begin
            fin_comp    = 1'b1;
            state_next  = STATE_LAYER_SYNC;
          end else begin
            state_next  = STATE_W_DRAIN;
          end
        end
      end
    end

    STATE_W_DRAIN: begin
      if (~queue_empty) begin
        // go to the next activation index
        out_act_idx_next  = (out_act_idx_reg == out_act_no-1) ? 0 :
          out_act_idx_incre;
        // computation enable
        comp_en_d     = 1'b1;
        in_act_idx_d  = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
        in_act_value_d= act_out[`PE_DATA_WIDTH-1:0];
        out_act_addr_d= out_act_idx_reg;

        // if all the activation finishes
        if (out_act_idx_reg == out_act_no-1) begin
          pop_act     = 1'b1;
          if (queue_empty_next) begin
            fin_comp    = 1'b1;
            state_next  = STATE_LAYER_SYNC;
          end
        end
      end
    end

    STATE_LAYER_SYNC: begin
      if (comp_done) begin
        // receive the layer done flag
        if (layer_idx_reg == layer_no - 1) begin
          // finish all the layers' computation, return to idle state
          state_next  = STATE_IDLE;
        end else begin
          // proceed to the next layer computation
          state_next          = STATE_W_CALC;
          layer_idx_next      = layer_idx_incre;
          out_act_idx_next    = 0;
          out_act_clear_next  = 1'b1;
          pe_start_broadcast_next = 1'b1;
          act_regfile_dir_next= ~act_regfile_dir_reg;
          // synopsys translate_off
          $display("@%t PE[%d] starts CALC Layer[%d]", $time, PE_IDX,
            layer_idx_next);
          // synopsys translate_on
        end
      end
    end
  endcase
end

// -----------------------------
// Primary output assignment
// -----------------------------
assign layer_idx = layer_idx_reg;
assign act_regfile_dir = act_regfile_dir_reg;
assign out_act_clear = out_act_clear_reg;
assign pe_start_broadcast = pe_start_broadcast_reg;
// Register the computation datapath to reduce the critical path
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en         <= 1'b0;
    in_act_idx      <= 0;
    out_act_addr    <= 0;
    in_act_value    <= 0;
  end else begin
    comp_en         <= comp_en_d;
    in_act_idx      <= in_act_idx_d;
    out_act_addr    <= out_act_addr_d;
    in_act_value    <= in_act_value_d;
  end
end

endmodule
