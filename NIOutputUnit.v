// =============================================================================
// Module name: NIOutputUnit
//
// This module exports the output unit for the network interface of the
// processing element.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module NIOutputUnit (
  input wire  [5:0]                     PE_IDX,       // PE index
  input wire                            clk,          // system clock
  input wire                            rst,          // system reset

  // PE controller interface
  input wire                            act_send_en,  // act send enable
  input wire  [`ROUTER_ADDR_WIDTH-1:0]  act_send_addr,// act send address
  input wire  [`PeDataBus]              act_send_data,// act send data
  input wire                            fin_comp,     // finish computation
  // partial sum broadcast path
  input wire                            part_sum_send_en,
  input wire  [`ROUTER_ADDR_WIDTH-1:0]  part_sum_send_addr,
  input wire  [`PeDataBus]              part_sum_send_data,

  // NI read request interface
  input wire                            read_rqst_read_en,
                                                      // read request read enable
  input wire                            ni_read_rqst, // read request enable
  input wire  [`PeActNoBus]             ni_read_addr, // read request address

  // PE status registers
  input wire                            out_act_relu, // output act relu
  // Activation register file interface
  input wire  [`ActRegDataBus]          out_act_read_data,
                                                      // output act read data
  input wire  [`ActRegDataBus]          out_act_read_data_relu,
                                                      // out act read data relu

  // Credit input from downstreaming router
  input wire                            downstream_credit,
  output wire                           router_rdy,   // router ready

  // Output datapath
  output reg                            out_data_valid,
  output reg  [`ROUTER_WIDTH-1:0]       out_data      // output data
);

// Mux for the output activation
reg [`PeDataBus] out_act_data;
always @ (*) begin
  if (out_act_relu) begin
    out_act_data    = out_act_read_data_relu[`PeDataBus];
  end else begin
    out_act_data    = out_act_read_data[`PeDataBus];
  end
end

// --------------------------------------------------
// Output datapath: registers to transfer the packet
// --------------------------------------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    out_data_valid    <= 1'b0;
    out_data          <= 0;
  end else if (act_send_en) begin
    // send the activation during the broadcast activation phase
    if (act_send_addr[`ROUTER_ADDR_WIDTH-1] == 1'b1) begin
      // special packet of `FIN_BROADCAST`
      out_data_valid  <= 1'b1;
      out_data[35:32] <= `ROUTER_INFO_FIN_BROADCAST;
      out_data[31:16] <= act_send_addr;
      out_data[15:0]  <= act_send_data;
    end else begin
      // transmit the normal `BROADCAST` packet
      out_data_valid  <= 1'b1;
      out_data[35:32] <= `ROUTER_INFO_BROADCAST;
      out_data[31:16] <= act_send_addr;
      out_data[15:0]  <= act_send_data;
    end
  end else if (part_sum_send_en) begin
    out_data_valid    <= 1'b1;
    out_data[35:32]   <= `ROUTER_INFO_UV;
    out_data[31:16]   <= part_sum_send_addr;
    out_data[15:0]    <= part_sum_send_data;
  end else if (fin_comp) begin
    // special packet of `FIN_COMP`
    out_data_valid    <= 1'b1;
    out_data[35:32]   <= `ROUTER_INFO_FIN_COMP;
    out_data[31:16]   <= 0;
    out_data[15:0]    <= {10'b0, PE_IDX};   // embed the pe index into packet
  end else if (ni_read_rqst) begin
    // transmit the packet of READ local register files
    out_data_valid    <= 1'b1;
    out_data[35:32]   <= `ROUTER_INFO_READ;
    out_data[31:16]   <= {4'b0,ni_read_addr, PE_IDX};
    out_data[15:0]    <= out_act_data;      // embed the act value into packet
  end else begin
    out_data_valid    <= 1'b0;
    out_data          <= 0;
  end
end

// -------------------------------------------------------------
// Maintain the credit count for the downstreaming leaf router
// There are 4 cases to decrement the downstreaming credit
// a) act_send_en: broadcast an input activation
// b) fin_comp: send a `FIN_COMP` packet
// c) read_rqst_read_en: send a `READ` packet
// d) part_sum_send_en: send a `UV` packet
// -------------------------------------------------------------
reg [`CREDIT_CNT_WIDTH-1:0] credit_count;
wire credit_decre = act_send_en | fin_comp | read_rqst_read_en |
                    part_sum_send_en;
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    credit_count      <= `TOT_FIFO_DEPTH;
  end else begin
    case ({downstream_credit, credit_decre})
      2'b01: begin
        credit_count  <= credit_count - 1;
      end
      2'b10: begin
        credit_count  <= credit_count + 1;
      end
      default: begin
        credit_count  <= credit_count;
      end
    endcase
  end
end

assign router_rdy = (credit_count > 0);

endmodule
