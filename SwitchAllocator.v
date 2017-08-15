// =============================================================================
// Module name: SwitchAllocator
//
// This file exports the module `SwitchAllocator`. The arbiter is simplified
// into always grant the local port's request. The remaining 4 directions are
// allocated based on the associated address.
// =============================================================================

`include "router.vh"

module SwitchAllocator (
  input wire  [`DIRECTION-1:0]      sa_request,           // SA request
  input wire  [`DIRECTION*`ROUTER_INFO_WIDTH-1:0]
                                    sa_info,              // SA info
  input wire  [`DIRECTION*`ROUTER_ADDR_WIDTH-1:0]
                                    sa_addr,              // SA address
  output reg  [`DIRECTION-1:0]      sa_grant              // SA grant
);

// Always grant the local port request
// Corner case: the contention of FIN_BROADCAST with BROADCAST
// unpack the 5 direction info
wire [`ROUTER_INFO_WIDTH-1:0] sa_info_dir [`DIRECTION-1:0];
assign sa_info_dir[`DIR_NW] = sa_info[`DIR_NW*`ROUTER_INFO_WIDTH +:
                                      `ROUTER_INFO_WIDTH];
assign sa_info_dir[`DIR_NE] = sa_info[`DIR_NE*`ROUTER_INFO_WIDTH +:
                                      `ROUTER_INFO_WIDTH];
assign sa_info_dir[`DIR_SE] = sa_info[`DIR_SE*`ROUTER_INFO_WIDTH +:
                                      `ROUTER_INFO_WIDTH];
assign sa_info_dir[`DIR_SW] = sa_info[`DIR_SW*`ROUTER_INFO_WIDTH +:
                                      `ROUTER_INFO_WIDTH];
assign sa_info_dir[`DIR_LOCAL] = sa_info[`DIR_LOCAL*`ROUTER_INFO_WIDTH +:
                                      `ROUTER_INFO_WIDTH];

always @ (*) begin
  sa_grant[`DIR_LOCAL] = sa_request[`DIR_LOCAL];
  // corner case
  if (sa_request[`DIR_LOCAL] && sa_info_dir[`DIR_LOCAL] ==
    `ROUTER_INFO_FIN_BROADCAST) begin
    if ( (sa_request[`DIR_NW] && sa_info_dir[`DIR_NW] == `ROUTER_INFO_BROADCAST)
      || (sa_request[`DIR_NE] && sa_info_dir[`DIR_NE] == `ROUTER_INFO_BROADCAST)
      || (sa_request[`DIR_SE] && sa_info_dir[`DIR_SE] == `ROUTER_INFO_BROADCAST)
      || (sa_request[`DIR_SW] && sa_info_dir[`DIR_SW] == `ROUTER_INFO_BROADCAST)
      ) begin
      sa_grant[`DIR_LOCAL] = 1'b0;
    end
  end
end

// For non-local port, we grant the port with the lowest address
// We use radix-2 comparator
reg [2:0] dir_level_0_0, dir_level_0_1, dir_level_1;

// unpack the 4 directions address
wire [`ROUTER_ADDR_WIDTH-1:0] sa_addr_dir [`DIRECTION-2:0];
assign sa_addr_dir[`DIR_NW] = sa_addr[`DIR_NW*`ROUTER_ADDR_WIDTH +:
                                      `ROUTER_ADDR_WIDTH];
assign sa_addr_dir[`DIR_NE] = sa_addr[`DIR_NE*`ROUTER_ADDR_WIDTH +:
                                      `ROUTER_ADDR_WIDTH];
assign sa_addr_dir[`DIR_SE] = sa_addr[`DIR_SE*`ROUTER_ADDR_WIDTH +:
                                      `ROUTER_ADDR_WIDTH];
assign sa_addr_dir[`DIR_SW] = sa_addr[`DIR_SW*`ROUTER_ADDR_WIDTH +:
                                      `ROUTER_ADDR_WIDTH];

// level 0: NW v.s. NE
always @ (*) begin
  case (sa_request[1:0])
    2'b00: begin
      dir_level_0_0   = `DIR_NIL;
    end
    2'b01: begin
      dir_level_0_0   = `DIR_NW;
    end
    2'b10: begin
      dir_level_0_0   = `DIR_NE;
    end
    2'b11: begin
      if (sa_addr_dir[`DIR_NW] < sa_addr_dir[`DIR_NE]) begin
        dir_level_0_0 = `DIR_NW;
      end else begin
        dir_level_0_0 = `DIR_NE;
      end
    end
  endcase
end

// level 0: SE v.s. SW
always @ (*) begin
  case (sa_request[3:2])
    2'b00: begin
      dir_level_0_1   = `DIR_NIL;
    end
    2'b01: begin
      dir_level_0_1   = `DIR_SE;
    end
    2'b10: begin
      dir_level_0_1   = `DIR_SW;
    end
    2'b11: begin
      if (sa_addr_dir[`DIR_SE] < sa_addr_dir[`DIR_SW]) begin
        dir_level_0_1 = `DIR_SE;
      end else begin
        dir_level_0_1 = `DIR_SW;
      end
    end
  endcase
end

// level 1
always @ (*) begin
  case ({dir_level_0_1, dir_level_0_0})
    {3'd`DIR_NIL, 3'd`DIR_NIL}: begin
      dir_level_1     = `DIR_NIL;
    end
    {3'd`DIR_NIL, 3'd`DIR_NW}, {3'd`DIR_NIL, 3'd`DIR_NE}: begin
      dir_level_1     = dir_level_0_0;
    end
    {3'd`DIR_SE, 3'd`DIR_NIL}, {3'd`DIR_SW, 3'd`DIR_NIL}: begin
      dir_level_1     = dir_level_0_1;
    end
    {3'd`DIR_SE, 3'd`DIR_NW}: begin
      if (sa_addr_dir[`DIR_SE] < sa_addr_dir[`DIR_NW]) begin
        dir_level_1   = `DIR_SE;
      end else begin
        dir_level_1   = `DIR_NW;
      end
    end
    {3'd`DIR_SE, 3'd`DIR_NE}: begin
      if (sa_addr_dir[`DIR_SE] < sa_addr_dir[`DIR_NE]) begin
        dir_level_1   = `DIR_SE;
      end else begin
        dir_level_1   = `DIR_NE;
      end
    end
    {3'd`DIR_SW, 3'd`DIR_NW}: begin
      if (sa_addr_dir[`DIR_SW] < sa_addr_dir[`DIR_NW]) begin
        dir_level_1   = `DIR_SW;
      end else begin
        dir_level_1   = `DIR_NW;
      end
    end
    {3'd`DIR_SW, 3'd`DIR_NE}: begin
      if (sa_addr_dir[`DIR_SW] < sa_addr_dir[`DIR_NE]) begin
        dir_level_1   = `DIR_SW;
      end else begin
        dir_level_1   = `DIR_NE;
      end
    end
    default: begin
      dir_level_1     = `DIR_NIL;
    end
  endcase
end


// ------------------
// grant outputs
// ------------------
always @ (*) begin
  if (dir_level_1 == `DIR_NW) begin
    sa_grant[3:0]     = 4'b0001;
  end else if (dir_level_1 == `DIR_NE) begin
    sa_grant[3:0]     = 4'b0010;
  end else if (dir_level_1 == `DIR_SE) begin
    sa_grant[3:0]     = 4'b0100;
  end else if (dir_level_1 == `DIR_SW) begin
    sa_grant[3:0]     = 4'b1000;
  end else begin
    sa_grant[3:0]     = 4'b0000;
  end
end

endmodule
