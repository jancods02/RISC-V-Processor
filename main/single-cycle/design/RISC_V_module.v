`timescale 1ns / 1ps

module single_cycle_risc (
    input clk,
    input reset,
    output [9:0] pc_counter
);
    
    wire [31:0] fetched_instruction;
    wire [9:0] pc;
    wire [31:0] d_au_in1, d_au_in2;
    wire d_au_in1_type, d_au_in2_type, d_au_op;
    wire [31:0] logic_unit_in1, logic_unit_in2;
    wire [1:0] logic_unit_op;
    wire [31:0] shift_unit_in1;
    wire [4:0] shift_unit_in2;
    wire [1:0] shift_unit_op;
    wire [31:0] a_au_in1, a_au_in2;
    wire fmt_r, fmt_il, fmt_s;
    wire [2:0] funct3;
    wire [31:0] d_mem_write_data;
    wire d_mem_en, d_mem_write_en;
    wire [4:0] rd;
    wire write_ex_result_to_rd, write_d_mem_out_to_rd;
    wire [31:0] d_au_res, log_res, shift_res, address_arith_res;
    wire flag_lt;
  
    wire [31:0] final_data_op_result;
    wire [31:0] final_data_mem_address;

  
    wire [31:0] d_mem_out;
    wire [31:0] rd_write_data_from_wb;
    wire rd_write_en_from_wb;
    
    assign pc_counter = pc; 
    
    // instruction fetch
    fetch fetch_unit (
        .clk(clk), 
        .fetch_en(1'b1), 
        .decision(1'b0), 
        .clr(reset), 
        .target(10'b0), 
        .fetched_instruction(fetched_instruction), 
        .pc(pc)
    );

    // instruction decoder
    decoder_r_ld_st_stage decoder_unit (
        .inst(fetched_instruction), 
        .rd_write_data_from_wb(rd_write_data_from_wb), 
        .rd_write_en_from_wb(rd_write_en_from_wb), 
        .clock(clk), 
        .d_au_in1(d_au_in1), .d_au_in2(d_au_in2), 
        .d_au_in1_type(d_au_in1_type), .d_au_in2_type(d_au_in2_type), 
        .d_au_op(d_au_op), 
        .logic_unit_in1(logic_unit_in1), .logic_unit_in2(logic_unit_in2), 
        .logic_unit_op(logic_unit_op), 
        .shift_unit_in1(shift_unit_in1), .shift_unit_in2(shift_unit_in2), 
        .shift_unit_op(shift_unit_op), 
        .a_au_in1(a_au_in1), .a_au_in2(a_au_in2), 
        .fmt_r(fmt_r), .fmt_il(fmt_il), .fmt_s(fmt_s), 
        .funct3(funct3), 
        .d_mem_write_data(d_mem_write_data),  
        .d_mem_en(d_mem_en), .d_mem_write_en(d_mem_write_en), 
        .rd(rd), 
        .write_ex_result_to_rd(write_ex_result_to_rd), 
        .write_d_mem_out_to_rd(write_d_mem_out_to_rd)
    );

   // execute stage
    arith_unit_data au_data (
        .operand_1(d_au_in1), .operand_2(d_au_in2), 
        .operand_1_type(d_au_in1_type), .operand_2_type(d_au_in2_type), 
        .operation(d_au_op), 
        .result_of_operation(d_au_res), 
        .flag_lt(flag_lt)
    );

    logic_unit lu (
        .operand_1(logic_unit_in1), .operand_2(logic_unit_in2), 
        .operation(logic_unit_op), 
        .result_of_operation(log_res)
    );

    shift_unit su (
        .operand_1(shift_unit_in1), .operand_2(shift_unit_in2), 
        .operation(shift_unit_op), 
        .result_of_operation(shift_res)
    );

    arith_unit_address au_addr (
        .operand_1(a_au_in1), .operand_2(a_au_in2), 
        .address_arith_result(address_arith_res)
    );

    // output selector
    out_gen execute_multiplexer (
        .data_op_result(final_data_op_result),
        .data_mem_address(final_data_mem_address),
        .is_fmt_r(fmt_r), 
        .is_fmt_il(fmt_il), 
        .is_fmt_s(fmt_s), 
        .i_funct3(funct3), 
        .data_arith_result(d_au_res),
        .logic_result(log_res), 
        .shift_result(shift_res), 
        .flag_lt(flag_lt), 
        .address_arith_result(address_arith_res)
    );

    // data memory
    data_mem_16kx8 dmem (
        .d_mem_address(final_data_mem_address[13:0]), 
        .d_mem_data_in(d_mem_write_data), 
        .d_mem_en(d_mem_en), 
        .d_mem_write_en(d_mem_write_en), 
        .d_mem_clock(clk), 
        .d_mem_rw_size(funct3[1:0]), 
        .d_mem_out(d_mem_out)
    );

    // write back
    write_back_logic wb (
        .ex_unit_result(final_data_op_result), 
        .data_mem_output(d_mem_out), 
        .ex_unit_result_write(write_ex_result_to_rd),
        .data_mem_output_write(write_d_mem_out_to_rd), 
        .funct3_val(funct3), 
        .d_mem_address_2lsbs(final_data_mem_address[1:0]), 
        .rd_write_data(rd_write_data_from_wb), 
        .reg_file_write_en(rd_write_en_from_wb)
    );

endmodule