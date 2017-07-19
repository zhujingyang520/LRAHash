// =============================================================================
// Module name: ProcessingElement
//
// This module exports the main processing element of the LRAHash neural network
// accelerator.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module ProcessingElement #(
  parameter   PE_IDX              = 0             // PE index
) (
  input wire                      clk,            // system clock
  input wire                      rst,            // syetem reset (active high)

  // data path from/to router
  input wire                      in_data_valid,  // input data valid
  input wire  [`ROUTER_WIDTH-1:0] in_data,        // input data
  output wire                     out_data_valid, // output data valid
  output wire [`ROUTER_WIDTH-1:0] out_data,       // output data

  // credit path from/to router
  input wire                      downstream_credit,
  output wire                     upstream_credit
);

// ----------------------------------------
// Interconnections of network interfaces
// ----------------------------------------
wire router_rdy;
wire act_send_en;
wire [`ROUTER_ADDR_WIDTH-1:0] act_send_addr;
wire [`PeDataBus] act_send_data;

// ---------------------------------------
// Interconnections of PE state registers
// ---------------------------------------
wire pe_status_we;
wire [`PeStatusAddrBus] pe_status_addr;
wire [`PeStatusDataBus] pe_status_data;
wire [`PeLayerNoBus] layer_no;
wire [`PeActNoBus] in_act_no;
wire [`PeActNoBus] out_act_no;

// ----------------------------------------------
// Interconnections of activation register files
// ----------------------------------------------
wire in_act_write_en;
wire [`PeActNoBus] in_act_write_addr;
wire [`PeDataBus] in_act_write_data;
wire in_act_read_en;
wire [`PeActNoBus] in_act_read_addr;
wire [`PeDataBus] in_act_read_data;
wire out_act_clear;

// -----------------------------------
// Interconnections of PE controller
// -----------------------------------
wire pe_start_calc;
wire fin_broadcast;
wire fin_comp;
wire layer_done;
wire [`PeLayerNoBus] layer_idx;

// -----------------------------------------
// Interconnections of PE activation queue
// -----------------------------------------
wire push_act;
wire [`PEQueueBus] act_in;
wire pop_act;
wire [`PEQueueBus] act_out;
wire queue_empty;

// -----------------------------------------
// Interconnections of computation datapath
// -----------------------------------------
// Stage 1: hash address computation
wire comp_en;
wire [`PeAddrBus] in_act_idx;
wire [`PeAddrBus] out_act_idx;
wire [`PeActNoBus] out_act_addr;
wire [`PeDataBus] in_act_value;
// Stage 2: memory access
wire comp_en_mem;
wire [`PeDataBus] in_act_value_mem;
wire [`PeActNoBus] out_act_addr_mem;
wire w_mem_cen;
wire w_mem_wen;
wire [`WMemAddrBus] w_mem_addr;
// Stage 3: multiply-accumulation (MAC)
wire comp_en_mac;
wire [`PeDataBus] in_act_value_mac;
wire [`PeDataBus] w_value_mac;
wire [`PeActNoBus] out_act_addr_mac;
wire [`PeDataBus] out_act_value_mac;
// Stage 4: output activation write back (WB)
wire comp_en_wb;
wire [`PeActNoBus] out_act_addr_wb;
wire [`PeDataBus] mac_result_wb;

// -------------------
// Network interface
// -------------------
NetworkInterface #(.PE_IDX(PE_IDX)) network_interface (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset (active high)

  // local port of the leaf router
  .in_data_valid      (in_data_valid),      // input data valid
  .in_data            (in_data),            // input data
  .out_data_valid     (out_data_valid),     // output data valid
  .out_data           (out_data),           // output data
  .downstream_credit  (downstream_credit),  // credit from downstream
  .upstream_credit    (upstream_credit),    // credit to upstream

  // configuration interfaces
  // pe status registers
  .pe_status_we       (pe_status_we),       // pe status write enable
  .pe_status_addr     (pe_status_addr),     // pe status write address
  .pe_status_data     (pe_status_data),     // pe status write data
  // input activation configuration
  .in_act_write_en    (in_act_write_en),    // input act write enable
  .in_act_write_addr  (in_act_write_addr),  // input act write address
  .in_act_write_data  (in_act_write_data),  // input act write data

  // PE controller interface
  .pe_start_calc      (pe_start_calc),      // PE start calculation
  .fin_broadcast      (fin_broadcast),      // finish broadcast act
  .router_rdy         (router_rdy),         // router is ready to send
  .fin_comp           (fin_comp),           // finish computation
  .act_send_en        (act_send_en),        // act send enable
  .act_send_addr      (act_send_addr),      // act send address
  .act_send_data      (act_send_data),      // act send data
  .layer_done         (layer_done),         // layer computation done

  // Activation queue interface
  .pop_act            (pop_act),            // pop activation
  .push_act           (push_act),           // push activation
  .act                (act_in)              // activation
);

// ---------------
// PE controller
// ---------------
PEController #(
  .PE_IDX             (PE_IDX)              // PE index
) pe_controller (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset

  .pe_start_calc      (pe_start_calc),      // start calculation
  .fin_broadcast      (fin_broadcast),      // finish broadcast act
  .fin_comp           (fin_comp),           // finish computation
  .layer_done         (layer_done),         // layer computation done

  // interfaces of PE state registers
  .layer_no           (layer_no),           // total layer no.
  .layer_idx          (layer_idx),          // layer index
  .in_act_no          (in_act_no),          // input activation no.
  .out_act_no         (out_act_no),         // output activation no.

  // interfaces of network interfaces
  .router_rdy         (router_rdy),         // router ready
  .act_send_en        (act_send_en),        // act send enable
  .act_send_addr      (act_send_addr),      // act send address
  .act_send_data      (act_send_data),      // act send data

  // activation register file
  .in_act_read_data   (in_act_read_data),   // in act read data
  .in_act_read_en     (in_act_read_en),     // in act read enable
  .in_act_read_addr   (in_act_read_addr),   // in act read address


  // interfaces of PE activation queue
  .queue_empty        (queue_empty),        // activation queue empty
  .act_out            (act_out),            // activation queue output
  .pop_act            (pop_act),            // activation queue pop
  .out_act_clear      (out_act_clear),      // output activation clear

  // computation datapath
  .comp_en            (comp_en),            // compute enable
  .in_act_idx         (in_act_idx),         // input activation idx
  .out_act_idx        (out_act_idx),        // output activation idx
  .out_act_addr       (out_act_addr),       // output activation address
  .in_act_value       (in_act_value)        // input activation value
);

// --------------------
// PE status registers
// --------------------
PEStateReg #(.PE_IDX(PE_IDX)) pe_state_reg (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset (active high)

  // configure data path
  .write_en           (pe_status_we),       // write enable (active high)
  .write_addr         (pe_status_addr),     // write address
  .write_data         (pe_status_data),     // write data

  // output DNN related parameters
  .layer_idx          (layer_idx),          // layer index
  .layer_no           (layer_no),           // layer number
  .in_act_no          (in_act_no),          // input activation no.
  .out_act_no         (out_act_no)          // output activation no.
  //output wire [`PeActNoBus]     act_no,   // activation number
  //output wire [`PeRealWNoBus]   real_w_no // real weight number
);

// ------------------------------------------------------
// Activation queue (store the activation value & index)
// ------------------------------------------------------
PEActQueue pe_act_queue (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset (active high)

  // interface of network interface
  .push_act           (push_act),           // push new activation to queue
  .act_in             (act_in),             // activation (with index)

  // interface of data path
  .pop_act            (pop_act),            // pop the activation
  .act_out            (act_out),            // activation @ head
  .queue_empty        (queue_empty)         // flag for empty queue
);

// ----------------------------------------
// Computation datapath: 3 pipeline stages
// ----------------------------------------
// Stage 1: Hash Engine for address computation
HashEngine #(.PE_IDX(PE_IDX)) hash_engine (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset (active high)

  // Input datapath
  .comp_en            (comp_en),            // computation enable
  .layer_idx          (layer_idx),          // layer index
  .in_act_idx         (in_act_idx),         // input activation index
  .out_act_idx        (out_act_idx),        // output activation index
  .out_act_addr       (out_act_addr),       // output activation address
  .in_act_value       (in_act_value),       // input activation value

  // Output datapath (memory stage)
  .comp_en_mem        (comp_en_mem),        // computation enable
  .in_act_value_mem   (in_act_value_mem),   // input activation value
  .out_act_addr_mem   (out_act_addr_mem),   // output activation address

  // Weight memory interfaces (active low)
  .w_mem_cen          (w_mem_cen),          // weight memory enable
  .w_mem_wen          (w_mem_wen),          // weight memory write enable
  .w_mem_addr         (w_mem_addr)          // weight memory address
);
// Stage 2: Memory Access (read weights from on-chip SRAM)
MemAccess mem_access (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset

  // Input datapath (memory stage)
  .comp_en_mem        (comp_en_mem),        // computation enable (mem)
  .in_act_value_mem   (in_act_value_mem),   // input activation value (mem)
  .out_act_addr_mem   (out_act_addr_mem),   // output activation address
  .w_mem_cen          (w_mem_cen),          // weight memory enable
  .w_mem_wen          (w_mem_wen),          // weight memory write enable
  .w_mem_addr         (w_mem_addr),         // weight memory address

  // output datapath (mac stage)
  .comp_en_mac        (comp_en_mac),        // computation enable (mac)
  .in_act_value_mac   (in_act_value_mac),   // input activation value (mac)
  .w_value_mac        (w_value_mac),        // weight value
  .out_act_addr_mac   (out_act_addr_mac)    // output activation address
);
// Stage 3: MAC operation
MAC mac (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset

  // Input datapath (mac stage)
  .comp_en_mac        (comp_en_mac),        // computation enable (mac)
  .in_act_value_mac   (in_act_value_mac),   // input activation value (mac)
  .w_value_mac        (w_value_mac),        // weight value (mac)
  .out_act_addr_mac   (out_act_addr_mac),   // output activation address(mac)
  .out_act_value_mac  (out_act_value_mac),  // output activation value (mac)

  // Output datapath (wb stage)
  .comp_en_wb         (comp_en_wb),         // computation enable (wb)
  .out_act_addr_wb    (out_act_addr_wb),    // output activation address(wb)
  .mac_result_wb      (mac_result_wb)       // mac result (wb)
);

// ----------------------------
// Activation register files
// ----------------------------
// TODO: finish connections
ActRegFile #(.PE_IDX(PE_IDX)) act_reg_file (
  .clk                (clk),                // system clock
  .dir                (`ACT_DIR_0),         // direction of in/out
  // input activations
  .in_act_clear       (1'b0),               // input activation clear
  .in_act_read_en     (in_act_read_en),     // read enable
  .in_act_read_addr   (in_act_read_addr),   // read address
  .in_act_read_data   (in_act_read_data),   // read data
  .in_act_write_en    (in_act_write_en),    // write enable
  .in_act_write_addr  (in_act_write_addr),  // write address
  .in_act_write_data  (in_act_write_data),  // write data
  .in_act_zeros       (),                   // zero flags
  // output activations
  .out_act_clear      (out_act_clear),      // output activation clear
  .out_act_read_en    (comp_en_mac),        // read enable
  .out_act_read_addr  (out_act_addr_mac),   // read address
  .out_act_read_data  (out_act_value_mac),  // read data
  .out_act_write_en   (comp_en_wb),         // write enable
  .out_act_write_addr (out_act_addr_wb),    // write address
  .out_act_write_data (mac_result_wb)       // write data
);

endmodule
