// =============================================================================
// Module name: ActRegFile
//
// This module exports the activations for the processing elements. It includes
// 2 activation register files, which exchange the role of input and output
// activations during feedforward (Ping-Pong fashion).
// =============================================================================

`include "pe.vh"

module ActRegFile (
  input wire  [5:0]             PE_IDX,             // PE index
  input wire                    clk,                // system clock
  input wire                    dir,                // direction of in/out
  // input activations
  input wire                    in_act_clear,       // input activation clear
  input wire                    in_act_read_en,     // read enable
  input wire  [`PeActNoBus]     in_act_read_addr,   // read address
  output reg  [`PeDataBus]      in_act_read_data,   // read data
  input wire                    in_act_write_en,    // write enable
  input wire  [`PeActNoBus]     in_act_write_addr,  // write address
  input wire  [`PeDataBus]      in_act_write_data,  // write data
  output reg  [`PE_ACT_NO-1:0]  in_act_zeros,       // zero flags
  // output activations
  input wire                    out_act_clear,      // output activation clear
  input wire                    out_act_read_en,    // read enable
  input wire  [`PeActNoBus]     out_act_read_addr,  // read address
  output reg  [`PeDataBus]      out_act_read_data,  // read data
  input wire                    out_act_write_en,   // write enable
  input wire  [`PeActNoBus]     out_act_write_addr, // write address
  input wire  [`PeDataBus]      out_act_write_data  // write data
);

genvar g;

// -------------------------------------
// Interconnections of 2 register files
// -------------------------------------
reg clear [1:0];
reg read_en [1:0];
reg [`PeActNoBus] read_addr [1:0];
wire [`PeDataBus] read_data [1:0];
reg write_en [1:0];
reg [`PeActNoBus] write_addr [1:0];
reg [`PeDataBus] write_data [1:0];
wire [`PE_ACT_NO-1:0] zeros [1:0];

// ----------------------------------
// Instantiation of 2 register files
// ----------------------------------
generate
for (g = 0; g < 2; g = g + 1) begin: gen_reg_file
RegFile #(
  .BIT_WIDTH          (`PE_DATA_WIDTH),       // bit width of the entry
  .REG_DEPTH          (`PE_ACT_NO)            // register file depth
) reg_file (
  .clk                (clk),                  // system clock
  .clear              (clear[g]),             // clear
  // read interface
  .read_en            (read_en[g]),           // read enable (active high)
  .read_addr          (read_addr[g]),         // read address
  .read_data          (read_data[g]),         // read data
  // write interface
  .write_en           (write_en[g]),          // write enable (active high)
  .write_addr         (write_addr[g]),        // write address
  .write_data         (write_data[g]),        // write data
  // zero detection flag
  .zeros              (zeros[g])              // zero flag for detection
);
end
endgenerate

// ---------------------------------------------------------
// Multiplexer dealing with in/out activation register file
// ---------------------------------------------------------
always @ (*) begin
  if (dir == `ACT_DIR_0) begin
    // ACT_DIR_0: act[0]: in; act[1]: out
    // clear operation
    clear[0] = in_act_clear;
    clear[1] = out_act_clear;
    // read operation
    read_en[0] = in_act_read_en;
    read_en[1] = out_act_read_en;
    read_addr[0] = in_act_read_addr;
    read_addr[1] = out_act_read_addr;
    in_act_read_data = read_data[0];
    out_act_read_data = read_data[1];
    // write operation
    write_en[0] = in_act_write_en;
    write_en[1] = out_act_write_en;
    write_addr[0] = in_act_write_addr;
    write_addr[1] = out_act_write_addr;
    write_data[0] = in_act_write_data;
    write_data[1] = out_act_write_data;
    // zero flags
    in_act_zeros = zeros[0];
  end else begin
    // ACT_DIR_1: act[0]: out; act[1]: in
    // clear operation
    clear[1] = in_act_clear;
    clear[0] = out_act_clear;
    // read operation
    read_en[1] = in_act_read_en;
    read_en[0] = out_act_read_en;
    read_addr[1] = in_act_read_addr;
    read_addr[0] = out_act_read_addr;
    in_act_read_data = read_data[1];
    out_act_read_data = read_data[0];
    // write operation
    write_en[1] = in_act_write_en;
    write_en[0] = out_act_write_en;
    write_addr[1] = in_act_write_addr;
    write_addr[0] = out_act_write_addr;
    write_data[1] = in_act_write_data;
    write_data[0] = out_act_write_data;
    // zero flags
    in_act_zeros = zeros[1];
  end
end

// behavior log information
// synopsys translate_off
always @ (posedge clk) begin
  if (in_act_write_en) begin
    $display("@%t CONFIG PE[%d]: act[%d] = %d", $time, PE_IDX,
      in_act_write_addr, $signed(in_act_write_data));
  end
end
// synopsys translate_on

endmodule
