// =============================================================================
// Module name: PEControllerMux
//
// The module exports the MUX stage within the PE controller module.
// =============================================================================

`include "pe.vh"

module PEControllerMux (
  // COMP FSM
  input wire                    in_act_read_en_comp,        // read enable
  input wire  [`PeActNoBus]     in_act_read_addr_comp,      // read address
  // BROADCAST FSM
  input wire                    in_act_read_en_broadcast,   // read enable
  input wire  [`PeActNoBus]     in_act_read_addr_broadcast, // read address

  // To register file
  output reg                    in_act_read_en,             // read enable
  output reg  [`PeActNoBus]     in_act_read_addr            // read address
);

// Act register file input read enable
always @ (*) begin
  if (in_act_read_en_comp) begin
    in_act_read_en        = in_act_read_en_comp;
    in_act_read_addr      = in_act_read_addr_comp;
  end else begin
    in_act_read_en        = in_act_read_en_broadcast;
    in_act_read_addr      = in_act_read_addr_broadcast;
  end
end

endmodule
