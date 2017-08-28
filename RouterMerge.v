// =============================================================================
// Module name: RouterMerge
//
// The module exports the extra merge stage in the quadtree router. It merges
// the V computation results from 4 directions.
// =============================================================================

`include "router.vh"

module RouterMerge (
  input wire    [(`DIRECTION-1)*`ROUTER_WIDTH-1:0]
                                              st_data_in, // switch input data

  output reg                                  merge_en,   // merge enable
  output reg    [`ROUTER_WIDTH-1:0]           merge_data  // merge data
);

genvar g;
// unpack the data into 2D
wire [`ROUTER_WIDTH-1:0] st_data_in_2d [`DIRECTION-2:0];
wire [`ROUTER_INFO_WIDTH-1:0] st_data_info [`DIRECTION-2:0];
wire [`ROUTER_DATA_WIDTH-1:0] st_data_data [`DIRECTION-2:0];
// Merge the packets
reg [`ROUTER_DATA_WIDTH-1:0] merge_result;

generate
for (g = 0; g < `DIRECTION-1; g = g + 1) begin: gen_in_2d
  assign st_data_in_2d[g] = st_data_in[g*`ROUTER_WIDTH +: `ROUTER_WIDTH];
  assign st_data_info[g] = st_data_in_2d[g][35:32];
  assign st_data_data[g] = st_data_in_2d[g][15:0];
end
endgenerate

// --------------------------
// Merge results
// --------------------------
always @ (*) begin
  if (merge_en) begin
    merge_result  = st_data_data[`DIR_NW] + st_data_data[`DIR_NE] +
      st_data_data[`DIR_SW] + st_data_data[`DIR_SE];
  end else begin
    merge_result  = 0;
  end
end

// ------------------------------
// Primary output: merge enable
// ------------------------------
always @ (*) begin
  if ((st_data_info[`DIR_NW] == `ROUTER_INFO_UV) &&
      (st_data_info[`DIR_NE] == `ROUTER_INFO_UV) &&
      (st_data_info[`DIR_SW] == `ROUTER_INFO_UV) &&
      (st_data_info[`DIR_SE] == `ROUTER_INFO_UV)) begin
    merge_en    = 1'b1;
  end else begin
    merge_en    = 1'b0;
  end
end

// ------------------------------
// Primary output: merge data
// ------------------------------
always @ (*) begin
  if (merge_en) begin
    merge_data[35:32] = `ROUTER_INFO_UV;
    merge_data[31:16] = st_data_in_2d[`DIR_NW][31:16];
    merge_data[15:0]  = merge_result;
  end else begin
    merge_data        = 0;
  end
end

endmodule
