// =============================================================================
// Module name: PEBroadcastPartSumFSM
//
// This module broadcasts the partial sum of during the V computation stage.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module PEBroadcastPartSumFSM (
  input wire  [5:0]             PE_IDX,             // PE index
  input wire                    clk,                // system clock
  input wire                    rst,                // system reset

  input wire                    router_rdy,         // router is ready
  input wire                    part_sum_done,      // one partial sum done
  input wire  [`RankBus]        rank_no,            // rank number
  output reg                    fin_tx_part_sum,    // finish tx partial sum

  // output activations of the register file
  // use secondary read port
  output reg                    out_act_read_en_s,  // read enable
  output reg  [`PeActNoBus]     out_act_read_addr_s,// read address
  input wire  [`PeDataBus]      out_act_read_data_s,// read data

  // interfaces of network interface
  output reg                    part_sum_send_en,   // partial sum send enable
  output reg  [`PeDataBus]      part_sum_send_data, // partial sum send data
  output reg  [`ROUTER_ADDR_WIDTH-1:0]
                                part_sum_send_addr  // partial sum send address
);

// -------------------------
// FSM state definition
// -------------------------
localparam  STATE_IDLE            = 1'd0,           // idle state
            STATE_TRAN_PART_SUM   = 1'd1;           // transfer partial sum

// state registers
reg state_reg, state_next;
// counter of partial sum done
reg [`RankBus] part_sum_done_cnt_reg, part_sum_done_cnt_next;
// increments the partial sum done
reg part_sum_done_incre [`COMP_PIPE_STAGE-2:0];
// counter of partial sum tx
reg [`RankBus] part_sum_tx_cnt_reg, part_sum_tx_cnt_next;

// --------------------------------------------------------------------------
// Partial sum done incrementer
// The part_sum_done is sent from controller, where the actual final results
// requires an extra computation pipeline stages to finish
// --------------------------------------------------------------------------
genvar g;
always @ (*) begin
  part_sum_done_incre[0]      = part_sum_done;
end
generate
for (g = 1; g < `COMP_PIPE_STAGE-1; g = g + 1) begin: gen_part_sum_done_incre
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      part_sum_done_incre[g]  <= 1'b0;
    end else begin
      part_sum_done_incre[g]  <= part_sum_done_incre[g-1];
    end
  end
end
endgenerate

// ---------------------
// FSM state registers
// ---------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg         <= STATE_IDLE;
  end else begin
    state_reg         <= state_next;
  end
end
// Counter of partial sum done
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    part_sum_done_cnt_reg <= 0;
  end else begin
    part_sum_done_cnt_reg <= part_sum_done_cnt_next;
  end
end
// Counter of partial sum tx
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    part_sum_tx_cnt_reg   <= 0;
  end else begin
    part_sum_tx_cnt_reg   <= part_sum_tx_cnt_next;
  end
end

// ---------------------
// Next-state logic
// ---------------------
always @ (*) begin
  // keep the original state by default
  state_next              = state_reg;
  part_sum_done_cnt_next  = part_sum_done_cnt_reg;
  part_sum_tx_cnt_next    = part_sum_tx_cnt_reg;
  // disable control path
  // activation read disabled & network interface send disable
  out_act_read_en_s       = 1'b0;
  out_act_read_addr_s     = 0;
  part_sum_send_en        = 1'b0;
  part_sum_send_addr      = 0;
  part_sum_send_data      = 0;
  fin_tx_part_sum         = 1'b0;

  case (state_reg)
    STATE_IDLE: begin
      if (part_sum_done) begin
        // transfer to transmit partial sum state
        state_next              = STATE_TRAN_PART_SUM;
        // reset the counter
        part_sum_done_cnt_next  = 0;
        part_sum_tx_cnt_next    = 0;
      end
    end

    STATE_TRAN_PART_SUM: begin
      if (part_sum_done_incre[`COMP_PIPE_STAGE-2]) begin
        part_sum_done_cnt_next  = part_sum_done_cnt_reg + 1;
      end

      // ready to send the partial sum
      if (part_sum_done_cnt_reg > part_sum_tx_cnt_reg && router_rdy) begin
        // read the output activation through the secondary read port
        out_act_read_en_s       = 1'b1;
        out_act_read_addr_s     = part_sum_tx_cnt_reg;
        // network interface
        part_sum_send_en        = 1'b1;
        part_sum_send_addr      = {{(`ROUTER_ADDR_WIDTH-`RANK_WIDTH){1'b0}},
                                    part_sum_tx_cnt_reg};
        part_sum_send_data      = out_act_read_data_s;

        // increments the part_sum_tx_cnt_reg
        part_sum_tx_cnt_next    = part_sum_tx_cnt_reg + 1;
        if (part_sum_tx_cnt_reg == rank_no-1) begin
          // sends all the partial sums
          state_next            = STATE_IDLE;
          fin_tx_part_sum       = 1'b1;
        end

        // display info
        // synopsys translate_off
        $display("@%t PE[%d] BROADCAST partial sum[%d] = %d", $time, PE_IDX,
          part_sum_tx_cnt_reg, $signed(out_act_read_addr_s));
        // synopsys translate_on
      end
    end
  endcase
end

endmodule
