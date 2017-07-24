// =============================================================================
// Module name: RegFile
//
// This module exports a general module of the register file with one read port
// and one write port. The read operation is combinational logic (i.e. no one
// cycle latency). The module automatically handles the bypass logic between
// write and read operation.
// The RegFile also exports the REG_DEPTH zero flags, which is useful for zero
// detection in the neural network.
// =============================================================================

module RegFile #(
  parameter   BIT_WIDTH               = 16,       // bit width of the entry
  parameter   REG_DEPTH               = 64        // register file depth
) (
  input wire                          clk,        // system clock
  input wire                          clear,      // clear
  // read interface
  input wire                          read_en,    // read enable (active high)
  input wire  [clog2(REG_DEPTH)-1:0]  read_addr,  // read address
  output reg  [BIT_WIDTH-1:0]         read_data,  // read data
  // write interface
  input wire                          write_en,   // write enable (active high)
  input wire  [clog2(REG_DEPTH)-1:0]  write_addr, // write address
  input wire  [BIT_WIDTH-1:0]         write_data, // write data
  // zero detection flag
  output wire [REG_DEPTH-1:0]         zeros       // zero flag for detection
);

genvar g;

// 2D array of the register array
reg [BIT_WIDTH-1:0] reg_array [REG_DEPTH-1:0];

// ------------------------------------------------------------------
// write operation (@ rising edge, need to resolve the data hazard)
// ------------------------------------------------------------------
integer j;
always @ (posedge clk) begin
  if (clear) begin
    for (j = 0; j < REG_DEPTH; j = j + 1) begin
      reg_array[j]        <= 0;
    end
  end else if (write_en == 1'b1) begin
    reg_array[write_addr] <= write_data;
  end
end

// ------------------------------------------------------
// read operation (combinational read)
// With data forwarding to resolve the data hazard (RAW)
// ------------------------------------------------------
always @ (*) begin
  if (read_en) begin
    if (write_en && read_addr == write_addr) begin
      read_data   = write_data;
    end else begin
      read_data   = reg_array[read_addr];
    end
  end else begin
    read_data     = 0;
  end
end

// zero flags
generate
for (g = 0; g < REG_DEPTH; g = g + 1) begin: gen_zeros
  assign zeros[g] = (reg_array[g] == {BIT_WIDTH{1'b0}}) ? 1'b0 : 1'b1;
end
endgenerate

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
