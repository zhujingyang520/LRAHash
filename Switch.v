// =============================================================================
// Module name: Switch
//
// This file exports the module `Switch`, which transfers/broadcast the input
// data port to the output data port.
// =============================================================================

`include "router.vh"

module Switch (
  input wire  [`DIRECTION*`ROUTER_WIDTH-1:0]  st_data_in,   // switch input data
  input wire  [`DIRECTION*`DIRECTION-1:0]     st_ctrl_in,   // switch control

  output reg  [`DIRECTION-1:0]                out_unit_en,  // output unit enable
  output reg  [`DIRECTION*`ROUTER_WIDTH-1:0]  st_data_out   // switch output
);

// unpack the 1D input data to 2D
wire [`ROUTER_WIDTH-1:0] st_data_in_2d [`DIRECTION-1:0];
wire [`DIRECTION-1:0] st_ctrl_in_2d [`DIRECTION-1:0];

genvar g;
generate
for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_in_2d
  assign st_data_in_2d[g] = st_data_in[g*`ROUTER_WIDTH +: `ROUTER_WIDTH];
  assign st_ctrl_in_2d[g] = st_ctrl_in[g*`DIRECTION +: `DIRECTION];
end
endgenerate

// Local port output
always @ (*) begin
  case ({st_ctrl_in_2d[`DIR_NW][`DIR_LOCAL], st_ctrl_in_2d[`DIR_NE][`DIR_LOCAL],
         st_ctrl_in_2d[`DIR_SE][`DIR_LOCAL], st_ctrl_in_2d[`DIR_SW][`DIR_LOCAL]})
    4'b1000: begin
      st_data_out[`DIR_LOCAL*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NW];
      out_unit_en[`DIR_LOCAL] = 1'b1;
    end
    4'b0100: begin
      st_data_out[`DIR_LOCAL*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NE];
      out_unit_en[`DIR_LOCAL] = 1'b1;
    end
    4'b0010: begin
      st_data_out[`DIR_LOCAL*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SE];
      out_unit_en[`DIR_LOCAL] = 1'b1;
    end
    4'b0001: begin
      st_data_out[`DIR_LOCAL*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SW];
      out_unit_en[`DIR_LOCAL] = 1'b1;
    end
    default: begin
      st_data_out[`DIR_LOCAL*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        0;
      out_unit_en[`DIR_LOCAL] = 1'b0;
    end
  endcase
end

// NW output port
always @ (*) begin
  case ({st_ctrl_in_2d[`DIR_LOCAL][`DIR_NW], st_ctrl_in_2d[`DIR_NW][`DIR_NW],
         st_ctrl_in_2d[`DIR_NE][`DIR_NW], st_ctrl_in_2d[`DIR_SE][`DIR_NW],
         st_ctrl_in_2d[`DIR_SW][`DIR_NW]})
    5'b10000: begin
      st_data_out[`DIR_NW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_LOCAL];
      out_unit_en[`DIR_NW] = 1'b1;
    end
    5'b01000: begin
      st_data_out[`DIR_NW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NW];
      out_unit_en[`DIR_NW] = 1'b1;
    end
    5'b00100: begin
      st_data_out[`DIR_NW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NE];
      out_unit_en[`DIR_NW] = 1'b1;
    end
    5'b00010: begin
      st_data_out[`DIR_NW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SE];
      out_unit_en[`DIR_NW] = 1'b1;
    end
    5'b00001: begin
      st_data_out[`DIR_NW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SW];
      out_unit_en[`DIR_NW] = 1'b1;
    end
    default: begin
      st_data_out[`DIR_NW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        0;
      out_unit_en[`DIR_NW] = 1'b0;
    end
  endcase
end

// NE output port
always @ (*) begin
  case ({st_ctrl_in_2d[`DIR_LOCAL][`DIR_NE], st_ctrl_in_2d[`DIR_NW][`DIR_NE],
         st_ctrl_in_2d[`DIR_NE][`DIR_NE], st_ctrl_in_2d[`DIR_SE][`DIR_NE],
         st_ctrl_in_2d[`DIR_SW][`DIR_NE]})
    5'b10000: begin
      st_data_out[`DIR_NE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_LOCAL];
      out_unit_en[`DIR_NE] = 1'b1;
    end
    5'b01000: begin
      st_data_out[`DIR_NE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NW];
      out_unit_en[`DIR_NE] = 1'b1;
    end
    5'b00100: begin
      st_data_out[`DIR_NE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NE];
      out_unit_en[`DIR_NE] = 1'b1;
    end
    5'b00010: begin
      st_data_out[`DIR_NE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SE];
      out_unit_en[`DIR_NE] = 1'b1;
    end
    5'b00001: begin
      st_data_out[`DIR_NE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SW];
      out_unit_en[`DIR_NE] = 1'b1;
    end
    default: begin
      st_data_out[`DIR_NE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        0;
      out_unit_en[`DIR_NE] = 1'b0;
    end
  endcase
end

// SE output port
always @ (*) begin
  case ({st_ctrl_in_2d[`DIR_LOCAL][`DIR_SE], st_ctrl_in_2d[`DIR_NW][`DIR_SE],
         st_ctrl_in_2d[`DIR_NE][`DIR_SE], st_ctrl_in_2d[`DIR_SE][`DIR_SE],
         st_ctrl_in_2d[`DIR_SW][`DIR_SE]})
    5'b10000: begin
      st_data_out[`DIR_SE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_LOCAL];
      out_unit_en[`DIR_SE] = 1'b1;
    end
    5'b01000: begin
      st_data_out[`DIR_SE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NW];
      out_unit_en[`DIR_SE] = 1'b1;
    end
    5'b00100: begin
      st_data_out[`DIR_SE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NE];
      out_unit_en[`DIR_SE] = 1'b1;
    end
    5'b00010: begin
      st_data_out[`DIR_SE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SE];
      out_unit_en[`DIR_SE] = 1'b1;
    end
    5'b00001: begin
      st_data_out[`DIR_SE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SW];
      out_unit_en[`DIR_SE] = 1'b1;
    end
    default: begin
      st_data_out[`DIR_SE*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        0;
      out_unit_en[`DIR_SE] = 1'b0;
    end
  endcase
end

// SW output port
always @ (*) begin
  case ({st_ctrl_in_2d[`DIR_LOCAL][`DIR_SW], st_ctrl_in_2d[`DIR_NW][`DIR_SW],
         st_ctrl_in_2d[`DIR_NE][`DIR_SW], st_ctrl_in_2d[`DIR_SE][`DIR_SW],
         st_ctrl_in_2d[`DIR_SW][`DIR_SW]})
    5'b10000: begin
      st_data_out[`DIR_SW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_LOCAL];
      out_unit_en[`DIR_SW] = 1'b1;
    end
    5'b01000: begin
      st_data_out[`DIR_SW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NW];
      out_unit_en[`DIR_SW] = 1'b1;
    end
    5'b00100: begin
      st_data_out[`DIR_SW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_NE];
      out_unit_en[`DIR_SW] = 1'b1;
    end
    5'b00010: begin
      st_data_out[`DIR_SW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SE];
      out_unit_en[`DIR_SW] = 1'b1;
    end
    5'b00001: begin
      st_data_out[`DIR_SW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        st_data_in_2d[`DIR_SW];
      out_unit_en[`DIR_SW] = 1'b1;
    end
    default: begin
      st_data_out[`DIR_SW*`ROUTER_WIDTH +: `ROUTER_WIDTH] =
        0;
      out_unit_en[`DIR_SW] = 1'b0;
    end
  endcase
end

endmodule
