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
  output reg                        part_sum_done,// done one partial sum
  input wire                        fin_tx_part_sum,  // finish tx partial sum

  // PE status interface
  input wire  [`PeLayerNoBus]       layer_no,     // total layer no.
  input wire  [`PeActNoBus]         in_act_no,    // input activation no.
  input wire  [`PeActNoBus]         out_act_no,   // output activation no.
  input wire                        uv_en,        // UV enable for current layer
  input wire  [`RankBus]            rank_no,      // rank number
  output wire [`PeLayerNoBus]       layer_idx,    // current layer index
  input wire  [`WMemAddrBus]        w_mem_offset, // W memory offset
  input wire  [`UMemAddrBus]        u_mem_offset, // U memory offset
  input wire  [`VMemAddrBus]        v_mem_offset, // V memory offset

  // Activation register file
  input wire  [`PE_ACT_NO-1:0]      in_act_zeros, // input activation zero
  output wire                       act_regfile_dir,
  output reg                        in_act_read_en,   // input act read enable
  output reg  [`PeActNoBus]         in_act_read_addr, // input act read addr
  input wire  [`PeDataBus]          in_act_read_data, // input act read data
  input wire  [`PE_ACT_NO-1:0]      out_act_g_zeros,  // output act > zeros

  // PE activation queue interface
  input wire                        queue_empty,  // activation queue empty
  input wire                        queue_empty_next,
  input wire  [`PEQueueBus]         act_out,      // activation queue output
  output reg                        pop_act,      // activation queue pop
  output wire                       out_act_clear,// output activation clear

  // Computation datapath
  output reg  [`CompEnBus]          comp_en,      // compute enable
  output reg  [`PeAddrBus]          in_act_idx,   // input activation idx
  output reg  [`PeActNoBus]         out_act_addr, // output activation address
  output reg  [`PeDataBus]          in_act_value, // input activation value
  output reg  [`WMemAddrBus]        mem_offset    // memory offset
);

// ----------------------
// FSM state definition
// ----------------------
localparam    STATE_IDLE            = 4'd0,       // idle state
              STATE_W_CALC          = 4'd1,       // W calculation state
              STATE_W_DRAIN         = 4'd2,       // Drain existing act in queue
              STATE_LAYER_SYNC      = 4'd3,       // layer synchronization
              STATE_V_CALC          = 4'd4,       // V calculation state
              STATE_U_CALC          = 4'd5,       // U calculation state
              STATE_FIN_V_TX        = 4'd6,       // finish V tx state
              STATE_PRE_V           = 4'd7,       // pre-V computation
              STATE_FIN_U           = 4'd8;       // finish U (mask) computation

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
reg [`CompEnBus] comp_en_d;
reg [`PeAddrBus] in_act_idx_d;
reg [`PeActNoBus] out_act_addr_d;
reg [`PeDataBus] in_act_value_d;
reg [`WMemAddrBus] mem_offset_d;

// -------------------------------------------------
// UV related registers
// -------------------------------------------------
// LNZD detector for input activations
reg [`PeActNoBus] lnzd_start;
wire [`PeActNoBus] lnzd_position;
wire lnzd_valid;
reg [`PeActNoBus] lnzd_position_reg;      // register to reduce critical path
reg lnzd_valid_reg;
reg [`RankBus] rx_rank_cnt_reg, rx_rank_cnt_next;
// UV calculated mask
reg [`PE_ACT_NO-1:0] mask_reg, mask_next;
// finish u state register
reg [2:0] fin_u_cnt_reg, fin_u_cnt_next;
// LNZD detector for UV mask (output sparsity)
reg [`PeActNoBus] mask_lnzd_start;
wire [`PeActNoBus] mask_lnzd_position;
wire mask_lnzd_valid;
reg mask_lnzd_valid_reg;
reg [`PeActNoBus] mask_lnzd_position_reg;

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
    rx_rank_cnt_reg     <= 0;
    mask_reg            <= 0;
    fin_u_cnt_reg       <= 0;
  end else begin
    state_reg           <= state_next;
    layer_idx_reg       <= layer_idx_next;
    act_regfile_dir_reg <= act_regfile_dir_next;
    out_act_clear_reg   <= out_act_clear_next;
    out_act_idx_reg     <= out_act_idx_next;
    pe_start_broadcast_reg  <= pe_start_broadcast_next;
    rx_rank_cnt_reg     <= rx_rank_cnt_next;
    mask_reg            <= mask_next;
    fin_u_cnt_reg       <= fin_u_cnt_next;
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
  comp_en_d             = `COMP_EN_IDLE;
  in_act_idx_d          = 0;
  out_act_addr_d        = 0;
  in_act_value_d        = 0;
  mem_offset_d          = 0;

  // UV related register
  lnzd_start            = 0;
  in_act_read_en        = 1'b0;
  in_act_read_addr      = 0;
  part_sum_done         = 1'b0;
  rx_rank_cnt_next      = rx_rank_cnt_reg;
  fin_u_cnt_next        = fin_u_cnt_reg;
  mask_next             = mask_reg;
  // mask start register
  mask_lnzd_start       = 0;

  case (state_reg)
    STATE_IDLE: begin
      if (pe_start_calc) begin
        if (uv_en) begin
          // next state, we go to V calculation stage
          state_next        = STATE_V_CALC;
          layer_idx_next    = 0;
          out_act_idx_next  = 0;
          out_act_clear_next= 1'b1;
          lnzd_start        = 0;      // look for nonzero act @ idx = 0
          // synopsys translate_off
          $display("@%t PE[%d] starts V CALC Layer[%d]", $time, PE_IDX,
            layer_idx_next);
          // synopsys translate_on
        end else begin
          // next state, we go to W calculation stage
          state_next        = STATE_W_CALC;
          layer_idx_next    = 0;
          out_act_idx_next  = 0;
          out_act_clear_next= 1'b1;
          pe_start_broadcast_next = 1'b1;
          // synopsys translate_off
          $display("@%t PE[%d] starts W CALC Layer[%d]", $time, PE_IDX,
            layer_idx_next);
          // synopsys translate_on
        end
      end
    end

    STATE_V_CALC: begin
      // In V calculation state, we iterate over nonzero input acts
      if (lnzd_valid_reg == 1'b0) begin
        // all the nonzero input activations have been traversed
        // wrap to the first location
        lnzd_start      = 0;
        if (out_act_idx_reg == rank_no - 1) begin
          // V caculation has finished
          state_next    = STATE_FIN_V_TX;
        end else begin
          out_act_idx_next = out_act_idx_reg + 1;
        end
        part_sum_done   = 1'b1;
      end else begin
        // proceed to the next location
        lnzd_start      = lnzd_position_reg + 1;
        // read the nonzero input activations
        in_act_read_en  = 1'b1;
        in_act_read_addr= lnzd_position_reg;
        // computation path
        comp_en_d       = `COMP_EN_V;
        in_act_idx_d    = {{(`PE_ADDR_WIDTH-`PE_ACT_NO_WIDTH){1'b0}},
                            lnzd_position_reg};
        in_act_value_d  = in_act_read_data;
        out_act_addr_d  = out_act_idx_reg;
        mem_offset_d    = {{(`W_MEM_ADDR_WIDTH-`V_MEM_ADDR_WIDTH){1'b0}},
                            v_mem_offset};
      end
    end

    STATE_FIN_V_TX: begin
      if (fin_tx_part_sum) begin
        // all the partial sum have been transmitted
        state_next    = STATE_U_CALC;
        out_act_idx_next= 0;
        rx_rank_cnt_next= 0;
        out_act_clear_next = 1'b1;
      end
    end

    STATE_U_CALC: begin
      // In U calculation state, we receive the internal V results from the
      // router. It is stored in the activation queue
      if (~queue_empty) begin
        if (out_act_no != 0) begin
          // go to the next activation index
          out_act_idx_next  = (out_act_idx_reg == out_act_no-1) ? 0 :
            out_act_idx_incre;
          // computation enable
          comp_en_d       = `COMP_EN_U;
          in_act_idx_d    = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
          in_act_value_d  = act_out[`PE_DATA_WIDTH-1:0];
          out_act_addr_d  = out_act_idx_reg;
          mem_offset_d    = {{(`W_MEM_ADDR_WIDTH-`U_MEM_ADDR_WIDTH){1'b0}},
                              u_mem_offset};
        end
        if (out_act_no == 0 || out_act_idx_reg == out_act_no-1) begin
          pop_act         = 1'b1;
          rx_rank_cnt_next= rx_rank_cnt_reg + 1;
          if (rx_rank_cnt_reg == rank_no-1) begin
            // finish all the computation of the V path
            pe_start_broadcast_next = 1'b1;
            state_next    = STATE_FIN_U;
            fin_u_cnt_next= 0;
          end
        end
      end
    end

    STATE_FIN_U: begin
      fin_u_cnt_next = fin_u_cnt_reg + 1;
      if (fin_u_cnt_reg == 3'd5) begin
        out_act_clear_next= 1'b1;
        mask_next         = out_act_g_zeros;
        // reset the lnzd start = 0
        mask_lnzd_start   = 0;
      end
      else if (fin_u_cnt_reg == 3'd6) begin
        state_next        = STATE_W_CALC;
      end
    end

    STATE_W_CALC: begin
      if (~queue_empty) begin
        if (act_out != 0) begin
          if (uv_en) begin
            // UV bypass
            mask_lnzd_start = mask_lnzd_position_reg + 1;
            if (mask_lnzd_valid_reg) begin
              comp_en_d     = `COMP_EN_W;
              in_act_idx_d  = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
              in_act_value_d= act_out[`PE_DATA_WIDTH-1:0];
              out_act_addr_d= mask_lnzd_position_reg;
              mem_offset_d  = w_mem_offset;
            end
            else begin
              // all the nonzero acts have been calculated
              pop_act       = 1'b1;
              mask_lnzd_start = 0;  // return to head
            end
          end else begin
            // no UV bypass
            // go to the next activation index
            out_act_idx_next  = (out_act_idx_reg == out_act_no-1) ? 0 :
              out_act_idx_incre;
            // computation enable
            comp_en_d       = `COMP_EN_W;
            in_act_idx_d    = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
            in_act_value_d  = act_out[`PE_DATA_WIDTH-1:0];
            out_act_addr_d  = out_act_idx_reg;
            mem_offset_d    = w_mem_offset;

            // if all the activation finishes
            if (out_act_idx_reg == out_act_no-1) begin
              pop_act   = 1'b1;
            end
          end
        end else begin
          // receive full 0s packet: represents the broadcast has finished
          pop_act     = 1'b1;
          if (queue_empty_next) begin
            fin_comp    = 1'b1;
            state_next  = STATE_LAYER_SYNC;
            layer_idx_next = layer_idx_incre;
          end else begin
            state_next  = STATE_W_DRAIN;
          end
        end
      end
    end

    STATE_W_DRAIN: begin
      if (~queue_empty) begin
        if (uv_en) begin
          // UV bypass enable
          mask_lnzd_start   = mask_lnzd_position_reg + 1;
          if (mask_lnzd_valid_reg) begin
            // computation enable
            comp_en_d       = `COMP_EN_W;
            in_act_idx_d    = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
            in_act_value_d  = act_out[`PE_DATA_WIDTH-1:0];
            out_act_addr_d  = mask_lnzd_position_reg;
            mem_offset_d    = w_mem_offset;
          end else begin
            pop_act         = 1'b1;
            mask_lnzd_start = 0;
            if (queue_empty_next) begin
              fin_comp      = 1'b1;
              state_next    = STATE_LAYER_SYNC;
              layer_idx_next= layer_idx_incre;
            end
          end
        end else begin
          // go to the next activation index
          out_act_idx_next  = (out_act_idx_reg == out_act_no-1) ? 0 :
            out_act_idx_incre;
          // computation enable
          comp_en_d         = `COMP_EN_W;
          in_act_idx_d      = act_out[`PE_QUEUE_WIDTH-1:`PE_DATA_WIDTH];
          in_act_value_d    = act_out[`PE_DATA_WIDTH-1:0];
          out_act_addr_d    = out_act_idx_reg;
          mem_offset_d      = w_mem_offset;

          // if all the activation finishes
          if (out_act_idx_reg == out_act_no-1) begin
            pop_act     = 1'b1;
            if (queue_empty_next) begin
              fin_comp    = 1'b1;
              state_next  = STATE_LAYER_SYNC;
              layer_idx_next = layer_idx_incre;
            end
          end
        end
      end
    end

    STATE_LAYER_SYNC: begin
      if (comp_done) begin
        // receive the layer done flag
        if (layer_idx_reg == layer_no) begin
          // finish all the layers' computation, return to idle state
          state_next  = STATE_IDLE;
        end else begin
          // proceed to the next layer computation
          if (uv_en) begin
            state_next        = STATE_PRE_V;
          end else begin
            state_next        = STATE_W_CALC;
            pe_start_broadcast_next = 1'b1;
          end
          out_act_idx_next    = 0;
          out_act_clear_next  = 1'b1;
          act_regfile_dir_next= ~act_regfile_dir_reg;
          // synopsys translate_off
          $display("@%t PE[%d] starts CALC Layer[%d]", $time, PE_IDX,
            layer_idx_reg);
          // synopsys translate_on
        end
      end
    end

    STATE_PRE_V: begin
      // additional cycle for speculative LNZD
      state_next              = STATE_V_CALC;
      lnzd_start              = 0;
    end
  endcase
end

// -----------------------------------------------------------------------------
// Input activation leading nonzero detection
// (TODO): for a more efficient implementation, the LNZD unit can be reused with
// the LNZD in broadcast module
// -----------------------------------------------------------------------------
LNZDRange #(
  .BIT_WIDTH          (`PE_ACT_NO)              // bit width (power of 2)
) lnzd_range (
  .data_in            (in_act_zeros),           // input data to be detected
  .start              (lnzd_start),             // start range
  .stop               (in_act_no),              // stop range

  .position           (lnzd_position),          // nonzero position within range
  .valid              (lnzd_valid)              // valid for nonzero element
);
// Register @ the output of LNZD
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    lnzd_valid_reg    <= 1'b0;
    lnzd_position_reg <= 0;
  end else begin
    lnzd_valid_reg    <= lnzd_valid;
    lnzd_position_reg <= lnzd_position;
  end
end

// -----------------------------------------------------------------------------
// Output activation leading nonzero detection
// It adopts a seperate LNZD to explore the output sparsity of the neural
// network
// -----------------------------------------------------------------------------
LNZDRange #(
  .BIT_WIDTH          (`PE_ACT_NO)              // bit width (power of 2)
) mask_lnzd_range (
  .data_in            (mask_reg),               // input data to be detected
  .start              (mask_lnzd_start),        // start range
  .stop               (out_act_no),             // stop range

  .position           (mask_lnzd_position),     // nonzero position within range
  .valid              (mask_lnzd_valid)         // valid for nonzero element
);
// Register @ the output of mask LNZD
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    mask_lnzd_valid_reg     <= 1'b0;
    mask_lnzd_position_reg  <= 0;
  end else begin
    mask_lnzd_valid_reg     <= mask_lnzd_valid;
    mask_lnzd_position_reg  <= mask_lnzd_position;
  end
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
    comp_en         <= `COMP_EN_IDLE;
    in_act_idx      <= 0;
    out_act_addr    <= 0;
    in_act_value    <= 0;
    mem_offset      <= 0;
  end else begin
    comp_en         <= comp_en_d;
    in_act_idx      <= in_act_idx_d;
    out_act_addr    <= out_act_addr_d;
    in_act_value    <= in_act_value_d;
    mem_offset      <= mem_offset_d;
  end
end

endmodule
