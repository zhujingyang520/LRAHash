// =============================================================================
// Module name: ProcessingElement
//
// This module exports the main processing element of the LRAHash neural network
// accelerator.
// =============================================================================

`include "pe.vh"
`include "router.vh"

module ProcessingElement (
  input wire  [5:0]               PE_IDX,         // PE index
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
wire ni_read_rqst;
wire [`PeActNoBus] ni_read_addr;
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
wire act_regfile_dir;
wire in_act_write_en;
wire [`PeActNoBus] in_act_write_addr;
wire [`PeDataBus] in_act_write_data;
wire [`PE_ACT_NO-1:0] in_act_zeros;
wire in_act_read_en;
wire [`PeActNoBus] in_act_read_addr;
wire [`PeDataBus] in_act_read_data;
wire out_act_clear;
wire out_act_read_en;
wire [`PeActNoBus] out_act_read_addr;
wire [`PeDataBus] out_act_read_data;

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
// Stage 1: memory address computation
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
// Stage 3: multiplication (MULT)
wire comp_en_mult;
wire [`PeDataBus] in_act_value_mult;
wire [`PeDataBus] w_value_mult;
wire [`PeActNoBus] out_act_addr_mult;
// Stage 4: addition (ADD)
wire comp_en_add;
wire [`PeDataBus] mult_result_add;
wire [`PeActNoBus] out_act_addr_add;
// Stage 5: output activation write back (WB)
wire comp_en_wb;
wire [`PeActNoBus] out_act_addr_wb;
wire [`PeDataBus] add_result_wb;

// -------------------
// Network interface
// -------------------
NetworkInterface network_interface (
  .PE_IDX             (PE_IDX),             // PE index
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
  .out_act_no         (out_act_no),         // output activation no.
  // input activation configuration
  .in_act_write_en    (in_act_write_en),    // input act write enable
  .in_act_write_addr  (in_act_write_addr),  // input act write address
  .in_act_write_data  (in_act_write_data),  // input act write data

  // read request interface (to activation register file)
  .ni_read_rqst       (ni_read_rqst),       // read request
  .ni_read_addr       (ni_read_addr),       // read address
  .out_act_read_data  (out_act_read_data),  // output activation read

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
PEController pe_controller (
  .PE_IDX             (PE_IDX),             // PE index
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

  // interfaces of activation register file
  .act_regfile_dir    (act_regfile_dir),    // act regfile direction

  // interfaces of network interfaces
  .router_rdy         (router_rdy),         // router ready
  .act_send_en        (act_send_en),        // act send enable
  .act_send_addr      (act_send_addr),      // act send address
  .act_send_data      (act_send_data),      // act send data

  // activation register file
  .in_act_read_data   (in_act_read_data),   // in act read data
  .in_act_read_en     (in_act_read_en),     // in act read enable
  .in_act_read_addr   (in_act_read_addr),   // in act read address
  .in_act_zeros       (in_act_zeros),       // in act zero flags

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
PEStateReg pe_state_reg (
  .PE_IDX             (PE_IDX),             // PE index
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
// Computation datapath: 5 pipeline stages
// ----------------------------------------
// Stage 1: on-chip SRAM address computation
MemAddrComp mem_addr_comp (
  .PE_IDX             (PE_IDX),             // PE index
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset (active high)

  // Input datapath & control path
  .comp_en            (comp_en),            // computation enable
  .layer_idx          (layer_idx),          // layer index
  .in_act_idx         (in_act_idx),         // input activation index
  .out_act_idx        (out_act_idx),        // output activation index
  .out_act_addr       (out_act_addr),       // output activation address
  .in_act_value       (in_act_value),       // input activation value

  // Output datapath & control path (memory stage)
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

  // Input datapath & control path (memory stage)
  .comp_en_mem        (comp_en_mem),        // computation enable (mem)
  .in_act_value_mem   (in_act_value_mem),   // input activation value (mem)
  .out_act_addr_mem   (out_act_addr_mem),   // output activation address
  .w_mem_cen          (w_mem_cen),          // weight memory enable
  .w_mem_wen          (w_mem_wen),          // weight memory write enable
  .w_mem_addr         (w_mem_addr),         // weight memory address

  // Output datapath & control path (mult stage)
  .comp_en_mult       (comp_en_mult),       // computation enable (mult)
  .in_act_value_mult  (in_act_value_mult),  // input activation value (mult)
  .w_value_mult       (w_value_mult),       // weight value
  .out_act_addr_mult  (out_act_addr_mult)   // output activation address
);
// Stage 3: activation & weights multiplication (MULT)
Mult mult (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset (active high)

  // Input datapath & control path (mult stage)
  .comp_en_mult       (comp_en_mult),       // computation enable
  .in_act_value_mult  (in_act_value_mult),  // input activation value
  .w_value_mult       (w_value_mult),       // weight value
  .out_act_addr_mult  (out_act_addr_mult),  // output activation address

  // Output datapath & control path (add stage)
  .comp_en_add        (comp_en_add),        // computation enable
  .out_act_addr_add   (out_act_addr_add),   // output activation address
  .mult_result_add    (mult_result_add)     // multiplication result
);
// Stage 4: activation accumulation (ADD)
Add add (
  .clk                (clk),                // system clock
  .rst                (rst),                // system reset (active high)

  // Input datapath & control path (add stage)
  .comp_en_add        (comp_en_add),        // computation enable
  .out_act_value_add  (out_act_read_data),  // output activation value
  .mult_result_add    (mult_result_add),    // multiplication result
  .out_act_addr_add   (out_act_addr_add),   // output activation address

  // Output datapath & control path (wb stage)
  .comp_en_wb         (comp_en_wb),         // computation enable
  .out_act_addr_wb    (out_act_addr_wb),    // output activation address
  .add_result_wb      (add_result_wb)       // addition result
);

// Stage 5: Write back (wb)
// ----------------------------
// Activation register files
// ----------------------------
// TODO: finish connections
ActRegFile act_reg_file (
  .PE_IDX             (PE_IDX),             // PE index
  .clk                (clk),                // system clock
  .dir                (act_regfile_dir),    // direction of in/out
  // input activations
  .in_act_clear       (1'b0),               // input activation clear
  .in_act_read_en     (in_act_read_en),     // read enable
  .in_act_read_addr   (in_act_read_addr),   // read address
  .in_act_read_data   (in_act_read_data),   // read data
  .in_act_write_en    (in_act_write_en),    // write enable
  .in_act_write_addr  (in_act_write_addr),  // write address
  .in_act_write_data  (in_act_write_data),  // write data
  .in_act_zeros       (in_act_zeros),       // zero flags
  // output activations
  .out_act_clear      (out_act_clear),      // output activation clear
  .out_act_read_en    (out_act_read_en),    // read enable
  .out_act_read_addr  (out_act_read_addr),  // read address
  .out_act_read_data  (out_act_read_data),  // read data
  .out_act_write_en   (comp_en_wb),         // write enable
  .out_act_write_addr (out_act_addr_wb),    // write address
  .out_act_write_data (add_result_wb)       // write data
);
// Activation Read Mux Logic
ActRegFileOutMux act_reg_file_out_mux (
  .comp_en_add        (comp_en_add),        // computation enable (ADD)
  .out_act_addr_add   (out_act_addr_add),   // output activation address
  .ni_read_rqst       (ni_read_rqst),       // network interface read rqst
  .ni_read_addr       (ni_read_addr),       // network interface read addr

  .out_act_read_en    (out_act_read_en),    // output act read enable
  .out_act_read_addr  (out_act_read_addr)   // output act read address
);

endmodule
