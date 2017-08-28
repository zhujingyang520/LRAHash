// =============================================================================
// Module name: AddrComp
//
// This module exports the common arithmetic path to compute the memory address
//
// Implementation notes:
//
// The address to be computated goes as follows:
//  addr = offset + row_idx * col_dim + col_idx
// =============================================================================

`include "pe.vh"

module AddrComp (
  input wire  [`WMemAddrBus]          offset,     // memory offset
  input wire  [`PeActNoBus]           row_idx,    // row index
  input wire  [`PeAddrBus]            col_dim,    // column dimension
  input wire  [`PeAddrBus]            col_idx,    // column index
  output wire [`WMemAddrBus]          addr        // calculated address
);

assign addr = offset + row_idx * col_dim + col_idx;

endmodule
