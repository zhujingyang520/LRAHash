`timescale 1 ns / 1 ps

// =============================================================================
// Module name: AcceleratorTestbench
//
// Testbench for the top module `Accelerator`.
// =============================================================================

`include "global.vh"

module AcceleratorTestbench;

`include "mem_init_task.vh"

localparam CLK_PERIOD = 10.0;

// ---------------------------------------
// Signals Definitions for Accelerator
// ---------------------------------------
reg clk, rst;
wire interrupt;
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
wire [`ReadDataBus] read_data;

// --------------------
// UUT instantiation
// --------------------
Accelerator accelerator (
  .clk            (clk),            // system clock
  .rst            (rst),            // system reset (active high)

  .interrupt      (interrupt),      // interrupt

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

// output activation no.
reg [11:0] out_act_no;
integer fp, count;

// ------------------
// Input stimulus
// ------------------
initial begin
  // parse the parameters
  fp = $fopen("tb.dat", "r");
  if (fp == 0) begin
    $display("[ERROR]: open tb.dat failed");
    $finish;
  end
  count = $fscanf(fp, "%d", out_act_no);
  $display("Read out_act_no=%d", out_act_no);
  $fclose(fp);

  w_mem_init;               // memory initialization
  init(2);                  // reset for 2 clock cycles
  config_op("config.dat");  // write the configuration info

  wait(interrupt == 1'b1);
  #(CLK_PERIOD*100);
  read_out_act(out_act_no);

  #(CLK_PERIOD*1000);
  $finish;
end

// --------------------
// Read data monitor
// --------------------
always @ (posedge clk) begin
  if (read_data_vld && read_data_rdy) begin
    $display("@%t Testbench received Act[%d] = %d", $time,
      read_data[27:16], read_data[15:0]);
  end
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

// --------------------------------------
// Read operation task
// 1 input argument:
// - addr: read address
// --------------------------------------
task read_op;
  input [`AddrBus] addr;
  begin
    // wait for read ready (handshake)
    wait(read_rdy == 1'b1);
    @ (negedge clk);
    $display($time, " << read op: of addr[%h] >> ", addr);
    read_en = 1'b1;
    read_addr = addr;
    @ (negedge clk);
    read_en = 1'b0;
    read_addr = 0;
  end
endtask

// --------------------------------------
// Read all output activation data
// --------------------------------------
task read_out_act;
  input [11:0] act_no;
  integer pe_idx;
  integer act_addr;
  integer count;
  reg [`AddrBus] addr;
  begin
    $display("#######################################");
    $display("# start read activation");
    read_data_rdy = 1'b1;
    count = 0;
    pe_idx = 0;
    act_addr = 0;
    while (count < act_no) begin
      addr = 0;
      addr[15:10] = pe_idx;
      addr[5:0] = act_addr;
      read_op(addr);
      if (pe_idx == 63) begin
        pe_idx = 0;
        act_addr = act_addr + 1;
      end else begin
        pe_idx = pe_idx + 1;
      end
      count = count + 1;
    end
    $display("#######################################");
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
