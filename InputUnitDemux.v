// =============================================================================
// Module name: InputUnitDemux
//
// The module exports the DEMUX stage of the input unit in the router. There are
// multiple splits (banks) of FIFO in the router. The input data will be
// selectively pushed into the bank has less number of entries.
// =============================================================================

`include "router.vh"

module InputUnitDemux (
  input wire                            clk,            // system clock
  input wire                            rst,            // system reset
  input wire                            in_data_valid,  // input data valid
  input wire  [`ROUTER_FIFO_SPLIT-1:0]  fifo_read_en,   // fifo read enable
  output reg  [`ROUTER_FIFO_SPLIT-1:0]  fifo_write_en   // fifo write enable
);

// Here ONLY support up to 2 banks
generate
if (`ROUTER_FIFO_SPLIT == 1) begin: gen_fifo_split_1
  always @(*) begin
    fifo_write_en = in_data_valid;
  end
end
else if (`ROUTER_FIFO_SPLIT == 2) begin: gen_fifo_split_2
  // Maintain the utilization of 2 splits, and always push the packet into the
  // shallow one
  // counter of split 0 & 1
  reg [clog2(`ROUTER_FIFO_DEPTH):0] fifo_cnt_0, fifo_cnt_1;
  // track the count no. at each split
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      fifo_cnt_0      <= 0;
    end else begin
      case({fifo_read_en[0], fifo_write_en[0]})
        2'b10: begin
          fifo_cnt_0  <= fifo_cnt_0 - 1;
        end
        2'b01: begin
          fifo_cnt_0  <= fifo_cnt_0 + 1;
        end
      endcase
    end
  end
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      fifo_cnt_1      <= 0;
    end else begin
      case ({fifo_read_en[1], fifo_write_en[1]})
        2'b10: begin
          fifo_cnt_1  <= fifo_cnt_1 - 1;
        end
        2'b01: begin
          fifo_cnt_1  <= fifo_cnt_1 + 1;
        end
      endcase
    end
  end

  // Always write to the split with the less number of entries
  always @ (*) begin
    if (in_data_valid) begin
      if (fifo_cnt_1 < fifo_cnt_0) begin
        fifo_write_en = 2'b10;
      end else begin
        fifo_write_en = 2'b01;
      end
    end else begin
      fifo_write_en   = 2'b00;
    end
  end
end
else begin: gen_fifo_split_unsupported
  // synopsys translate_off
  initial begin
    $display("[ERROR]: unsupported FIFO split");
  end
  // synopsys translate_on
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
