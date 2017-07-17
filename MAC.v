// =============================================================================
// Module name: MAC
//
// This file exports the module MAC, which conducts the multiply-accumulation
// operation.
// =============================================================================

`include "pe.vh"

module MAC (
  input wire                  clk,              // system clock
  input wire                  rst,              // system reset

  // Input datapath (mac stage)
  input wire                  comp_en_mac,      // computation enable (mac)
  input wire  [`PeDataBus]    in_act_value_mac, // input activation value (mac)
  input wire  [`PeDataBus]    w_value_mac,      // weight value (mac)
  input wire  [`PeActNoBus]   out_act_addr_mac, // output activation address(mac)
  input wire  [`PeDataBus]    out_act_value_mac,// output activation value (mac)

  // Output datapath (wb stage)
  output reg                  comp_en_wb,       // computation enable (wb)
  output reg  [`PeActNoBus]   out_act_addr_wb,  // output activation address(wb)
  output reg  [`PeDataBus]    mac_result_wb     // mac result (wb)
);

// ---------------------------------
// Interconnections of the MAC unit
// ---------------------------------
wire [`PeDataBus] mac_result;

// --------------------------------
// Pipeline stage of the datapath
// --------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_wb      <= 1'b0;
    out_act_addr_wb <= 0;
    mac_result_wb   <= 0;
  end else if (comp_en_mac) begin
    comp_en_wb      <= 1'b1;
    out_act_addr_wb <= out_act_addr_mac;
    mac_result_wb   <= mac_result;
  end else begin
    comp_en_wb      <= 1'b0;
    out_act_addr_wb <= 0;
    mac_result_wb   <= 0;
  end
end

// --------------------------
// MultAdd instance
// --------------------------
MultAdd #(
  .BIT_WIDTH        (`PE_DATA_WIDTH)
) mult_add (
  .a                (in_act_value_mac),
  .b                (w_value_mac),
  .c                (out_act_value_mac),
  .y                (mac_result)
);

endmodule
