// =============================================================================
// Filename: router.vh
//
// This file exports the router related microarchitecture parameters.
// =============================================================================

`ifndef __ROUTER_VH__
`define __ROUTER_VH__

// ----------------------------------------------
// Port width definition of the quadtree router
// ----------------------------------------------
// 3 level quadtree router
`define LEVEL_ROOT      0
`define LEVEL_INTERNAL  1
`define LEVEL_LEAF      2
// 5 directions
`define DIRECTION       5
`define DIR_NW          0
`define DIR_NE          1
`define DIR_SE          2
`define DIR_SW          3
`define DIR_LOCAL       4
`define DIR_NIL         5
// Routing packet
`define ROUTER_INFO_WIDTH 4
`define ROUTER_ADDR_WIDTH 16
`define ROUTER_DATA_WIDTH 16
`define ROUTER_WIDTH (`ROUTER_INFO_WIDTH+`ROUTER_ADDR_WIDTH+`ROUTER_DATA_WIDTH)
`define RouterBus `ROUTER_WIDTH-1:0
// Routing infomation
`define ROUTER_INFO_CONFIG  4'd0  // configuration packet
`define ROUTER_INFO_CALC 4'd1     // calculation packet
`define ROUTER_INFO_BROADCAST 4'd2// broadcast packet
`define ROUTER_INFO_FIN_BROADCAST 4'd3  // finish broadcast
// Router FIFO depth
`define ROUTER_FIFO_DEPTH 4
// Credit count width (log2(ROUTER_FIFO_DEPTH)+1)
`define CREDIT_CNT_WIDTH 3

`endif