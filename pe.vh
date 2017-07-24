// =============================================================================
// Filename: pe.vh
//
// This file exports the processing element related microarchitecture
// parameters.
// =============================================================================

`ifndef __PE_VH__
`define __PE_VH__

// --------------------------------
// Memory model related settings
// --------------------------------
`define CACTI_MEM_MODEL 1

// ------------------------------------------------
// Port width definition of the processing element
// ------------------------------------------------
`define PE_DATA_WIDTH 16          // Bit width of the main data path
`define PeDataBus `PE_DATA_WIDTH-1:0

`define PE_ADDR_WIDTH 12          // Bit width of the address path
`define PeAddrBus `PE_ADDR_WIDTH-1:0

// PE state registers
`define PE_STATUS_ADDR_WIDTH 4
`define PeStatusAddrBus `PE_STATUS_ADDR_WIDTH-1:0
`define PE_STATUS_DATA_WIDTH 16
`define PeStatusDataBus `PE_STATUS_DATA_WIDTH-1:0

`define PE_LAYER_NO_WIDTH 3       // Bit width of the number of layers
`define PeLayerNoBus `PE_LAYER_NO_WIDTH-1:0

`define PE_ACT_NO_WIDTH 6         // Activation number width in each PE
`define PE_ACT_NO 2**`PE_ACT_NO_WIDTH
`define PeActNoBus `PE_ACT_NO_WIDTH-1:0

`define PE_REAL_W_NO_WIDTH 14     // Real weight number width for each layer
`define PeRealWNoBus `PE_REAL_W_NO_WIDTH-1:0

// Activation registers in/out direction
`define ACT_DIR_0 1'b0            // act[0]: in; act[1]: out
`define ACT_DIR_1 1'b1            // act[0]: out; act[0]: in

// PE queue data width
`define PE_QUEUE_WIDTH `PE_DATA_WIDTH+`PE_ADDR_WIDTH
`define PEQueueBus `PE_QUEUE_WIDTH-1:0
`define PE_QUEUE_DEPTH 8
`define PE_QUEUE_DEPTH_WIDTH 4    // clog2(PE_QUEUE_DEPTH)

// Weight memory address width
`define W_MEM_ADDR_WIDTH 16
`define WMemAddrBus `W_MEM_ADDR_WIDTH-1:0
`define W_MEM_DATA_WIDTH `PE_DATA_WIDTH
`define WMemDataBus `W_MEM_DATA_WIDTH-1:0

`endif
