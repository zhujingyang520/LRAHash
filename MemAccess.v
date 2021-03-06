// =============================================================================
// Module name: MemAccess
//
// This module exports the memory access stage of the computation datapath.
// =============================================================================

`include "pe.vh"

module MemAccess (
  input wire                  clk,              // system clock
  input wire                  rst,              // system reset

  // Input datapath & control path (memory stage)
  input wire  [`CompEnBus]    comp_en_mem,      // computation enable (mem)
  input wire  [`PeDataBus]    in_act_value_mem, // input activation value (mem)
  input wire  [`PeActNoBus]   out_act_addr_mem, // output activation address
  input wire  [`TruncWidth]   trunc_amount_mem, // truncation amount
  // W memory
  input wire                  w_mem_cen,        // weight memory enable
  input wire                  w_mem_wen,        // weight memory write enable
  input wire  [`WMemAddrBus]  w_mem_addr,       // weight memory address
  // U memory
  input wire                  u_mem_cen,        // U memory enable
  input wire                  u_mem_wen,        // U memory write enable
  input wire  [`UMemAddrBus]  u_mem_addr,       // U memory address
  // V memory
  input wire                  v_mem_cen,        // V memory enable
  input wire                  v_mem_wen,        // V memory write enable
  input wire  [`VMemAddrBus]  v_mem_addr,       // V memory address

  // Output datapath & control path (mult stage)
  output reg  [`CompEnBus]    comp_en_mult,     // computation enable (mult)
  output reg  [`PeDataBus]    in_act_value_mult,// operand: in act (mult)
  output reg  [`PeDataBus]    mem_value_mult,   // operand: mem data (mult)
  output reg  [`PeActNoBus]   out_act_addr_mult,// output activation address
  output reg  [`TruncWidth]   trunc_amount_mult // truncation amount
);

// ---------------------
// Memory data output
// ---------------------
wire [`PeDataBus] w_mem_q;
wire [`PeDataBus] u_mem_q;
wire [`PeDataBus] v_mem_q;

// ----------------------------------------------------------------
// Instantiate the on-chip SRAM
// Note: The memory model is generated by CACTI 6.5
// - W Memory size: 16x65536
// ----------------------------------------------------------------
`ifdef CACTI_MEM_MODEL
// memory output enable (active low)
reg w_mem_oe;
reg u_mem_oe;
reg v_mem_oe;
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    w_mem_oe          <= 1'b1;
    u_mem_oe          <= 1'b1;
    v_mem_oe          <= 1'b1;
  end else begin
    w_mem_oe          <= w_mem_cen;
    u_mem_oe          <= u_mem_cen;
    v_mem_oe          <= v_mem_cen;
  end
end
// memory behavior model generated by `cacti-mc`
// W memory
SRAM_16x65536_1P w_mem (
  .CE1                (clk),                    // system clock
  .WEB1               (w_mem_wen),              // write enable (active low)
  .CSB1               (w_mem_cen),              // chip enable (active low)
  .OEB1               (w_mem_oe),               // output enable (active low)
  .A1                 (w_mem_addr),             // read/write address
  .I1                 (`W_MEM_DATA_WIDTH'd0),   // data input (write op)
  .O1                 (w_mem_q)                 // data output (read op)
);
// U memory
SRAM_16x4096_1P u_mem (
  .CE1                (clk),                    // system clock
  .WEB1               (u_mem_wen),              // write enable (active low)
  .CSB1               (u_mem_cen),              // chip enable (active low)
  .OEB1               (u_mem_oe),               // output enable (active low)
  .A1                 (u_mem_addr),             // read/write address
  .I1                 (`U_MEM_DATA_WIDTH'd0),   // data input (write op)
  .O1                 (u_mem_q)                 // data output (read op)
);
// V memory
SRAM_16x4096_1P v_mem (
  .CE1                (clk),                    // system clock
  .WEB1               (v_mem_wen),              // write enable (active low)
  .CSB1               (v_mem_cen),              // chip enable (active low)
  .OEB1               (v_mem_oe),               // output enable (active low)
  .A1                 (v_mem_addr),             // read/write address
  .I1                 (`V_MEM_DATA_WIDTH'd0),   // data input (write op)
  .O1                 (v_mem_q)                 // data output (read op)
);

`else

// ideal memory model (WARNING: not synthesizable!)
// W memory
spram_behav # (
  .MEM_WIDTH          (`W_MEM_DATA_WIDTH),      // memory (bus) width
  .MEM_DEPTH          (2**`W_MEM_ADDR_WIDTH)    // memory depth
) w_mem (
  .clk                (clk),                    // system clock
  .cen                (w_mem_cen),              // chip enable (active low)
  .wen                (w_mem_wen),              // write enable (active low)
  .addr               (w_mem_addr),             // read/write address
  .d                  (`W_MEM_DATA_WIDTH'd0),   // data input (write op)
  .q                  (w_mem_q)                 // data output (read op)
);
// U memory
spram_behav # (
  .MEM_WIDTH          (`U_MEM_DATA_WIDTH),      // memory (bus) width
  .MEM_DEPTH          (2**`U_MEM_ADDR_WIDTH)    // memory depth
) u_mem (
  .clk                (clk),                    // system clock
  .cen                (u_mem_cen),              // chip enable (active low)
  .wen                (u_mem_wen),              // write enable (active low)
  .addr               (u_mem_addr),             // read/write address
  .d                  (`U_MEM_DATA_WIDTH'd0),   // data input (write op)
  .q                  (u_mem_q)                 // data output (read op)
);
// V memory
spram_behav # (
  .MEM_WIDTH          (`V_MEM_DATA_WIDTH),      // memory (bus) width
  .MEM_DEPTH          (2**`V_MEM_ADDR_WIDTH)    // memory depth
) v_mem (
  .clk                (clk),                    // system clock
  .cen                (v_mem_cen),              // chip enable (active low)
  .wen                (v_mem_wen),              // write enable (active low)
  .addr               (v_mem_addr),             // read/write address
  .d                  (`V_MEM_DATA_WIDTH'd0),   // data input (write op)
  .q                  (v_mem_q)                 // data output (read op)
);
`endif

// ----------------------------------------------
// Pipeline stage of the datapath & control path
// ----------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    comp_en_mult      <= `COMP_EN_IDLE;
    in_act_value_mult <= 0;
    out_act_addr_mult <= 0;
    trunc_amount_mult <= 0;
  end else begin
    comp_en_mult      <= comp_en_mem;
    in_act_value_mult <= in_act_value_mem;
    out_act_addr_mult <= out_act_addr_mem;
    trunc_amount_mult <= trunc_amount_mem;
  end
end
// Select the desired memory output
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    mem_value_mult    <= 0;
  end else begin
    case (comp_en_mem)
      `COMP_EN_U: begin
        mem_value_mult<= u_mem_q;
      end
      `COMP_EN_V: begin
        mem_value_mult<= v_mem_q;
      end
      `COMP_EN_W: begin
        mem_value_mult<= w_mem_q;
      end
      default: begin
        mem_value_mult<= 0;
      end
    endcase
  end
end

endmodule
