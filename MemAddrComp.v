// =============================================================================
// Module name: MemAddrComp
//
// This module exports the on-chip SRAM address computation
// =============================================================================

`include "pe.vh"

module MemAddrComp (
  input wire  [5:0]           PE_IDX,           // PE index
  input wire                  clk,              // system clock
  input wire                  rst,              // system reset (active high)

  // Input datapath & control path
  input wire  [`CompEnBus]    comp_en,          // computation enable
  input wire  [`PeLayerNoBus] layer_idx,        // layer index
  input wire  [`PeAddrBus]    in_act_idx,       // input activation index
  input wire  [`PeActNoBus]   out_act_addr,     // output activation address
  input wire  [`PeAddrBus]    col_dim,          // column dimension
  input wire  [`PeDataBus]    in_act_value,     // input activation value
  input wire  [`PeActNoBus]   in_act_no,        // input activation number
  input wire  [`RankBus]      rank_no,          // rank number
  input wire  [`WMemAddrBus]  mem_offset,       // memory offset

  // Output datapath & control path (memory stage)
  output reg  [`CompEnBus]    comp_en_mem,      // computation enable
  output reg  [`PeDataBus]    in_act_value_mem, // input activation value
  output reg  [`PeActNoBus]   out_act_addr_mem, // output activation address

  // on-chip sram interfaces (active low)
  // W memory
  output reg                  w_mem_cen,        // weight memory enable
  output reg                  w_mem_wen,        // weight memory write enable
  output reg  [`WMemAddrBus]  w_mem_addr,       // weight memory address
  // U memory
  output reg                  u_mem_cen,        // U memory enable
  output reg                  u_mem_wen,        // U memory write enable
  output reg  [`UMemAddrBus]  u_mem_addr,       // U memory address
  // V memory
  output reg                  v_mem_cen,        // V memory enable
  output reg                  v_mem_wen,        // V memory write enable
  output reg  [`VMemAddrBus]  v_mem_addr        // V memory address
);

`define MEM_ACTIVE 1'b0
`define MEM_INACTIVE 1'b1

// TODO: address computation using pseudo hash
//wire [`PeAddrBus] out_act_idx = {out_act_addr, PE_IDX};

// -----------------------------------------------
// Interconnections of memory address computation
// -----------------------------------------------
reg [`PeActNoBus] row_idx;
reg [`PeAddrBus] col_d;
reg [`PeAddrBus] col_idx;
wire [`WMemAddrBus] addr;

// ---------------------------------------------------------
// Multiplex the inputs to the address computation datapath
// ---------------------------------------------------------
always @ (*) begin
  case (comp_en)
    `COMP_EN_W: begin
      row_idx       = out_act_addr;
      col_d         = col_dim;
      col_idx       = in_act_idx;
    end
    `COMP_EN_U: begin
      row_idx       = out_act_addr;
      col_d         = {{(`PE_ADDR_WIDTH-`RANK_WIDTH){1'b0}}, rank_no};
      col_idx       = in_act_idx;
    end
    `COMP_EN_V: begin
      row_idx       = out_act_addr;
      col_d         = {{(`PE_ADDR_WIDTH-`PE_ACT_NO_WIDTH){1'b0}}, in_act_no};
      col_idx       = in_act_idx;
    end
    default: begin
      row_idx       = 0;
      col_d         = 0;
      col_idx       = 0;
    end
  endcase
end

// -------------------------------------------
// Address computation datapath
// -------------------------------------------
AddrComp addr_comp (
  .offset           (mem_offset),       // memory offset
  .row_idx          (row_idx),          // row index
  .col_dim          (col_d),            // column dimension
  .col_idx          (col_idx),          // column index
  .addr             (addr)              // calculated address
);

// -------------------------------------------
// Pipeline the input datapath & control path
// -------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_mem       <= `COMP_EN_IDLE;
    in_act_value_mem  <= 0;
    out_act_addr_mem  <= 0;
  end else begin
    comp_en_mem       <= comp_en;
    in_act_value_mem  <= in_act_value;
    out_act_addr_mem  <= out_act_addr;
  end
end

// ----------------------------------------------
// Generate the weight SRAM control interface
// ----------------------------------------------
// These signals are provided in the current cycle
// W memory
always @ (*) begin
  if (comp_en == `COMP_EN_W) begin
    w_mem_cen   = `MEM_ACTIVE;
    w_mem_wen   = 1'b1; // always @ read operation
    w_mem_addr  = addr;
  end else begin
    w_mem_cen   = `MEM_INACTIVE;
    w_mem_wen   = 1'b1; // always @ read operation
    w_mem_addr  = 0;
  end
end
// U memory
always @ (*) begin
  if (comp_en == `COMP_EN_U) begin
    u_mem_cen   = `MEM_ACTIVE;
    u_mem_wen   = 1'b1; // always @ read operation
    u_mem_addr  = addr[`UMemAddrBus];
  end else begin
    u_mem_cen   = `MEM_INACTIVE;
    u_mem_wen   = 1'b1; // always @ read operation
    u_mem_addr  = 0;
  end
end
// V memory
always @ (*) begin
  if (comp_en == `COMP_EN_V) begin
    v_mem_cen   = `MEM_ACTIVE;
    v_mem_wen   = 1'b1; // always @ read operation
    v_mem_addr  = addr[`VMemAddrBus];
  end else begin
    v_mem_cen   = `MEM_INACTIVE;
    v_mem_wen   = 1'b1; // always @ read operation
    v_mem_addr  = 0;
  end
end

endmodule
