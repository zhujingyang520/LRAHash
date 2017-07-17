// =============================================================================
// Filename: global.vh
//
// This file exports the global microarchitecture of the accelerator.
// =============================================================================

`ifndef __GLOBAL_VH__
`define __GLOBAL_VH__

// -----------------------------------------------
// Port width definition of the accelerator
// -----------------------------------------------
`define DATA_WIDTH 16             // Bit width of the system data bus
`define DataBus `DATA_WIDTH-1:0
`define ADDR_WIDTH 16             // Bit width of the system address bus
`define AddrBus `ADDR_WIDTH-1:0

`endif
