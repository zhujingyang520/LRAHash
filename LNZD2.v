// ==========================================
// Basic Module for building the 2-bit LNZD
// ==========================================

module LNZD2 (
  input wire  [1:0]               data_in,      // input data
  output reg                      position,     // position of nonzero element
  output wire                     valid         // valid for nonzero elements
);

// position: the first nonzero element's position
always @ (*) begin
  case (data_in)
    2'b01, 2'b11: begin
      position  = 1'b0;
    end
    2'b10: begin
      position  = 1'b1;
    end
    default: begin
      position  = 1'b0;
    end
  endcase
end

// valid: asserts when any data input is nonzero
assign valid = data_in[0] | data_in[1];

endmodule


