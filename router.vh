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
`define DIR_WIDTH       3
// Routing packet
`define ROUTER_INFO_WIDTH 4
`define ROUTER_ADDR_WIDTH 16
`define ROUTER_DATA_WIDTH 16
`define ROUTER_WIDTH (`ROUTER_INFO_WIDTH+`ROUTER_ADDR_WIDTH+`ROUTER_DATA_WIDTH)
`define RouterBus `ROUTER_WIDTH-1:0
// Routing infomation
`define ROUTER_INFO_CONFIG  4'd0        // configuration packet
`define ROUTER_INFO_CALC 4'd1           // calculation packet
`define ROUTER_INFO_UV 4'd2             // UV path
`define ROUTER_INFO_BROADCAST 4'd3      // broadcast packet
`define ROUTER_INFO_FIN_BROADCAST 4'd4  // finish broadcast
`define ROUTER_INFO_FIN_COMP 4'd5       // finish computation
`define ROUTER_INFO_READ 4'd6           // read register files
// Router FIFO depth
`define ROUTER_FIFO_DEPTH 4
// Router FIFO split (resolve the bubble caused by back-to-back packet stall)
`define ROUTER_FIFO_SPLIT 2
// Total FIFO depth per port
`define TOT_FIFO_DEPTH `ROUTER_FIFO_DEPTH*`ROUTER_FIFO_SPLIT
// Credit count width (log2(TOT_FIFO_DEPTH)+1)
`define CREDIT_CNT_WIDTH 4

`endif
