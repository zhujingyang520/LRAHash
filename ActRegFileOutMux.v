// =============================================================================
// Module name: ActRegFileOutMux
//
// This module exports the mux stage for the output activation of the register
// file.
// =============================================================================

`include "pe.vh"

module ActRegFileOutMux (
  input wire                  comp_en_add,        // computation enable (ADD)
  input wire  [`PeActNoBus]   out_act_addr_add,   // output activation address
  input wire                  ni_read_rqst,       // network interface read rqst
  input wire  [`PeActNoBus]   ni_read_addr,       // network interface read addr

  output reg                  out_act_read_en,    // output act read enable
  output reg  [`PeActNoBus]   out_act_read_addr   // output act read address
);

always @ (*) begin
  if (comp_en_add) begin
    out_act_read_en     = 1'b1;
    out_act_read_addr   = out_act_addr_add;
  end else if (ni_read_rqst) begin
    out_act_read_en     = 1'b1;
    out_act_read_addr   = ni_read_addr;
  end else begin
    out_act_read_en     = 1'b0;
    out_act_read_addr   = 0;
  end
end

endmodule
