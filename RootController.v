// =============================================================================
// Module name: RootController
//
// The FSM controller at the root node (central control unit). It determines
// the global system state during computation.
// =============================================================================

`include "router.vh"
`include "global.vh"
`include "pe.vh"

module RootController (
  input wire                      clk,            // system clock
  input wire                      rst,            // system reset (active high)

  output reg                      interrupt,      // interrupt for done

  // interfaces of write operation
  input wire                      write_en,       // write enable (active high)
  input wire  [`DataBus]          write_data,     // write data
  input wire  [`AddrBus]          write_addr,     // write address
  output reg                      write_rdy,      // write ready

  // interfaces of read operation
  input wire                      read_en,        // read enable (active high)
  output reg                      read_rdy,       // read ready (active high)
  input wire  [`AddrBus]          read_addr,      // read address
  input wire                      read_data_rdy,  // read data ready
  output reg                      read_data_vld,  // read data valid
  output reg  [`ReadDataBus]      read_data,      // read data bus

  // interfaces of LOCAL port of quadtree router
  input wire                      in_data_valid,  // input data valid
  input wire  [`ROUTER_WIDTH-1:0] in_data,        // input data
  output reg                      out_data_valid, // output data valid
  output reg  [`ROUTER_WIDTH-1:0] out_data,       // output data
  input wire                      downstream_credit,  // downstream credit
  output reg                      upstream_credit     // upstream credit
);

// -----------------------
// FSM state definition
// -----------------------
localparam    STATE_IDLE          = 3'b000,       // idle state
              STATE_FIN_BROADCAST = 3'b001,       // finish broadcast state
              STATE_FIN_COMP      = 3'b010,       // finish computation stage
              STATE_WAIT_FOR_BROADCAST = 3'b011,  // wait for broadcast
              STATE_WAIT_FOR_COMP = 3'b100;       // wait for computation

// registers holding FSM state and next state logic
reg [2:0] state_reg, state_next;
// registers holding the layer no.
reg [`PeLayerNoBus] layer_no;
reg [`PeLayerNoBus] layer_idx_reg, layer_idx_next;
wire [`PeLayerNoBus] layer_idx_incre = layer_idx_reg + 1;
// dowstream available FIFO
reg [`CREDIT_CNT_WIDTH-1:0] downstream_credit_count;
// downstream credit decrement
reg downstream_credit_count_decre;
// read data field
wire [`ROUTER_INFO_WIDTH-1:0] in_data_route_info = in_data[35:32];
wire [`ROUTER_ADDR_WIDTH-1:0] in_data_route_addr = in_data[31:16];
wire [`ROUTER_DATA_WIDTH-1:0] in_data_route_data = in_data[15:0];
// counter for doing the statistic of PE
reg [5:0] pe_no_reg, pe_no_next;
// interrupt register next
reg interrupt_next;

// ---------------------------------
// Local FIFO storing the read data
// ---------------------------------
reg read_op_fifo_read_en;
wire [`ReadDataBus] read_op_fifo_read_data;
reg read_op_fifo_write_en;
reg [`ReadDataBus] read_op_fifo_write_data;
wire read_op_fifo_empty;

fifo_sync # (
  .BIT_WIDTH            (`READ_DATA_WIDTH),         // bit width
  .FIFO_DEPTH           (`TOT_FIFO_DEPTH)           // fifo depth (power of 2)
) read_op_fifo (
  .clk                  (clk),                      // system clock
  .rst                  (rst),                      // system reset

  // read interface
  .read_en              (read_op_fifo_read_en),     // read enable
  .read_data            (read_op_fifo_read_data),   // read data
  // write interface
  .write_en             (read_op_fifo_write_en),    // write enable
  .write_data           (read_op_fifo_write_data),  // write data

  // status indicator of FIFO
  .fifo_empty           (read_op_fifo_empty),       // fifo is empty
  .fifo_full            (/* floating */),           // fifo is full
  // next logic of fifo status flag
  .fifo_empty_next      (/* floating */),
  .fifo_full_next       (/* floating */)
);
// read operation interface handshake
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_data_vld       <= 1'b0;
    read_data           <= 0;
  end else if (~read_op_fifo_empty && read_data_rdy) begin
    read_data_vld       <= 1'b1;
    read_data           <= read_op_fifo_read_data;
  end else begin
    read_data_vld       <= 1'b0;
    read_data           <= 0;
  end
end
// read operation control
always @ (*) begin
  if (~read_op_fifo_empty && read_data_rdy) begin
    read_op_fifo_read_en  = 1'b1;
  end else begin
    read_op_fifo_read_en  = 1'b0;
  end
end
// write operation control
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_op_fifo_write_en   <= 1'b0;
    read_op_fifo_write_data <= 0;
  end else if (in_data_valid && in_data_route_info == `ROUTER_INFO_READ) begin
    read_op_fifo_write_en   <= 1'b1;
    read_op_fifo_write_data <= {in_data_route_addr[11:0],
      in_data_route_data};
  end else begin
    read_op_fifo_write_en   <= 1'b0;
    read_op_fifo_write_data <= 0;
  end
end

// ----------------------------------
// Configure the local layer no.
// ----------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    layer_no      <= 0;
  end else if (write_en && write_rdy && write_addr == 0) begin
    // synopsys translate_off
    $display("@%t Root Controller configure local layer no: %d", $time,
      write_data[`PeLayerNoBus]);
    // synopsys translate_on
    layer_no      <= write_data[`PeLayerNoBus];
  end
end

// -----------------------------------------------
// Status register tracking the computation stage
// -----------------------------------------------
// Track the layer index during computation
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    layer_idx_reg <= 0;
  end else begin
    layer_idx_reg <= layer_idx_next;
  end
end
// Track the received PE no.
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    pe_no_reg     <= 0;
  end else begin
    pe_no_reg     <= pe_no_next;
  end
end

// -----------------------------------------------------
// Root controller read data path from Quadtree router
// -----------------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    upstream_credit   <= 1'b0;
  end else if (in_data_valid &&
      in_data_route_info == `ROUTER_INFO_FIN_BROADCAST) begin
    // synopsys translate_off
    $display("@%t Root Controller receives fin broadcast from PE[%d]",
      $time, in_data_route_data);
    // synopsys translate_on
    upstream_credit   <= 1'b1;
  end else if (in_data_valid &&
      in_data_route_info == `ROUTER_INFO_FIN_COMP) begin
    // synopsys translate_off
    $display("@%t Root Controller receives fin comp from PE[%d]",
      $time, in_data_route_data);
    // synopsys translate_on
    upstream_credit   <= 1'b1;
  end else if (read_op_fifo_read_en) begin
    // synopsys translate_off
    $display("@%t Root Controller transfer Act[%d] = %d",
      $time, read_op_fifo_read_data[27:16], read_op_fifo_read_data[15:0]);
    // synopsys translate_on
    upstream_credit   <= 1'b1;
  end else begin
    upstream_credit   <= 1'b0;
  end
end

// ---------------------------------------------
// Credit count of the downstreaming LOCAL port
// ---------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    downstream_credit_count     <= `TOT_FIFO_DEPTH;
  end else begin
    case ({downstream_credit, downstream_credit_count_decre})
      2'b01: begin
        downstream_credit_count <= downstream_credit_count - 1;
      end
      2'b10: begin
        downstream_credit_count <= downstream_credit_count + 1;
      end
      default: begin
        downstream_credit_count <= downstream_credit_count;
      end
    endcase
  end
end

// ----------------
// FSM definition
// ----------------
// FSM state registers
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state_reg <= STATE_IDLE;
  end else begin
    state_reg <= state_next;
  end
end

// FSM next-state logics
always @ (*) begin
  // hold the previous state by default
  state_next        = state_reg;
  downstream_credit_count_decre = 1'b0;
  out_data_valid    = 1'b0;
  out_data          = 0;
  layer_idx_next    = layer_idx_reg;
  pe_no_next        = pe_no_reg;

  interrupt_next    = 1'b0;

  case (state_reg)
    STATE_IDLE: begin
      if (write_en && write_rdy && write_addr == {`ADDR_WIDTH{1'b1}}) begin
        // special register @ 0xFFFF, start computation
        state_next      = STATE_FIN_BROADCAST;
        out_data_valid  = 1'b1;
        out_data[35:32] = `ROUTER_INFO_CALC;
        out_data[31:0]  = 0;
        downstream_credit_count_decre = 1'b1;
        // reset the layer index & pe no
        layer_idx_next  = 0;
        pe_no_next      = 0;
      end
      else if (write_en && write_rdy) begin
        // configure the PE. Hardcode the data packet to send
        out_data_valid  = 1'b1;
        out_data[35:32] = `ROUTER_INFO_CONFIG;
        out_data[31:16] = write_addr;
        out_data[15:0]  = write_data;
        downstream_credit_count_decre = 1'b1;
      end
      else if (read_en && read_rdy) begin
        // read the PE local register file to the primary output
        out_data_valid  = 1'b1;
        out_data[35:32] = `ROUTER_INFO_READ;
        out_data[31:16] = read_addr;
        out_data[15:0]  = 16'b0;
        downstream_credit_count_decre = 1'b1;
      end
    end

    STATE_FIN_BROADCAST: begin
      // check the received number of finish broadcast package
      if (in_data_valid && in_data_route_info == `ROUTER_INFO_FIN_BROADCAST)
      begin
        // increase the number of pe no.
        pe_no_next      = pe_no_reg + 1;
        if (pe_no_reg == 63) begin
          // receive all the activations from PE
          if (downstream_credit_count > 0) begin
            out_data_valid  = 1'b1;
            out_data[35:32] = `ROUTER_INFO_FIN_BROADCAST;
            out_data[31:16] = 0;
            out_data[15:0]  = 0;
            downstream_credit_count_decre = 1'b1;
            // reset pe no.
            pe_no_next      = 0;

            state_next  = STATE_FIN_COMP;
          end else begin
            // downstreaming router is busy
            state_next  = STATE_WAIT_FOR_BROADCAST;
          end
        end
      end
    end

    STATE_WAIT_FOR_BROADCAST: begin
      if (downstream_credit_count > 0) begin
        out_data_valid  = 1'b1;
        out_data[35:32] = `ROUTER_INFO_FIN_BROADCAST;
        out_data[31:16] = 0;
        out_data[15:0]  = 0;
        downstream_credit_count_decre = 1'b1;
        // reset pe no.
        pe_no_next      = 0;
        state_next      = STATE_FIN_COMP;
      end
    end

    STATE_FIN_COMP: begin
      // check the recived number of finish computation package
      if (in_data_valid && in_data_route_info == `ROUTER_INFO_FIN_COMP)
      begin
        // increase the number of pe no.
        pe_no_next      = pe_no_reg + 1;
        if (pe_no_reg == 63) begin
          // all PEs finish computation
          if (downstream_credit_count > 0) begin
            out_data_valid  = 1'b1;
            out_data[35:32] = `ROUTER_INFO_FIN_COMP;
            out_data[31:0]  = 0;
            downstream_credit_count_decre = 1'b1;
            // reset pe no.
            pe_no_next      = 0;

            // next state transfer
            if (layer_idx_reg == layer_no-1) begin
              state_next    = STATE_IDLE;
              interrupt_next= 1'b1; // generate 1-cycle tick for interrupt
            end else begin
              // proceed to the next layer
              state_next    = STATE_FIN_BROADCAST;
              layer_idx_next= layer_idx_incre;
            end
          end else begin
            state_next  = STATE_WAIT_FOR_COMP;
          end
        end
      end
    end

    STATE_WAIT_FOR_COMP: begin
      if (downstream_credit_count > 0) begin
        out_data_valid  = 1'b1;
        out_data[35:32] = `ROUTER_INFO_FIN_COMP;
        out_data[31:0]  = 0;
        downstream_credit_count_decre = 1'b1;
        // reset pe no.
        pe_no_next      = 0;

        // next state transfer
        if (layer_idx_reg == layer_no-1) begin
          state_next    = STATE_IDLE;
          interrupt_next= 1'b1;   // generate 1-cycle tick for interrupt
        end else begin
          state_next    = STATE_FIN_BROADCAST;
          layer_idx_next= layer_idx_incre;
        end
      end
    end
  endcase
end

// ---------------------------------
// Primary output logic: registers
// ---------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    interrupt     <= 1'b0;
  end else begin
    interrupt     <= interrupt_next;
  end
end

//TODO: buggy for non ideal ready
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    write_rdy     <= 1'b0;
  end else begin
    write_rdy     <= (downstream_credit_count > 0) && (state_reg == STATE_IDLE);
  end
end

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    read_rdy      <= 1'b0;
  end else begin
    read_rdy      <= (downstream_credit_count > 0) && (state_reg == STATE_IDLE);
  end
end

endmodule
