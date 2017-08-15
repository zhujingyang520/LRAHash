// =============================================================================
// Module name: OutputUnit
//
// The output unit of the Quadtree Router. It contains the output registers of
// the router and the associated credit count of the downstreaming port.
// =============================================================================

`include "router.vh"
`include "pe.vh"

module OutputUnit #(
  parameter   level               = `LEVEL_ROOT,  // router level
  parameter   direction           = `DIR_LOCAL    // output unit's direction
) (
  input wire                      clk,            // system clock
  input wire                      rst,            // system reset (active high)

  // credit datapath
  input wire                      credit_decre,   // decrement credit
  input wire                      credit_incre,   // increment credit
  output wire                     credit_avail,   // credit available (> 0)

  // data path
  input wire                      out_unit_en,    // output unit update enable
  input wire  [`ROUTER_WIDTH-1:0] st_data_out,    // ST data output
  output reg  [`ROUTER_WIDTH-1:0] out_data,       // output unit data output
  output reg                      out_data_valid  // output unit data valid
);

// -------------------
// Datapath registers
// -------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    out_data_valid  <= 1'b0;
    out_data        <= 0;
  end else if (out_unit_en) begin
    out_data_valid  <= 1'b1;
    out_data        <= st_data_out;
  end else begin
    out_data_valid  <= 1'b0;
    out_data        <= 0;
  end
end

// -------------------------------------------
// Credit count for the downstreaming buffer
// -------------------------------------------
// Corner case: Nonlocal port @ leaf router has the credit count of
// PE_QUEUE_DEPTH
generate
if (level == `LEVEL_LEAF && direction != `DIR_LOCAL)
begin: gen_output_unit_leaf_nonlocal

reg [`PE_QUEUE_DEPTH_WIDTH-1:0] credit_count_reg;
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    credit_count_reg      <= `PE_QUEUE_DEPTH;
  end else begin
    case({credit_decre, credit_incre})
      2'b00, 2'b11: begin
        // unchanged
        credit_count_reg  <= credit_count_reg;
      end
      2'b01: begin
        credit_count_reg  <= credit_count_reg + 1;
      end
      2'b10: begin
        credit_count_reg  <= credit_count_reg - 1;
      end
    endcase
  end
end
assign credit_avail = (credit_count_reg > 0);

end // gen_output_unit_leaf_nonlocal
else begin: gen_output_unit_non_leaf_nonlocal

reg [`CREDIT_CNT_WIDTH-1:0] credit_count_reg;
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    credit_count_reg      <= `TOT_FIFO_DEPTH;
  end else begin
    case({credit_decre, credit_incre})
      2'b00, 2'b11: begin
        // unchanged
        credit_count_reg  <= credit_count_reg;
      end
      2'b01: begin
        credit_count_reg  <= credit_count_reg + 1;
      end
      2'b10: begin
        credit_count_reg  <= credit_count_reg - 1;
      end
    endcase
  end
end
assign credit_avail = (credit_count_reg > 0);

end // else: gen_output_unit_non_leaf_nonlocal
endgenerate


endmodule
