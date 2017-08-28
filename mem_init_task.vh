// -----------------------------------------------------------------------------
// This file exports the task that is used to configure the on-chip SRAM of
// accelerator
//
// The repeated patterns of readmem task are generated by the script!
// -----------------------------------------------------------------------------

`ifndef __MEM_INIT_TASK__
`define __MEM_INIT_TASK__

// ----------------------------------------------------------
// U memory SRAM initialization with the actual weights data
// Note: the file `mem_init` MUST be in the search path
// ----------------------------------------------------------
task u_mem_init;
  begin
    $readmemh("mem_init/u_mem_init_pe_0.dat", accelerator.gen_processing_element[0].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_1.dat", accelerator.gen_processing_element[1].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_2.dat", accelerator.gen_processing_element[2].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_3.dat", accelerator.gen_processing_element[3].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_4.dat", accelerator.gen_processing_element[4].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_5.dat", accelerator.gen_processing_element[5].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_6.dat", accelerator.gen_processing_element[6].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_7.dat", accelerator.gen_processing_element[7].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_8.dat", accelerator.gen_processing_element[8].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_9.dat", accelerator.gen_processing_element[9].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_10.dat", accelerator.gen_processing_element[10].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_11.dat", accelerator.gen_processing_element[11].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_12.dat", accelerator.gen_processing_element[12].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_13.dat", accelerator.gen_processing_element[13].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_14.dat", accelerator.gen_processing_element[14].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_15.dat", accelerator.gen_processing_element[15].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_16.dat", accelerator.gen_processing_element[16].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_17.dat", accelerator.gen_processing_element[17].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_18.dat", accelerator.gen_processing_element[18].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_19.dat", accelerator.gen_processing_element[19].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_20.dat", accelerator.gen_processing_element[20].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_21.dat", accelerator.gen_processing_element[21].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_22.dat", accelerator.gen_processing_element[22].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_23.dat", accelerator.gen_processing_element[23].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_24.dat", accelerator.gen_processing_element[24].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_25.dat", accelerator.gen_processing_element[25].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_26.dat", accelerator.gen_processing_element[26].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_27.dat", accelerator.gen_processing_element[27].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_28.dat", accelerator.gen_processing_element[28].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_29.dat", accelerator.gen_processing_element[29].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_30.dat", accelerator.gen_processing_element[30].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_31.dat", accelerator.gen_processing_element[31].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_32.dat", accelerator.gen_processing_element[32].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_33.dat", accelerator.gen_processing_element[33].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_34.dat", accelerator.gen_processing_element[34].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_35.dat", accelerator.gen_processing_element[35].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_36.dat", accelerator.gen_processing_element[36].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_37.dat", accelerator.gen_processing_element[37].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_38.dat", accelerator.gen_processing_element[38].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_39.dat", accelerator.gen_processing_element[39].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_40.dat", accelerator.gen_processing_element[40].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_41.dat", accelerator.gen_processing_element[41].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_42.dat", accelerator.gen_processing_element[42].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_43.dat", accelerator.gen_processing_element[43].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_44.dat", accelerator.gen_processing_element[44].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_45.dat", accelerator.gen_processing_element[45].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_46.dat", accelerator.gen_processing_element[46].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_47.dat", accelerator.gen_processing_element[47].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_48.dat", accelerator.gen_processing_element[48].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_49.dat", accelerator.gen_processing_element[49].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_50.dat", accelerator.gen_processing_element[50].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_51.dat", accelerator.gen_processing_element[51].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_52.dat", accelerator.gen_processing_element[52].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_53.dat", accelerator.gen_processing_element[53].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_54.dat", accelerator.gen_processing_element[54].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_55.dat", accelerator.gen_processing_element[55].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_56.dat", accelerator.gen_processing_element[56].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_57.dat", accelerator.gen_processing_element[57].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_58.dat", accelerator.gen_processing_element[58].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_59.dat", accelerator.gen_processing_element[59].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_60.dat", accelerator.gen_processing_element[60].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_61.dat", accelerator.gen_processing_element[61].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_62.dat", accelerator.gen_processing_element[62].processing_element.mem_access.u_mem.memory);
    $readmemh("mem_init/u_mem_init_pe_63.dat", accelerator.gen_processing_element[63].processing_element.mem_access.u_mem.memory);
  end
endtask

// ----------------------------------------------------------
// V memory SRAM initialization with the actual weights data
// Note: the file `mem_init` MUST be in the search path
// ----------------------------------------------------------
task v_mem_init;
  begin
    $readmemh("mem_init/v_mem_init_pe_0.dat", accelerator.gen_processing_element[0].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_1.dat", accelerator.gen_processing_element[1].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_2.dat", accelerator.gen_processing_element[2].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_3.dat", accelerator.gen_processing_element[3].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_4.dat", accelerator.gen_processing_element[4].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_5.dat", accelerator.gen_processing_element[5].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_6.dat", accelerator.gen_processing_element[6].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_7.dat", accelerator.gen_processing_element[7].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_8.dat", accelerator.gen_processing_element[8].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_9.dat", accelerator.gen_processing_element[9].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_10.dat", accelerator.gen_processing_element[10].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_11.dat", accelerator.gen_processing_element[11].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_12.dat", accelerator.gen_processing_element[12].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_13.dat", accelerator.gen_processing_element[13].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_14.dat", accelerator.gen_processing_element[14].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_15.dat", accelerator.gen_processing_element[15].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_16.dat", accelerator.gen_processing_element[16].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_17.dat", accelerator.gen_processing_element[17].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_18.dat", accelerator.gen_processing_element[18].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_19.dat", accelerator.gen_processing_element[19].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_20.dat", accelerator.gen_processing_element[20].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_21.dat", accelerator.gen_processing_element[21].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_22.dat", accelerator.gen_processing_element[22].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_23.dat", accelerator.gen_processing_element[23].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_24.dat", accelerator.gen_processing_element[24].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_25.dat", accelerator.gen_processing_element[25].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_26.dat", accelerator.gen_processing_element[26].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_27.dat", accelerator.gen_processing_element[27].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_28.dat", accelerator.gen_processing_element[28].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_29.dat", accelerator.gen_processing_element[29].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_30.dat", accelerator.gen_processing_element[30].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_31.dat", accelerator.gen_processing_element[31].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_32.dat", accelerator.gen_processing_element[32].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_33.dat", accelerator.gen_processing_element[33].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_34.dat", accelerator.gen_processing_element[34].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_35.dat", accelerator.gen_processing_element[35].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_36.dat", accelerator.gen_processing_element[36].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_37.dat", accelerator.gen_processing_element[37].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_38.dat", accelerator.gen_processing_element[38].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_39.dat", accelerator.gen_processing_element[39].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_40.dat", accelerator.gen_processing_element[40].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_41.dat", accelerator.gen_processing_element[41].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_42.dat", accelerator.gen_processing_element[42].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_43.dat", accelerator.gen_processing_element[43].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_44.dat", accelerator.gen_processing_element[44].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_45.dat", accelerator.gen_processing_element[45].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_46.dat", accelerator.gen_processing_element[46].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_47.dat", accelerator.gen_processing_element[47].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_48.dat", accelerator.gen_processing_element[48].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_49.dat", accelerator.gen_processing_element[49].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_50.dat", accelerator.gen_processing_element[50].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_51.dat", accelerator.gen_processing_element[51].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_52.dat", accelerator.gen_processing_element[52].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_53.dat", accelerator.gen_processing_element[53].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_54.dat", accelerator.gen_processing_element[54].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_55.dat", accelerator.gen_processing_element[55].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_56.dat", accelerator.gen_processing_element[56].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_57.dat", accelerator.gen_processing_element[57].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_58.dat", accelerator.gen_processing_element[58].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_59.dat", accelerator.gen_processing_element[59].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_60.dat", accelerator.gen_processing_element[60].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_61.dat", accelerator.gen_processing_element[61].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_62.dat", accelerator.gen_processing_element[62].processing_element.mem_access.v_mem.memory);
    $readmemh("mem_init/v_mem_init_pe_63.dat", accelerator.gen_processing_element[63].processing_element.mem_access.v_mem.memory);
  end
endtask

// ----------------------------------------------------------
// W memory SRAM initialization with the actual weights data
// Note: the file `mem_init` MUST be in the search path
// ----------------------------------------------------------
task w_mem_init;
  begin
    $readmemh("mem_init/w_mem_init_pe_0.dat", accelerator.gen_processing_element[0].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_1.dat", accelerator.gen_processing_element[1].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_2.dat", accelerator.gen_processing_element[2].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_3.dat", accelerator.gen_processing_element[3].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_4.dat", accelerator.gen_processing_element[4].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_5.dat", accelerator.gen_processing_element[5].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_6.dat", accelerator.gen_processing_element[6].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_7.dat", accelerator.gen_processing_element[7].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_8.dat", accelerator.gen_processing_element[8].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_9.dat", accelerator.gen_processing_element[9].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_10.dat", accelerator.gen_processing_element[10].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_11.dat", accelerator.gen_processing_element[11].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_12.dat", accelerator.gen_processing_element[12].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_13.dat", accelerator.gen_processing_element[13].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_14.dat", accelerator.gen_processing_element[14].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_15.dat", accelerator.gen_processing_element[15].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_16.dat", accelerator.gen_processing_element[16].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_17.dat", accelerator.gen_processing_element[17].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_18.dat", accelerator.gen_processing_element[18].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_19.dat", accelerator.gen_processing_element[19].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_20.dat", accelerator.gen_processing_element[20].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_21.dat", accelerator.gen_processing_element[21].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_22.dat", accelerator.gen_processing_element[22].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_23.dat", accelerator.gen_processing_element[23].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_24.dat", accelerator.gen_processing_element[24].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_25.dat", accelerator.gen_processing_element[25].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_26.dat", accelerator.gen_processing_element[26].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_27.dat", accelerator.gen_processing_element[27].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_28.dat", accelerator.gen_processing_element[28].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_29.dat", accelerator.gen_processing_element[29].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_30.dat", accelerator.gen_processing_element[30].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_31.dat", accelerator.gen_processing_element[31].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_32.dat", accelerator.gen_processing_element[32].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_33.dat", accelerator.gen_processing_element[33].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_34.dat", accelerator.gen_processing_element[34].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_35.dat", accelerator.gen_processing_element[35].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_36.dat", accelerator.gen_processing_element[36].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_37.dat", accelerator.gen_processing_element[37].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_38.dat", accelerator.gen_processing_element[38].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_39.dat", accelerator.gen_processing_element[39].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_40.dat", accelerator.gen_processing_element[40].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_41.dat", accelerator.gen_processing_element[41].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_42.dat", accelerator.gen_processing_element[42].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_43.dat", accelerator.gen_processing_element[43].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_44.dat", accelerator.gen_processing_element[44].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_45.dat", accelerator.gen_processing_element[45].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_46.dat", accelerator.gen_processing_element[46].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_47.dat", accelerator.gen_processing_element[47].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_48.dat", accelerator.gen_processing_element[48].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_49.dat", accelerator.gen_processing_element[49].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_50.dat", accelerator.gen_processing_element[50].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_51.dat", accelerator.gen_processing_element[51].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_52.dat", accelerator.gen_processing_element[52].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_53.dat", accelerator.gen_processing_element[53].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_54.dat", accelerator.gen_processing_element[54].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_55.dat", accelerator.gen_processing_element[55].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_56.dat", accelerator.gen_processing_element[56].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_57.dat", accelerator.gen_processing_element[57].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_58.dat", accelerator.gen_processing_element[58].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_59.dat", accelerator.gen_processing_element[59].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_60.dat", accelerator.gen_processing_element[60].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_61.dat", accelerator.gen_processing_element[61].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_62.dat", accelerator.gen_processing_element[62].processing_element.mem_access.w_mem.memory);
    $readmemh("mem_init/w_mem_init_pe_63.dat", accelerator.gen_processing_element[63].processing_element.mem_access.w_mem.memory);
  end
endtask


// ------------------------------------------
// W memory SRAM initialization with full 1s
// ------------------------------------------
task w_mem_init_full_ones;
  begin
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[0].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[1].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[2].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[3].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[4].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[5].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[6].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[7].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[8].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[9].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[10].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[11].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[12].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[13].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[14].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[15].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[16].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[17].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[18].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[19].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[20].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[21].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[22].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[23].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[24].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[25].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[26].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[27].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[28].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[29].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[30].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[31].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[32].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[33].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[34].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[35].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[36].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[37].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[38].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[39].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[40].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[41].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[42].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[43].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[44].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[45].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[46].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[47].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[48].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[49].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[50].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[51].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[52].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[53].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[54].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[55].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[56].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[57].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[58].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[59].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[60].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[61].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[62].
      processing_element.mem_access.w_mem.memory);
    $readmemb("w_init_ones.dat", accelerator.gen_processing_element[63].
      processing_element.mem_access.w_mem.memory);
  end
endtask

`endif

