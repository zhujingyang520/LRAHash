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
  output wire [`PeActNoBus]       out_act_no    // output activation no.
  //output wire [`PeActNoBus]     act_no,   // activation number
  //output wire [`PeRealWNoBus]   real_w_no // real weight number
);

// Max layer no: 2 ^ layer no bus width
localparam MAX_LAYER_NO = 2**`PE_LAYER_NO_WIDTH;

// --------------------------------
// State registers definition
// --------------------------------
reg [`PeLayerNoBus] layer_no_reg;         // layer no of neural network
// activation no for each layer
reg [`PeActNoBus] act_no_reg [MAX_LAYER_NO-1:0];

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

endmodule
