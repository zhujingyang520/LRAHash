// =============================================================================
// Module name: spram_behav
//
// It exports the behavior model of single port SRAM.
// !!! Warning: NEVER use the behavior model for synthesis. It will cause
// a large area, power overhead because synthsis tools will use flip-flop
// (rather than 6T SRAM) for the basic memory cell.
// =============================================================================

module spram_behav # (
  parameter   MEM_WIDTH               = 32,       // memory (bus) width
  parameter   MEM_DEPTH               = 4096      // memory depth
) (
  input wire                          clk,        // system clock
  input wire                          cen,        // chip enable (active low)
  input wire                          wen,        // write enable (active low)
  input wire  [clog2(MEM_DEPTH)-1:0]  addr,       // read/write address
  input wire  [MEM_WIDTH-1:0]         d,          // data input (write op)
  output reg  [MEM_WIDTH-1:0]         q           // data output (read op)
);

// -------------------
// Main memory array
// -------------------
reg [MEM_WIDTH-1:0] memory [MEM_DEPTH-1:0];

// ------------------
// Read path
// ------------------
always @ (posedge clk) begin
  if (cen == 1'b0 && wen == 1'b1) begin
    q <= memory[addr];
  end
end

// ------------------
// Write path
// ------------------
always @ (posedge clk) begin
  if (cen == 1'b0 && wen == 1'b0) begin
    memory[addr] <= d;
  end
end

// -------------------------------
// Initialization of memory array
// -------------------------------
integer j;
initial begin
  for (j = 0; j < MEM_DEPTH; j = j + 1) begin
    memory[j] = 1;
  end
end

// --------------------------------
// Function: clog2
// Returns the ceil of the log2(x)
// --------------------------------
function integer clog2(input integer x);
  integer i;
  begin
    clog2 = 0;
    for (i = x - 1; i > 0; i = i >> 1) begin
      clog2 = clog2 + 1;
    end
  end
endfunction

endmodule
