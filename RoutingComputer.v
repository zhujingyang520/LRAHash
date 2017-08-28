// =============================================================================
// Module name: RoutingComputer
//
// This module exports the routing computer to determine the routing port of the
// quadtree router.
// =============================================================================

`include "router.vh"

module RoutingComputer #(
  parameter   level               = `LEVEL_ROOT   // level of the router
) (
  input wire  [`DIR_WIDTH-1:0]    direction,      // input direction
  input wire                      rc_en,          // routing enable
  input wire  [`ROUTER_INFO_WIDTH-1:0]
                                  route_info,     // routing info
  input wire  [`ROUTER_ADDR_WIDTH-1:0]
                                  route_addr,     // routing address

  output reg  [`DIRECTION-1:0]    route_port      // direction to be routed
);

generate
if (level == `LEVEL_ROOT) begin: gen_root_rc
  always @ (*) begin
    // route to 0 by default
    route_port          = 5'b0;
    if (direction == `DIR_LOCAL) begin
      if ((rc_en && route_info == `ROUTER_INFO_CONFIG) ||
          (rc_en && route_info == `ROUTER_INFO_READ)) begin
        // send the data to the specified PE, hardcode the root index
        case(route_addr[15:14])
          2'b00: begin
            route_port  = 5'b00001;
          end
          2'b01: begin
            route_port  = 5'b00010;
          end
          2'b10: begin
            route_port  = 5'b00100;
          end
          2'b11: begin
            route_port  = 5'b01000;
          end
        endcase
      end
      else if (rc_en && route_info == `ROUTER_INFO_CALC) begin
        // broadcast to all 4 children when start calculation
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // broadcast to all 4 children when finish broadcast
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // broadcast to all 4 children when finish computation
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_UV) begin
        // broadcast to all 4 children for LOCAL direction
        route_port      = 5'b01111;
      end
    end else begin  // nonlocal direction
      if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcast to all 4 children when doing calculation
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // send to the root node
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // send to the root node
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_READ) begin
        // send to the root node
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_UV) begin
        // send to the root node
        route_port      = 5'b10000;
      end
    end
  end
end
else if (level == `LEVEL_INTERNAL) begin: gen_internal_rc
  always @ (*) begin
    // set route port to 0 by default
    route_port          = 5'b0;
    if (direction == `DIR_LOCAL) begin
      if ((rc_en && route_info == `ROUTER_INFO_CONFIG) ||
          (rc_en && route_info == `ROUTER_INFO_READ)) begin
        // send the data to the specified direction, hardcode the index
        // selection
        case (route_addr[13:12])
          2'b00: begin
            route_port  = 5'b00001;
          end
          2'b01: begin
            route_port  = 5'b00010;
          end
          2'b10: begin
            route_port  = 5'b00100;
          end
          2'b11: begin
            route_port  = 5'b01000;
          end
        endcase
      end
      else if (rc_en && route_info == `ROUTER_INFO_CALC) begin
        // broadcast start calculation to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcst activation to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // broadcast finish broadcast to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // broadcast finish computation to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_UV) begin
        // broadcast to 4 children for UV computation
        route_port      = 5'b01111;
      end
    end else begin    // nonlocal port
      if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // route to the root during broadcast for the nonlocal port
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // route to the root during finish broadcast
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // route to the root during finish computation
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_READ) begin
        // route to the root for reading activations
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_UV) begin
        // route to the root node for UV computation
        route_port      = 5'b10000;
      end
    end
  end
end
else if (level == `LEVEL_LEAF) begin: gen_internal_rc
  always @ (*) begin
    // route to 0 by default
    route_port          = 5'b0;
    if (direction == `DIR_LOCAL) begin
      if ((rc_en && route_info == `ROUTER_INFO_CONFIG) ||
          (rc_en && route_info == `ROUTER_INFO_READ)) begin
        // send the data to the specified PE, hardcode the leaf index
        case (route_addr[11:10])
          2'b00: begin
            route_port  = 5'b00001;
          end
          2'b01: begin
            route_port  = 5'b00010;
          end
          2'b10: begin
            route_port  = 5'b00100;
          end
          2'b11: begin
            route_port  = 5'b01000;
          end
        endcase
      end
      else if (rc_en && route_info == `ROUTER_INFO_CALC) begin
        // broadcast start calculation to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcst activation to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // broadcast finish broadcast to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // broadcast finish computation to 4 children
        route_port      = 5'b01111;
      end
      else if (rc_en && route_info == `ROUTER_INFO_UV) begin
        // broadcast to 4 children for UV
        route_port      = 5'b01111;
      end
    end else begin    // nonlocal port
      if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // route to the root during broadcast for the nonlocal port
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // route to the root during finish broadcast
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // route to the root during finish computation
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_READ) begin
        // route to the root for reading activations
        route_port      = 5'b10000;
      end
      else if (rc_en && route_info == `ROUTER_INFO_UV) begin
        // route to the root node for UV computation
        route_port      = 5'b10000;
      end
    end
  end
end
else begin: gen_undef
  // synopsys translate_off
  initial begin
    $display("[ERROR]: unexpected DIR: %d", direction);
    $finish;
  end
  // synopsys translate_on
end
endgenerate

endmodule
