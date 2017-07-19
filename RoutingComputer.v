// =============================================================================
// Module name: RoutingComputer
//
// This module exports the routing computer to determine the routing port of the
// quadtree router.
// =============================================================================

`include "router.vh"

module RoutingComputer #(
  parameter   level               = `LEVEL_ROOT,  // level of the router
  parameter   direction           = `DIR_LOCAL    // direction of the RC
) (
  input wire                      rc_en,          // routing enable
  input wire  [`ROUTER_INFO_WIDTH-1:0]
                                  route_info,     // routing info
  input wire  [`ROUTER_ADDR_WIDTH-1:0]
                                  route_addr,     // routing address

  output reg  [`DIRECTION-1:0]    route_port      // direction to be routed
);

generate
if (direction == `DIR_LOCAL) begin: gen_local_rc  // local port RC
  if (level == `LEVEL_ROOT) begin: gen_root_rc
    always @ (*) begin
      if (rc_en && route_info == `ROUTER_INFO_CONFIG) begin
        // send configuration data to a specified PE
        // hardcode the root index selection
        case (route_addr[15:14])
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
          default: begin
            route_port  = 5'b00000;
          end
        endcase
      end else if (rc_en && route_info == `ROUTER_INFO_CALC) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else begin
        route_port      = 0;
      end
    end
  end
  else if (level == `LEVEL_INTERNAL) begin: gen_internal_rc
    always @ (*) begin
      if (rc_en && route_info == `ROUTER_INFO_CONFIG) begin
        // send the configruation data to a specified PE
        // hardcode the internal index selection
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
      end else if (rc_en && route_info == `ROUTER_INFO_CALC) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else begin
        route_port      = 0;
      end
    end
  end
  else if (level == `LEVEL_LEAF) begin: gen_leaf_rc
    always @ (*) begin
      if (rc_en && route_info == `ROUTER_INFO_CONFIG) begin
        // send the configuration data to a specified PE
        // hardcode the leaf index selection
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
      end else if (rc_en && route_info == `ROUTER_INFO_CALC) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // broadcast to all 4 children
        route_port      = 5'b01111;
      end else begin
        route_port      = 0;
      end
    end
  end
end
else begin: gen_nonlocal_rc
  if (level == `LEVEL_ROOT) begin: gen_root_rc
    always @ (*) begin
      if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcast to all PEs, distribute to all 4 children
        route_port        = 5'b01111;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // finish the broadcast, send to the root controller
        route_port        = 5'b10000;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // finish the computation, send to the root controller
        route_port        = 5'b10000;
      end else begin
        route_port        = 5'b0;
      end
    end
  end
  else if (level == `LEVEL_INTERNAL) begin: gen_internal_rc
    always @ (*) begin
      if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcast to all PEs, first go up to the root node
        route_port        = 5'b10000;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // finish the broadcast, send to the root controller
        route_port        = 5'b10000;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // finish the computation, send to the root controller
        route_port        = 5'b10000;
      end else begin
        route_port        = 5'b0;
      end
    end
  end
  else if (level == `LEVEL_LEAF) begin: gen_leaf_rc
    always @ (*) begin
      if (rc_en && route_info == `ROUTER_INFO_BROADCAST) begin
        // broadcast to all PEs, first go up to the root node
        route_port        = 5'b10000;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_BROADCAST) begin
        // finish the broadcast, send to the root controller
        route_port        = 5'b10000;
      end else if (rc_en && route_info == `ROUTER_INFO_FIN_COMP) begin
        // finish the computation, send to the root controller
        route_port        = 5'b10000;
      end else begin
        route_port        = 5'b0;
      end
    end
  end
end
endgenerate

endmodule
