// =============================================================================
// Module name: RootCompController
//
// The module exports the root computation controller. It issues the computation
// related packets includes:
//
// a) Configuration packet
// b) Read request packet
// c) Finish broadcast packet (layer-level)
// d) Finish computation packet (layer-level)
// =============================================================================

`include "router.vh"
`include "pe.vh"
`include "global.vh"

module RootCompController (
  input wire                          clk,                // system clock
  input wire                          rst,                // system reset

  // primary interfaces
  output reg                          interrupt,          // interrupt
  // write request handshake
  input wire                          write_en,           // write enable
  input wire  [`DataBus]              write_data,         // write data
  input wire  [`AddrBus]              write_addr,         // write address
  output reg                          write_rdy,          // write ready
  // read request handshake
  input wire                          read_en,            // read enable
  output reg                          read_rdy,           // read ready
  input wire  [`AddrBus]              read_addr,          // read address

  // interfaces of the LOCAL port of the quadtree router
  input wire                          in_data_valid,      // input data valid
  input wire  [`ROUTER_WIDTH-1:0]     in_data,            // input data

  // interfaces of root node
  input wire                          router_rdy,         // router ready
  output wire [`PeLayerNoBus]         layer_idx,          // layer index
  output reg                          comp_tx_en,         // comp tx enable
  output reg  [`ROUTER_WIDTH-1:0]     comp_tx_data,       // comp tx data

  // interfaces of the root rank register
  output reg                          clear_bias_offset,  // clear offset
  output reg                          update_bias_offset  // update offset
);

// ---------------------------------
// FSM state definitions
// ---------------------------------
localparam    STATE_IDLE              = 3'd0,             // idle state
              STATE_FIN_BROADCAST     = 3'd1,             // finish broadcast
              STATE_FIN_COMP          = 3'd2,             // finish computation
              STATE_FIN_BROADCAST_STALL = 3'd3,           // stall of broadcast
              STATE_FIN_COMP_STALL    = 3'd4;             // stall of comp

// ---------------------------------
// Unpack the LOCAL data port
// ---------------------------------
wire [`ROUTER_INFO_WIDTH-1:0] in_data_route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] in_data_route_addr = in_data[31:16];
wire [`ROUTER_DATA_WIDTH-1:0] in_data_route_data = in_data[15:0];

// ---------------------------------
// Registers of the state machine
// ---------------------------------
reg [2:0] state_reg, state_next;
// layer index
reg [`PeLayerNoBus] layer_no;
reg [`PeLayerNoBus] layer_idx_reg, layer_idx_next;
wire [`PeLayerNoBus] layer_idx_incre = layer_idx_reg + 1;
// pe number counter
reg [5:0] pe_no_reg, pe_no_next;
// interrupt next
reg interrupt_next;

// -------------------------------------
// Write the layer no. @ the root node
// -------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    layer_no        <= 0;
  end else if (write_en && write_rdy && write_addr == 0) begin
    layer_no        <= write_data[`PeLayerNoBus];
    // synopsys translate_off
    $display("@%t Root Controller configure local layer no: %d", $time,
      write_data[`PeLayerNoBus]);
    // synopsys translate_on
  end
end

// ------------------------------------
// FSM-related registers definition
// ------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg       <= STATE_IDLE;
    layer_idx_reg   <= 0;
    pe_no_reg       <= 0;
  end else begin
    state_reg       <= state_next;
    layer_idx_reg   <= layer_idx_next;
    pe_no_reg       <= pe_no_next;
  end
end
// FSM next-logic (combinational)
always @ (*) begin
  // registers hold the original value by default
  state_next        = state_reg;
  layer_idx_next    = layer_idx_reg;
  pe_no_next        = pe_no_reg;
  // disable transmit by default
  comp_tx_en        = 1'b0;
  comp_tx_data      = 0;
  // disable interrupt by default
  interrupt_next    = 1'b0;
  // disable the bias memory offset
  clear_bias_offset   = 1'b0;
  update_bias_offset  = 1'b0;

  case (state_reg)
    STATE_IDLE: begin
      if (write_en && write_rdy && write_addr == {`ADDR_WIDTH{1'b1}}) begin
        // special resgiter @ 0xFFFF, start computation
        state_next          = STATE_FIN_BROADCAST;
        comp_tx_en          = 1'b1;
        comp_tx_data[35:32] = `ROUTER_INFO_CALC;
        comp_tx_data[31:0]  = 0;
        // reset the index counter
        layer_idx_next      = 0;
        pe_no_next          = 0;
      end else if (write_en && write_rdy) begin
        // normal configuration operation
        comp_tx_en          = 1'b1;
        comp_tx_data[35:32] = `ROUTER_INFO_CONFIG;
        comp_tx_data[31:16] = write_addr;
        comp_tx_data[15:0]  = write_data;
        // normal read operation
      end else if (read_en && read_rdy) begin
        comp_tx_en          = 1'b1;
        comp_tx_data[35:32] = `ROUTER_INFO_READ;
        comp_tx_data[31:16] = read_addr;
        comp_tx_data[15:0]  = 0;
      end
    end

    STATE_FIN_BROADCAST: begin
      // receive the finish broadcast packets from 64 PEs
      if (in_data_valid && in_data_route_info == `ROUTER_INFO_FIN_BROADCAST)
      begin
        pe_no_next          = pe_no_reg + 1;
        if (pe_no_reg == 63) begin
          // All 64 PEs have finished broadcast
          if (router_rdy) begin
            comp_tx_en          = 1'b1;
            comp_tx_data[35:32] = `ROUTER_INFO_FIN_BROADCAST;
            comp_tx_data[31:16] = 0;
            comp_tx_data[15:0]  = 0;
            // transfer to the finish computation state
            state_next          = STATE_FIN_COMP;
            pe_no_next          = 0;
          end else begin
            // stall for sending the finish broadcast packet
            state_next          = STATE_FIN_BROADCAST_STALL;
          end
        end
      end
    end

    STATE_FIN_BROADCAST_STALL: begin
      if (router_rdy) begin
        comp_tx_en          = 1'b1;
        comp_tx_data[35:32] = `ROUTER_INFO_FIN_BROADCAST;
        comp_tx_data[31:16] = 0;
        comp_tx_data[15:0]  = 0;
        // transfer to the finish computation state
        state_next          = STATE_FIN_COMP;
        pe_no_next          = 0;
      end
    end

    STATE_FIN_COMP: begin
      // recieve the finish computation packets from 64 PEs
      if (in_data_valid && in_data_route_info == `ROUTER_INFO_FIN_COMP) begin
        pe_no_next          = pe_no_reg + 1;
        if (pe_no_reg == 63) begin
          // All 64 PEs have finished computation
          if (router_rdy) begin
            comp_tx_en          = 1'b1;
            comp_tx_data[35:32] = `ROUTER_INFO_FIN_COMP;
            comp_tx_data[31:0]  = 0;
            // reset the pe no counter
            pe_no_next          = 0;

            // next state transfer
            if (layer_idx_reg == layer_no - 1) begin
              state_next        = STATE_IDLE;
              interrupt_next    = 1'b1;
              clear_bias_offset = 1'b1;
            end else begin
              state_next        = STATE_FIN_BROADCAST;
              layer_idx_next    = layer_idx_incre;
              update_bias_offset= 1'b1;
            end
          end else begin
            state_next          = STATE_FIN_COMP_STALL;
          end
        end
      end
    end

    STATE_FIN_COMP_STALL: begin
      if (router_rdy) begin
        comp_tx_en              = 1'b1;
        comp_tx_data[35:32]     = `ROUTER_INFO_FIN_COMP;
        comp_tx_data[31:0]      = 0;
        // reset the pe no counter
        pe_no_next              = 0;

        // next state transfer
        if (layer_idx_reg == layer_no - 1) begin
          state_next            = STATE_IDLE;
          interrupt_next        = 1'b1;
          clear_bias_offset     = 1'b1;
        end else begin
          state_next            = STATE_FIN_BROADCAST;
          layer_idx_next        = layer_idx_incre;
          update_bias_offset    = 1'b1;
        end
      end
    end
  endcase
end

// ------------------------------
// Interrupt (register)
// ------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    interrupt       <= 1'b0;
  end else begin
    interrupt       <= interrupt_next;
  end
end

// -------------------------------------
// Handshake of ready (TODO have bugs)
// -------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    write_rdy       <= 1'b0;
  end else begin
    write_rdy       <= router_rdy && (state_reg == STATE_IDLE);
  end
end

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_rdy        <= 1'b0;
  end else begin
    read_rdy        <= router_rdy && (state_reg == STATE_IDLE);
  end
end

assign layer_idx = layer_idx_reg;

// ------------------------------------
// Display log info
// ------------------------------------
// synopsys translate_off
always @ (posedge clk) begin
  if (in_data_valid && in_data_route_info == `ROUTER_INFO_FIN_BROADCAST) begin
    $display("@%t Root Controller receives fin broadcast from PE[%d]",
      $time, in_data_route_data);
  end
  else if (in_data_valid && in_data_route_info == `ROUTER_INFO_FIN_COMP) begin
    $display("@%t Root Controller receives fin comp from PE[%d]",
      $time, in_data_route_data);
  end
  else if (in_data_valid && in_data_route_info == `ROUTER_INFO_UV) begin
    $display("@%t Root Controller receives partial rank[%d] = %d", $time,
      in_data_route_addr, $signed(in_data_route_data));
  end
end
// synopsys translate_on

endmodule
