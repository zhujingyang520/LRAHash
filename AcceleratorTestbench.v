`timescale 1 ns / 1 ps

// =============================================================================
// Module name: AcceleratorTestbench
//
// Testbench for the top module `Accelerator`.
// =============================================================================

`include "global.vh"

module AcceleratorTestbench;

localparam CLK_PERIOD = 10.0;

// ---------------------------------------
// Signals Definitions for Accelerator
// ---------------------------------------
reg clk, rst;
// write path
reg write_en;
wire write_rdy;
reg [`AddrBus] write_addr;
reg [`DataBus] write_data;
// read path
reg read_en;
wire read_rdy;
reg [`AddrBus] read_addr;
reg read_data_rdy;
wire read_data_vld;
wire [`DataBus] read_data;

// --------------------
// UUT instantiation
// --------------------
Accelerator accelerator (
  .clk            (clk),            // system clock
  .rst            (rst),            // system reset (active high)

  // interface of write operation (configuration)
  .write_en       (write_en),       // write enable (active high)
  .write_rdy      (write_rdy),      // write ready (active high)
  .write_addr     (write_addr),     // write address
  .write_data     (write_data),     // write data

  // interface of read operation (read data from accelerator)
  .read_en        (read_en),        // read enable (active high)
  .read_rdy       (read_rdy),       // read ready (active high)
  .read_addr      (read_addr),      // read address
  .read_data_rdy  (read_data_rdy),  // read data ready (active high)
  .read_data_vld  (read_data_vld),  // read data valid (active high)
  .read_data      (read_data)       // read data
);

// --------------------
// Clock definition
// --------------------
initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2.0) clk = ~clk;
end

// ------------------
// Input stimulus
// ------------------
initial begin
  init(2);                  // reset for 2 clock cycles
  config_op("config.dat");  // write the configuration info

  #(CLK_PERIOD*30000);
  $finish;
end

// ---------------------------------------
// Initialization task (reset procedure)
// ---------------------------------------
task init;
  input integer rst_period;
  begin
    rst = 1'b1;
    write_en = 1'b0;
    write_addr = 0;
    write_data = 0;
    read_en = 1'b0;
    read_addr = 0;
    read_data_rdy = 1'b0;
    #(rst_period*CLK_PERIOD)
    rst = 1'b0;
  end
endtask

// --------------------------------------
// Write operation task
// 2 input arguments:
// - addr: write address
// - data: write data
// --------------------------------------
task write_op;
  input [`AddrBus] addr;
  input [`DataBus] data;
  begin
    // wait for write ready (handshake)
    wait(write_rdy == 1'b1);
    @ (negedge clk);
    $display($time, " << write op: addr[%h] = %h >> ", addr, data);
    write_en = 1'b1;
    write_addr = addr;
    write_data = data;
    @ (negedge clk);  // assert for 1 clock cycle
    write_en = 1'b0;
    write_addr = 0;
    write_data = 0;
  end
endtask

// -----------------------------------------------------------
// Config operation task
// write the configuration info defined in the specified file
// -----------------------------------------------------------
task config_op;
  input [100*8-1:0] filename;
  integer fid;
  integer count;
  reg [`DataBus] data;
  reg [`AddrBus] addr;
  begin
    $display("#######################################");
    $display("# start configuration");
    $display("# read configuration file: %s", filename);
    fid = $fopen(filename, "r");
    if (fid == 0) begin
      $display("[ERROR]: open configuration file failed!");
      $finish;
    end
    // read file
    while (!$feof(fid)) begin
      count = $fscanf(fid, "%h %h\n", addr, data);
      if (count != 2) begin
        $display("[ERROR]: unexpected count when parsing configuration file!");
        $finish;
      end
      write_op(addr, data);
    end
    $display("# finish configuration");
    $display("#######################################");
  end
endtask

endmodule
