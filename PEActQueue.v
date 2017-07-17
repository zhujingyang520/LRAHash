// =============================================================================
// Module name: PEActQueue
//
// The module exports the input activation queue within processing element.
// =============================================================================

`include "pe.vh"

module PEActQueue (
  input wire                      clk,          // system clock
  input wire                      rst,          // system reset (active high)

  // interface of network interface
  input wire                      push_act,     // push new activation to queue
  input wire  [`PEQueueBus]       act_in,       // activation (with index)

  // interface of data path
  input wire                      pop_act,      // pop the activation
  output wire [`PEQueueBus]       act_out,      // activation @ head
  output wire                     queue_empty   // flag for empty queue
);

// ---------------------------
// Instantiation of FIFO
// ---------------------------
fifo_sync # (
  .BIT_WIDTH          (`PE_QUEUE_WIDTH),        // bit width
  .FIFO_DEPTH         (`PE_QUEUE_DEPTH)         // fifo depth (power of 2)
) pe_queue_fifo (
  .clk                (clk),                    // system clock
  .rst                (rst),                    // system reset

  // read interface
  .read_en            (pop_act),                // read enable
  .read_data          (act_out),                // read data
  // write interface
  .write_en           (push_act),               // write enable
  .write_data         (act_in),                 // write data

  // status indicator of FIFO
  .fifo_empty         (queue_empty),            // fifo is empty
  .fifo_full          (/* floating */),         // fifo is full
  // next logic of fifo status flag
  .fifo_empty_next    (/* floating */),
  .fifo_full_next     (/* floating */)
);

endmodule
