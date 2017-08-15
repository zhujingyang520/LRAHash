// =============================================================================
// Module name: fifo_sync
//
// This file exports the synchronous FIFO.
// =============================================================================

module fifo_sync # (
  parameter     BIT_WIDTH             = 8,          // bit width
  parameter     FIFO_DEPTH            = 8           // fifo depth (power of 2)
) (
  input wire                          clk,          // system clock
  input wire                          rst,          // system reset

  // read interface
  input wire                          read_en,      // read enable
  output wire   [BIT_WIDTH-1:0]       read_data,    // read data
  // write interface
  input wire                          write_en,     // write enable
  input wire    [BIT_WIDTH-1:0]       write_data,   // write data

  // status indicator of FIFO
  output wire                         fifo_empty,   // fifo is empty
  output wire                         fifo_full,    // fifo is full
  // next logic of fifo status flag
  output reg                          fifo_empty_next,
  output reg                          fifo_full_next
);

// Address width: clog2(FIFO_DEPTH)
localparam ADDR_WIDTH = clog2(FIFO_DEPTH);

// ----------------------------------
// FIFO memory array (inferred DFFs)
// ----------------------------------
reg [BIT_WIDTH-1:0] fifo_array [FIFO_DEPTH-1:0];

// ----------------------
// FIFO status registers
// ----------------------
reg fifo_full_reg/*, fifo_full_next*/;
reg fifo_empty_reg/*, fifo_empty_next*/;

generate
if (FIFO_DEPTH == 1) begin: gen_depth_eq_1

// status register
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    fifo_full_reg   <= 1'b0;
    fifo_empty_reg  <= 1'b1;
  end else begin
    fifo_full_reg   <= fifo_full_next;
    fifo_empty_reg  <= fifo_empty_next;
  end
end
assign fifo_empty = fifo_empty_reg;
assign fifo_full = fifo_full_reg;

// -----------
// Write path
// -----------
always @ (posedge clk) begin
  if (write_en && ~fifo_full_reg) begin
    fifo_array[0] <= write_data;
  end
end

// ----------
// Read path
// ----------
assign read_data = (~fifo_empty_reg) ? fifo_array[0] : 0;

// -----------------------
// Next-logic computation
// -----------------------
always @ (*) begin
  // keep the original value
  fifo_full_next  = fifo_full_reg;
  fifo_empty_next = fifo_empty_reg;

  case({read_en, write_en})
    2'b00, 2'b11: begin
      // keep the original values
    end

    2'b01: begin
      // write operation
      if (~fifo_full_reg) begin
        fifo_empty_next = 1'b0;
        fifo_full_next  = 1'b1;
      end
    end

    2'b10: begin
      // read operation
      if (~fifo_empty_reg) begin
        fifo_empty_next = 1'b1;
        fifo_full_next  = 1'b0;
      end
    end
  endcase
end

end // FIFO depth = 1

else begin: gen_depth_greater_1
// -----------------------------
// Read pointer & write pointer
// -----------------------------
reg [ADDR_WIDTH-1:0] read_ptr_reg, read_ptr_next;
reg [ADDR_WIDTH-1:0] write_ptr_reg, write_ptr_next;
wire [ADDR_WIDTH-1:0] read_ptr_incre = (read_ptr_reg == FIFO_DEPTH-1) ? 0 :
  read_ptr_reg + 1;
wire [ADDR_WIDTH-1:0] write_ptr_incre = (write_ptr_reg == FIFO_DEPTH-1) ? 0 :
  write_ptr_reg + 1;

// -----------------
// status registers
// -----------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_ptr_reg    <= 0;
    write_ptr_reg   <= 0;
    fifo_full_reg   <= 1'b0;
    fifo_empty_reg  <= 1'b1;
  end else begin
    read_ptr_reg    <= read_ptr_next;
    write_ptr_reg   <= write_ptr_next;
    fifo_full_reg   <= fifo_full_next;
    fifo_empty_reg  <= fifo_empty_next;
  end
end
assign fifo_empty = fifo_empty_reg;
assign fifo_full  = fifo_full_reg;

// -----------
// Write path
// -----------
always @ (posedge clk) begin
  if (write_en && ~fifo_full_reg) begin
    fifo_array[write_ptr_reg] <= write_data;
  end
  // synopsys translate_off
  else if (write_en && fifo_full_reg) begin
    $display("[ERROR]: @%t: %m FIFO overflow!", $time);
  end
  // synopsys translate_on
end

// -------------------------------
// Read path (combinational read)
// -------------------------------
assign read_data = (~fifo_empty_reg) ? fifo_array[read_ptr_reg] : 0;

// -----------------------
// Next logic computation
// -----------------------
always @ (*) begin
  // default: hold the original values
  read_ptr_next   = read_ptr_reg;
  write_ptr_next  = write_ptr_reg;
  fifo_full_next  = fifo_full_reg;
  fifo_empty_next = fifo_empty_reg;

  case ({read_en, write_en})
    2'b00: begin
      // no operation
    end
    2'b01: begin
      // write operation
      if (~fifo_full_reg) begin
        write_ptr_next    = write_ptr_incre;
        fifo_empty_next   = 1'b0;
        if (write_ptr_incre == read_ptr_reg) begin
          fifo_full_next  = 1'b1;
        end
      end
    end
    2'b10: begin
      // read operation
      if (~fifo_empty_reg) begin
        read_ptr_next     = read_ptr_incre;
        fifo_full_next    = 1'b0;
        if (read_ptr_incre == write_ptr_reg) begin
          fifo_empty_next = 1'b1;
        end
      end
    end
    2'b11: begin
      // read + write operation
      read_ptr_next       = read_ptr_incre;
      write_ptr_next      = write_ptr_incre;
    end
  endcase
end

end // FIFO_DEPTH > 1

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
