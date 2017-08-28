// =============================================================================
// Module name: InputUnitMux
//
// The module exports the input unit MUX stage, which select the corresponding
// datapath from the splited buffers.
// =============================================================================

`include "router.vh"

module InputUnitMux (
  // Credit
  input wire  [`ROUTER_FIFO_SPLIT-1:0]    in_credit_split,  // upstream credit
  input wire  [`ROUTER_FIFO_SPLIT*
                `DIRECTION-1:0]           out_credit_decre_split,
  output wire                             in_credit,        // upstream credit
  output wire [`DIRECTION-1:0]            out_credit_decre, // downstream credit

  // Routing Computation
  input wire  [`ROUTER_FIFO_SPLIT-1:0]    rc_grant_split,   // RC grant
  input wire  [`ROUTER_FIFO_SPLIT*
                `ROUTER_INFO_WIDTH-1:0]   route_info_split, // routing info
  input wire  [`ROUTER_FIFO_SPLIT*
                `ROUTER_ADDR_WIDTH-1:0]   route_addr_split, // routing addr

  output wire                             rc_en,            // RC enable
  output wire [`ROUTER_INFO_WIDTH-1:0]    route_info,       // routing info
  output wire [`ROUTER_ADDR_WIDTH-1:0]    route_addr,       // routing addr

  // Switch Allocation
  input wire  [`ROUTER_FIFO_SPLIT-1:0]    sa_grant_split,   // SA grant
  input wire  [`ROUTER_FIFO_SPLIT*
                `ROUTER_INFO_WIDTH-1:0]   sa_info_split,    // SA info
  input wire  [`ROUTER_FIFO_SPLIT*
                `ROUTER_ADDR_WIDTH-1:0]   sa_addr_split,    // SA address

  output wire                             sa_request,       // SA request
  output wire [`ROUTER_INFO_WIDTH-1:0]    sa_info,          // SA info
  output wire [`ROUTER_ADDR_WIDTH-1:0]    sa_addr,          // SA address

  // Switch Traversal
  input wire  [`ROUTER_FIFO_SPLIT*
                `ROUTER_WIDTH-1:0]        st_data_in_split, // ST data
  input wire  [`ROUTER_FIFO_SPLIT*
                `DIRECTION-1:0]           st_ctrl_in_split, // ST control
  output wire [`ROUTER_WIDTH-1:0]         st_data_in,       // ST data
  output wire [`DIRECTION-1:0]            st_ctrl_in        // ST control
);

genvar g, h;

// --------------------------
// Credit
// --------------------------
wire [`ROUTER_FIFO_SPLIT-1:0] out_credit_decre_split_2d [`DIRECTION-1:0];
// upstreaming credit
assign in_credit = |in_credit_split;
// downstreaming credit
generate
for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_out_credit_decre_2d_g
  for (h = 0; h < `ROUTER_FIFO_SPLIT; h = h + 1) begin: gen_out_credit_decre_2d_h
    assign out_credit_decre_split_2d[g][h] =
      out_credit_decre_split[h*`DIRECTION+g];
  end
end

for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_out_credit_decre
  assign out_credit_decre[g] = |out_credit_decre_split_2d[g];
end
endgenerate

// --------------------------
// Routing Computation
// --------------------------
wire [`ROUTER_FIFO_SPLIT-1:0] route_info_split_mask [`ROUTER_INFO_WIDTH-1:0];
wire [`ROUTER_FIFO_SPLIT-1:0] route_addr_split_mask [`ROUTER_ADDR_WIDTH-1:0];
assign rc_en = |rc_grant_split;
// Routing info
generate
for (g = 0; g < `ROUTER_INFO_WIDTH; g = g + 1) begin: gen_route_info_mask_g
  for (h = 0; h < `ROUTER_FIFO_SPLIT; h = h + 1) begin: gen_route_info_mask_h
    assign route_info_split_mask[g][h] = rc_grant_split[h] &
      route_info_split[h*`ROUTER_INFO_WIDTH+g];
  end
end
for (g = 0; g < `ROUTER_INFO_WIDTH; g = g + 1) begin: gen_route_info
  assign route_info[g] = |route_info_split_mask[g];
end
endgenerate
// Routing addr
generate
for (g = 0; g < `ROUTER_ADDR_WIDTH; g = g + 1) begin: gen_route_addr_mask_g
  for (h = 0; h < `ROUTER_FIFO_SPLIT; h = h + 1) begin: gen_route_addr_mask_h
    assign route_addr_split_mask[g][h] = rc_grant_split[h] &
      route_addr_split[h*`ROUTER_ADDR_WIDTH+g];
  end
end
for (g = 0; g < `ROUTER_ADDR_WIDTH; g = g + 1) begin: gen_route_addr
  assign route_addr[g] = |route_addr_split_mask[g];
end
endgenerate

// --------------------------
// Switch Allocation
// --------------------------
wire [`ROUTER_FIFO_SPLIT-1:0] sa_info_split_mask [`ROUTER_INFO_WIDTH-1:0];
wire [`ROUTER_FIFO_SPLIT-1:0] sa_addr_split_mask [`ROUTER_ADDR_WIDTH-1:0];
assign sa_request = |sa_grant_split;
// SA info (used for SA)
generate
for (g = 0; g < `ROUTER_INFO_WIDTH; g = g + 1) begin: gen_sa_info_mask_g
  for (h = 0; h < `ROUTER_FIFO_SPLIT; h = h + 1) begin: gen_sa_info_mask_h
    assign sa_info_split_mask[g][h] = sa_grant_split[h] &
      sa_info_split[h*`ROUTER_INFO_WIDTH+g];
  end
end

for (g = 0; g < `ROUTER_INFO_WIDTH; g = g + 1) begin: gen_sa_info
  assign sa_info[g] = |sa_info_split_mask[g];
end
endgenerate
// SA address (used for SA)
generate
for (g = 0; g < `ROUTER_ADDR_WIDTH; g = g + 1) begin: gen_sa_addr_mask_g
  for (h = 0; h < `ROUTER_FIFO_SPLIT; h = h + 1) begin: gen_sa_addr_mask_h
    assign sa_addr_split_mask[g][h] = sa_grant_split[h] &
      sa_addr_split[h*`ROUTER_ADDR_WIDTH+g];
  end
end

for (g = 0; g < `ROUTER_ADDR_WIDTH; g = g + 1) begin: gen_sa_addr
  assign sa_addr[g] = |sa_addr_split_mask[g];
end
endgenerate

// -------------------------
// Switch Traversal
// -------------------------
wire [`ROUTER_FIFO_SPLIT-1:0] st_data_in_2d [`ROUTER_WIDTH-1:0];
wire [`ROUTER_FIFO_SPLIT-1:0] st_ctrl_in_2d [`DIRECTION-1:0];
// ST data
generate
for (g = 0; g < `ROUTER_WIDTH; g = g + 1) begin: gen_st_data_in_2d_g
  for (h = 0; h < `ROUTER_FIFO_SPLIT; h = h + 1) begin: gen_st_data_in_2d_h
    assign st_data_in_2d[g][h] = st_data_in_split[h*`ROUTER_WIDTH+g];
  end
end
for (g = 0; g < `ROUTER_WIDTH; g = g + 1) begin: geb_st_data_in
  assign st_data_in[g] = |st_data_in_2d[g];
end
endgenerate
// ST control
generate
for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_st_ctrl_in_2d_g
  for (h = 0; h < `ROUTER_FIFO_SPLIT; h = h + 1) begin: gen_st_ctrl_in_2d_h
    assign st_ctrl_in_2d[g][h] = st_ctrl_in_split[h*`DIRECTION+g];
  end
end
for (g = 0; g < `DIRECTION; g = g + 1) begin: gen_st_ctrl_in
  assign st_ctrl_in[g] = |st_ctrl_in_2d[g];
end
endgenerate

endmodule
