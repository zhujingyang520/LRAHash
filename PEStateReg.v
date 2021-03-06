// =============================================================================
// Module name: PEStateReg
//
// This module exports several state registers, including
// a) layer_no: the number of layers in the neural network
// b) act_no: the number of activations in the neural network
//
// The registers are configured during the IO mode of the accelerator when boots
// up. After the initial configuration, the accelerator FSM controller uses the
// configured registers to coordinate the data path.
// =============================================================================

`include "pe.vh"

module PEStateReg (
  input wire  [5:0]               PE_IDX,       // PE index
  input wire                      clk,          // system clock
  input wire                      rst,          // system reset (active high)

  // configure data path
  input wire                      write_en,     // write enable (active high)
  input wire  [`PeStatusAddrBus]  write_addr,   // write address
  input wire  [`PeStatusDataBus]  write_data,   // write data

  // output DNN related parameters
  input wire  [`PeLayerNoBus]     layer_idx,    // layer index
  output wire [`PeLayerNoBus]     layer_no,     // layer number
  output wire [`PeActNoBus]       in_act_no,    // input activation no.
  output wire [`PeActNoBus]       out_act_no,   // output activation no.
  output wire [`PeAddrBus]        col_dim,      // column dimension
  output wire [`WMemAddrBus]      w_mem_offset, // weight memory address offset
  output wire                     in_act_relu,  // input activation relu
  output wire                     out_act_relu, // output activation relu

  // output uv calculation related parameters
  output wire                     uv_en,        // uv enable
  output wire [`RankBus]          rank_no,      // rank number
  output wire [`UMemAddrBus]      u_mem_offset, // u memory address offset
  output wire [`VMemAddrBus]      v_mem_offset, // v memory address offset

  // output truncation scheme
  output wire [`TruncWidth]       act_trunc,    // Act truncation scheme
  output wire [`TruncWidth]       act_u_trunc,  // Act u truncation scheme
  output wire [`TruncWidth]       act_v_trunc   // Act v truncation scheme
);

// Max layer no: 2 ^ layer no bus width
localparam integer MAX_LAYER_NO = 2**`PE_LAYER_NO_WIDTH;

// --------------------------------
// State registers definition
// --------------------------------
reg [`PeLayerNoBus] layer_no_reg;         // layer no of neural network
// activation no for each layer
reg [`PeActNoBus] act_no_reg [MAX_LAYER_NO-1:0];
// column dimension for each layer (no. = max layer no. - 1)
reg [`PeAddrBus] col_dim_reg [MAX_LAYER_NO-2:0];
// address offset for each layer (no. = max layer no. - 1)
reg [`WMemAddrBus] w_mem_offset_reg [MAX_LAYER_NO-2:0];
// relu enable for each layer
reg [MAX_LAYER_NO:0] relu_en_reg;
// truncation scheme for each layer
reg [`TruncWidth] act_trunc_reg [MAX_LAYER_NO-2:0];
reg [`TruncWidth] act_u_trunc_reg [MAX_LAYER_NO-3:0];
reg [`TruncWidth] act_v_trunc_reg [MAX_LAYER_NO-3:0];

// ----------------------
// UV related parameters
// ----------------------
reg [MAX_LAYER_NO-1:0] uv_en_reg;         // UV path enable register
// rank size @ each layer (no. = max layer no. - 2, excluding output layer)
reg [`RankBus] rank_no_reg [MAX_LAYER_NO-3:0];
// address offset for each layer (no. = max layer no. - 2, excluding output)
reg [`UMemAddrBus] u_mem_offset_reg [MAX_LAYER_NO-3:0];
reg [`VMemAddrBus] v_mem_offset_reg [MAX_LAYER_NO-3:0];

// -------------------------------------
// Configuration of status registers
// Hardcode the configuration address
// -------------------------------------
integer i;
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    // reset phase
    layer_no_reg      <= 0;
    for (i = 0; i < MAX_LAYER_NO; i = i + 1) begin
      act_no_reg[i]   <= 0;
    end
    for (i = 0; i < MAX_LAYER_NO-1; i = i + 1) begin
      col_dim_reg[i]  <= 0;
    end
    for (i = 0; i < MAX_LAYER_NO-1; i = i + 1) begin
      w_mem_offset_reg[i] <= 0;
    end
    relu_en_reg       <= 0;
    // uv matrix setting
    uv_en_reg         <= 0;
    for (i = 0; i < MAX_LAYER_NO-2; i = i + 1) begin
      rank_no_reg[i]  <= 0;
    end
    for (i = 0; i < MAX_LAYER_NO-2; i = i + 1) begin
      u_mem_offset_reg[i] <= 0;
    end
    for (i = 0; i < MAX_LAYER_NO-2; i = i + 1) begin
      v_mem_offset_reg[i] <= 0;
    end
    for (i = 0; i < MAX_LAYER_NO-1; i = i + 1) begin
      act_trunc_reg[i]    <= 0;
    end
    for (i = 0; i < MAX_LAYER_NO-2; i = i + 1) begin
      act_u_trunc_reg[i]  <= 0;
    end
    for (i = 0; i < MAX_LAYER_NO-2; i = i + 1) begin
      act_v_trunc_reg[i]  <= 0;
    end
  end else if (write_en) begin
    case (write_addr)
      `PE_STATUS_ADDR_WIDTH'd0: begin     // [0]: layer no.
        layer_no_reg  <= write_data[2:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: layer no. = %d", $time, PE_IDX,
          write_data[2:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd2: begin     // [2]: {act_no[1], act_no[0]}
        act_no_reg[1] <= write_data[13:8];
        act_no_reg[0] <= write_data[5:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act no.[1] = %d; act no.[0] = %d",
          $time, PE_IDX, write_data[13:8], write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd4: begin     // [4]: {act_no[3], act_no[2]}
        act_no_reg[3] <= write_data[13:8];
        act_no_reg[2] <= write_data[5:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act no.[3] = %d; act no.[2] = %d",
          $time, PE_IDX, write_data[13:8], write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd6: begin     // [6]: {act_no[5], act_no[4]}
        act_no_reg[5] <= write_data[13:8];
        act_no_reg[4] <= write_data[5:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act no.[5] = %d; act no.[4] = %d",
          $time, PE_IDX, write_data[13:8], write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd8: begin     // [8]: {act_no[7], act_no[6]}
        act_no_reg[7] <= write_data[13:8];
        act_no_reg[6] <= write_data[5:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act no.[7] = %d; act no.[6] = %d",
          $time, PE_IDX, write_data[13:8], write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd10: begin    // [10]: col_dim[0]
        col_dim_reg[0]  <= write_data[`PeAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: col dim[0] = %d", $time, PE_IDX,
          write_data[`PeAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd12: begin    // [12]: col_dim[1]
        col_dim_reg[1]  <= write_data[`PeAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: col dim[1] = %d", $time, PE_IDX,
          write_data[`PeAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd14: begin    // [14]: col_dim[2]
        col_dim_reg[2]  <= write_data[`PeAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: col dim[2] = %d", $time, PE_IDX,
          write_data[`PeAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd16: begin    // [16]: col_dim[3]
        col_dim_reg[3]  <= write_data[`PeAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: col dim[3] = %d", $time, PE_IDX,
          write_data[`PeAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd18: begin    // [18]: col_dim[4]
        col_dim_reg[4]  <= write_data[`PeAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: col dim[4] = %d", $time, PE_IDX,
          write_data[`PeAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd20: begin    // [20]: col_dim[5]
        col_dim_reg[5]  <= write_data[`PeAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: col dim[5] = %d", $time, PE_IDX,
          write_data[`PeAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd22: begin    // [22]: col_dim[6]
        col_dim_reg[6]  <= write_data[`PeAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: col dim[6] = %d", $time, PE_IDX,
          write_data[`PeAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd24: begin  // [24]: w_mem_offset[0]
        w_mem_offset_reg[0] <= write_data[`WMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: w mem offset[0] = %d", $time, PE_IDX,
          write_data[`WMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd26: begin  // [26]: w_mem_offset[1]
        w_mem_offset_reg[1] <= write_data[`WMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: w mem offset[1] = %d", $time, PE_IDX,
          write_data[`WMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd28: begin  // [28]: w_mem_offset[2]
        w_mem_offset_reg[2] <= write_data[`WMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: w mem offset[2] = %d", $time, PE_IDX,
          write_data[`WMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd30: begin  // [30]: w_mem_offset[3]
        w_mem_offset_reg[3] <= write_data[`WMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: w mem offset[3] = %d", $time, PE_IDX,
          write_data[`WMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd32: begin  // [32]: w_mem_offset[4]
        w_mem_offset_reg[4] <= write_data[`WMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: w mem offset[4] = %d", $time, PE_IDX,
          write_data[`WMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd34: begin  // [34]: w_mem_offset[5]
        w_mem_offset_reg[5] <= write_data[`WMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: w mem offset[5] = %d", $time, PE_IDX,
          write_data[`WMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd36: begin  // [36]: w_mem_offset[6]
        w_mem_offset_reg[6] <= write_data[`WMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: w mem offset[6] = %d", $time, PE_IDX,
          write_data[`WMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd38: begin  // [38]: {rank_no[1], rank_no[0]}
        rank_no_reg[1]      <= write_data[13:8];
        rank_no_reg[0]      <= write_data[5:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: rank no[1] = %d; rank_no[0] = %d",
          $time, PE_IDX, write_data[13:8], write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd40: begin  // [40]: {rank_no[3], rank_no[2]}
        rank_no_reg[3]      <= write_data[13:8];
        rank_no_reg[2]      <= write_data[5:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: rank no[3] = %d; rank_no[2] = %d",
          $time, PE_IDX, write_data[13:8], write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd42: begin  // [42]: {rank_no[5], rank_no[4]}
        rank_no_reg[5]      <= write_data[13:8];
        rank_no_reg[4]      <= write_data[5:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: rank no[5] = %d; rank_no[4] = %d",
          $time, PE_IDX, write_data[13:8], write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd44: begin  // [44]: v_mem_offset[0]
        v_mem_offset_reg[0] <= write_data[`VMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: v_mem_offset[0] = %d", $time, PE_IDX,
          write_data[`VMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd46: begin  // [46]: v_mem_offset[1]
        v_mem_offset_reg[1] <= write_data[`VMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: v_mem_offset[1] = %d", $time, PE_IDX,
          write_data[`VMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd48: begin  // [48]: v_mem_offset[2]
        v_mem_offset_reg[2] <= write_data[`VMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: v_mem_offset[2] = %d", $time, PE_IDX,
          write_data[`VMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd50: begin  // [50]: v_mem_offset[3]
        v_mem_offset_reg[3] <= write_data[`VMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: v_mem_offset[3] = %d", $time, PE_IDX,
          write_data[`VMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd52: begin  // [52]: v_mem_offset[4]
        v_mem_offset_reg[4] <= write_data[`VMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: v_mem_offset[4] = %d", $time, PE_IDX,
          write_data[`VMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd54: begin  // [54]: v_mem_offset[5]
        v_mem_offset_reg[5] <= write_data[`VMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: v_mem_offset[5] = %d", $time, PE_IDX,
          write_data[`VMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd56: begin  // [56]: u_mem_offset[0]
        u_mem_offset_reg[0] <= write_data[`UMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: u_mem_offset[0] = %d", $time, PE_IDX,
          write_data[`UMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd58: begin  // [58]: u_mem_offset[1]
        u_mem_offset_reg[1] <= write_data[`UMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: u_mem_offset[1] = %d", $time, PE_IDX,
          write_data[`UMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd60: begin  // [60]: u_mem_offset[2]
        u_mem_offset_reg[2] <= write_data[`UMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: u_mem_offset[2] = %d", $time, PE_IDX,
          write_data[`UMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd62: begin  // [62]: u_mem_offset[3]
        u_mem_offset_reg[3] <= write_data[`UMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: u_mem_offset[3] = %d", $time, PE_IDX,
          write_data[`UMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd64: begin  // [64]: u_mem_offset[4]
        u_mem_offset_reg[4] <= write_data[`UMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: u_mem_offset[4] = %d", $time, PE_IDX,
          write_data[`UMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd66: begin  // [66]: u_mem_offset[5]
        u_mem_offset_reg[5] <= write_data[`UMemAddrBus];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: u_mem_offset[5] = %d", $time, PE_IDX,
          write_data[`UMemAddrBus]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd68: begin  // [68]: uv_en
        uv_en_reg           <= write_data[MAX_LAYER_NO-1:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: uv_en = %d", $time, PE_IDX,
          write_data[MAX_LAYER_NO-1:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd70: begin  // [70]: relu_en
        relu_en_reg         <= write_data[MAX_LAYER_NO:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: relu_en = %d", $time, PE_IDX,
          write_data[MAX_LAYER_NO:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd72: begin  // [72]: act_trunc_reg[2:0]
        act_trunc_reg[2]    <= write_data[14:10];
        act_trunc_reg[1]    <= write_data[9:5];
        act_trunc_reg[0]    <= write_data[4:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act_trunc_reg[2:0] = %d",
          $time, PE_IDX, write_data[14:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd74: begin  // [74]: act_trunc_reg[5:3]
        act_trunc_reg[5]    <= write_data[14:10];
        act_trunc_reg[4]    <= write_data[9:5];
        act_trunc_reg[3]    <= write_data[4:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act_trunc_reg[5:3] = %d",
          $time, PE_IDX, write_data[14:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd76: begin  // [76]: act_trunc_reg[6]
        act_trunc_reg[6]    <= write_data[4:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act_trunc_reg[6] = %d",
          $time, PE_IDX, write_data[5:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd78: begin  // [78]: act_u_trunc_reg[2:0]
        act_u_trunc_reg[2]  <= write_data[14:10];
        act_u_trunc_reg[1]  <= write_data[9:5];
        act_u_trunc_reg[0]  <= write_data[4:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act_u_trunc_reg[2:0] = %d",
          $time, PE_IDX, write_data[14:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd80: begin  // [80]: act_u_trunc_reg[5:3]
        act_u_trunc_reg[5]  <= write_data[14:10];
        act_u_trunc_reg[4]  <= write_data[9:5];
        act_u_trunc_reg[3]  <= write_data[4:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act_u_trunc_reg[5:3] = %d",
          $time, PE_IDX, write_data[14:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd82: begin  // [82]: act_v_trunc_reg[2:0]
        act_v_trunc_reg[2]  <= write_data[14:10];
        act_v_trunc_reg[1]  <= write_data[9:5];
        act_v_trunc_reg[0]  <= write_data[4:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act_v_trunc_reg[2:0] = %d",
          $time, PE_IDX, write_data[14:0]);
        // synopsys translate_on
      end

      `PE_STATUS_ADDR_WIDTH'd84: begin  // [84]: act_v_trunc_reg[5:3]
        act_v_trunc_reg[5]  <= write_data[14:10];
        act_v_trunc_reg[4]  <= write_data[9:5];
        act_v_trunc_reg[3]  <= write_data[4:0];
        // synopsys translate_off
        $display("@%t CONFIG PE[%d]: act_v_trunc_reg[5:3] = %d",
          $time, PE_IDX, write_data[14:0]);
        // synopsys translate_on
      end

      default: begin
        /* Keep the original value */
      end
    endcase
  end
end

// ---------------
// Output logic
// ---------------
assign layer_no = layer_no_reg;
assign in_act_no = act_no_reg[layer_idx];
assign out_act_no = act_no_reg[layer_idx + 1];
assign col_dim = col_dim_reg[layer_idx];
assign w_mem_offset = w_mem_offset_reg[layer_idx];
assign in_act_relu = relu_en_reg[layer_idx];
assign out_act_relu = (layer_idx == layer_no_reg) ?
  relu_en_reg[layer_no_reg] : relu_en_reg[layer_idx + 1];
// UV related parameters
assign uv_en = uv_en_reg[layer_idx];
assign rank_no = rank_no_reg[layer_idx];
assign u_mem_offset = u_mem_offset_reg[layer_idx];
assign v_mem_offset = v_mem_offset_reg[layer_idx];
// Truncation scheme for the current layer
assign act_trunc = act_trunc_reg[layer_idx];
assign act_u_trunc = act_u_trunc_reg[layer_idx];
assign act_v_trunc = act_v_trunc_reg[layer_idx];

endmodule
