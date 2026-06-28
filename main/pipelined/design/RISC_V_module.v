`timescale 1ns / 1ps

module pipelined_risc (
    input clk,
    input reset,
    output [9:0] pc_counter
);

    // --- MAIN DATAPATH WIRES ---
    wire [31:0] fetched_instruction;
    wire [9:0] pc;
    wire [31:0] d_au_in1, d_au_in2, logic_unit_in1, logic_unit_in2, shift_unit_in1, a_au_in1, a_au_in2;
    wire [4:0] shift_unit_in2, rd, rs1_wire, rs2_wire;
    wire [1:0] logic_unit_op, shift_unit_op;
    wire d_au_in1_type, d_au_in2_type, d_au_op, fmt_r, fmt_il, fmt_s, d_mem_en, d_mem_write_en, mem_read_wire, write_ex_result_to_rd, write_d_mem_out_to_rd;
    wire [2:0] funct3;
    wire [31:0] d_mem_write_data, d_au_res, log_res, shift_res, address_arith_res, d_mem_out, rd_write_data_from_wb;
    wire flag_lt, rd_write_en_from_wb;

    // --- HAZARD & FORWARDING WIRES ---
    wire stall;
    wire [1:0] fwdA, fwdB;
    wire [31:0] alu_in1_fwd, alu_in2_fwd, final_data_op_result, final_data_mem_address;
    
    // --- PIPELINE REGISTERS ---
    reg [9:0] if_id_pc;
    reg [31:0] if_id_instr;
    reg [31:0] id_ex_d_au_in1, id_ex_d_au_in2, id_ex_logic_in1, id_ex_logic_in2, id_ex_shift_in1, id_ex_a_au_in1, id_ex_a_au_in2, id_ex_d_mem_write_data, id_ex_instr;
    reg [4:0] id_ex_shift_in2, id_ex_rd, id_ex_rs1, id_ex_rs2;
    reg [2:0] id_ex_funct3;
    reg [1:0] id_ex_logic_op, id_ex_shift_op;
    reg id_ex_d_au_in1_type, id_ex_d_au_in2_type, id_ex_d_au_op, id_ex_fmt_r, id_ex_fmt_il, id_ex_fmt_s, id_ex_d_mem_en, id_ex_d_mem_write_en, id_ex_write_ex_to_rd, id_ex_write_mem_to_rd, id_ex_mem_read;
    reg [31:0] ex_mem_data_op_result, ex_mem_mem_address, ex_mem_write_data;
    reg [4:0] ex_mem_rd;
    reg [2:0] ex_mem_funct3;
    reg ex_mem_d_mem_en, ex_mem_d_mem_write_en, ex_mem_write_ex_to_rd, ex_mem_write_mem_to_rd;
    reg [31:0] mem_wb_data_op_result, mem_wb_read_data, mem_wb_mem_address;
    reg [4:0] mem_wb_rd;
    reg mem_wb_write_ex_to_rd, mem_wb_write_mem_to_rd;

    assign pc_counter = pc;

    // --- STAGE 1: FETCH ---
    fetch fetch_unit (.clk(clk), .fetch_en(~stall), .decision(1'b0), .clr(reset), .target(10'b0), .fetched_instruction(fetched_instruction), .pc(pc));
    // IF/ID Pipeline Register
    always @(posedge clk) begin
        if (reset) begin
            if_id_pc    <= 0;
            if_id_instr <= 0;
        end else if (!stall) begin
            // Capture the PC and the Instruction simultaneously
            if_id_pc    <= pc;
            if_id_instr <= fetched_instruction; 
        end
    end

    // --- STAGE 2: DECODE ---
    decoder_r_ld_st_stage decoder_unit (.inst(if_id_instr), .rd_write_data_from_wb(rd_write_data_from_wb), .rd_write_en_from_wb(rd_write_en_from_wb), .clock(clk), 
        .d_au_in1(d_au_in1), .d_au_in2(d_au_in2), .d_au_in1_type(d_au_in1_type), .d_au_in2_type(d_au_in2_type), .d_au_op(d_au_op), 
        .logic_unit_in1(logic_unit_in1), .logic_unit_in2(logic_unit_in2), .logic_unit_op(logic_unit_op), .shift_unit_in1(shift_unit_in1), .shift_unit_in2(shift_unit_in2), 
        .shift_unit_op(shift_unit_op), .a_au_in1(a_au_in1), .a_au_in2(a_au_in2), .fmt_r(fmt_r), .fmt_il(fmt_il), .fmt_s(fmt_s), .funct3(funct3), 
        .d_mem_write_data(d_mem_write_data), .d_mem_en(d_mem_en), .d_mem_write_en(d_mem_write_en), .rd(rd), .rs1(rs1_wire), .rs2(rs2_wire), .mem_read(mem_read_wire),
        .write_ex_result_to_rd(write_ex_result_to_rd), .write_d_mem_out_to_rd(write_d_mem_out_to_rd));

    always @(posedge clk) begin
        if (reset) begin id_ex_rd <= 0; id_ex_d_mem_en <= 0; id_ex_d_mem_write_en <= 0; id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_mem_read <= 0; end
        else if (!stall) begin
            id_ex_d_au_in1 <= d_au_in1; id_ex_d_au_in2 <= d_au_in2; id_ex_logic_in1 <= logic_unit_in1; id_ex_logic_in2 <= logic_unit_in2;
            id_ex_shift_in1 <= shift_unit_in1; id_ex_shift_in2 <= shift_unit_in2; id_ex_a_au_in1 <= a_au_in1; id_ex_a_au_in2 <= a_au_in2;
            id_ex_d_mem_write_data <= d_mem_write_data; id_ex_rd <= rd; id_ex_rs1 <= rs1_wire; id_ex_rs2 <= rs2_wire; id_ex_mem_read <= mem_read_wire;
            id_ex_funct3 <= funct3; id_ex_logic_op <= logic_unit_op; id_ex_shift_op <= shift_unit_op; id_ex_d_au_in1_type <= d_au_in1_type; 
            id_ex_d_au_in2_type <= d_au_in2_type; id_ex_d_au_op <= d_au_op; id_ex_fmt_r <= fmt_r; id_ex_fmt_il <= fmt_il; id_ex_fmt_s <= fmt_s;
            id_ex_d_mem_en <= d_mem_en; id_ex_d_mem_write_en <= d_mem_write_en; id_ex_write_ex_to_rd <= write_ex_result_to_rd; 
            id_ex_write_mem_to_rd <= write_d_mem_out_to_rd; id_ex_instr <= if_id_instr;
         
        end
        else 
            id_ex_mem_read <= 0;
    end

    // --- STAGE 3: EXECUTE ---
    assign alu_in1_fwd = (fwdA == 2'b10) ? ex_mem_data_op_result : (fwdA == 2'b01) ? rd_write_data_from_wb : id_ex_d_au_in1;
    assign alu_in2_fwd = (fwdB == 2'b10) ? ex_mem_data_op_result : (fwdB == 2'b01) ? rd_write_data_from_wb : id_ex_d_au_in2;

    arith_unit_data au_data (.operand_1(alu_in1_fwd), .operand_2(alu_in2_fwd), .operand_1_type(id_ex_d_au_in1_type), .operand_2_type(id_ex_d_au_in2_type), .operation(id_ex_d_au_op), .result_of_operation(d_au_res), .flag_lt(flag_lt));
    logic_unit lu (.operand_1(id_ex_logic_in1), .operand_2(id_ex_logic_in2), .operation(id_ex_logic_op), .result_of_operation(log_res));
    shift_unit su (.operand_1(id_ex_shift_in1), .operand_2(id_ex_shift_in2), .operation(id_ex_shift_op), .result_of_operation(shift_res));
    arith_unit_address au_addr (.operand_1(id_ex_a_au_in1), .operand_2(id_ex_a_au_in2), .address_arith_result(address_arith_res));
    
    hazard_detection_unit hazard_unit (.if_id_rs1(if_id_instr[19:15]), .if_id_rs2(if_id_instr[24:20]), .id_ex_mem_read(id_ex_mem_read), .id_ex_rd(id_ex_rd), .stall(stall));
    forwarding_unit fwd_unit (.EX_MEM_RegWrite(ex_mem_write_ex_to_rd | ex_mem_write_mem_to_rd), .EX_MEM_RegisterRD(ex_mem_rd), .ID_EX_RegisterRS1(id_ex_rs1), .ID_EX_RegisterRS2(id_ex_rs2), .MEM_WB_RegWrite(mem_wb_write_ex_to_rd | mem_wb_write_mem_to_rd), .MEM_WB_RegisterRD(mem_wb_rd), .ForwardA(fwdA), .ForwardB(fwdB));
    out_gen execute_multiplexer (.data_op_result(final_data_op_result), .data_mem_address(final_data_mem_address), .is_fmt_r(id_ex_fmt_r), .is_fmt_il(id_ex_fmt_il), .is_fmt_s(id_ex_fmt_s), .i_funct3(id_ex_funct3), .data_arith_result(d_au_res), .logic_result(log_res), .shift_result(shift_res), .flag_lt(flag_lt), .address_arith_result(address_arith_res));

    always @(posedge clk) begin
        if (reset) begin ex_mem_rd <= 0; ex_mem_d_mem_en <= 0; ex_mem_d_mem_write_en <= 0; ex_mem_write_ex_to_rd <= 0; ex_mem_write_mem_to_rd <= 0; end
        else begin
            ex_mem_data_op_result <= final_data_op_result; ex_mem_mem_address <= final_data_mem_address; ex_mem_write_data <= id_ex_d_mem_write_data;
            ex_mem_rd <= id_ex_rd; ex_mem_funct3 <= id_ex_funct3; ex_mem_d_mem_en <= id_ex_d_mem_en; ex_mem_d_mem_write_en <= id_ex_d_mem_write_en;
            ex_mem_write_ex_to_rd <= id_ex_write_ex_to_rd; ex_mem_write_mem_to_rd <= id_ex_write_mem_to_rd;
        end
    end
    reg [31:0] ex_mem_data_op_result, ex_mem_mem_address, ex_mem_write_data;
    reg [4:0]  ex_mem_rd;
    reg [2:0]  ex_mem_funct3;
    reg ex_mem_d_mem_en, ex_mem_d_mem_write_en, ex_mem_write_ex_to_rd, ex_mem_write_mem_to_rd;
    reg [31:0] write_data, read_data;
    always @(posedge clk) begin
        if (reset) begin
            ex_mem_rd <= 0; ex_mem_d_mem_en <= 0; ex_mem_d_mem_write_en <= 0;
            ex_mem_write_ex_to_rd <= 0; ex_mem_write_mem_to_rd <= 0;
        end else begin
            ex_mem_data_op_result <= final_data_op_result;
            ex_mem_mem_address <= final_data_mem_address;
            ex_mem_write_data <= id_ex_d_mem_write_data;
            ex_mem_rd <= id_ex_rd;
            ex_mem_funct3 <= id_ex_funct3;
            ex_mem_d_mem_en <= id_ex_d_mem_en;
            ex_mem_d_mem_write_en <= id_ex_d_mem_write_en;
            ex_mem_write_ex_to_rd <= id_ex_write_ex_to_rd;
            ex_mem_write_mem_to_rd <= id_ex_write_mem_to_rd;
        end
    end
    // data memory
    always @(*) begin
        case(ex_mem_funct3)
            3'b000: write_data = {24'b0, ex_mem_write_data[7:0]};   // SB
            3'b001: write_data = {16'b0, ex_mem_write_data[15:0]};  // SH
            default: write_data = ex_mem_write_data;                // SW
        endcase
    end

    data_mem_16kx8 dmem (
        .d_mem_address(ex_mem_mem_address[13:0]), 
        .d_mem_data_in(write_data),  
        .d_mem_en(ex_mem_d_mem_en), 
        .d_mem_write_en(ex_mem_d_mem_write_en), 
        .d_mem_clock(clk), 
        .d_mem_rw_size(2'b10), 
        .d_mem_out(d_mem_out) 
    );

    always @(*) begin
        case(ex_mem_funct3)
            3'b000: read_data = {{24{d_mem_out[7]}}, d_mem_out[7:0]};
            3'b001: read_data = {{16{d_mem_out[15]}}, d_mem_out[15:0]};
            3'b100: read_data = {24'b0, d_mem_out[7:0]};
            3'b101: read_data = {16'b0, d_mem_out[15:0]};
            default: read_data = d_mem_out;
        endcase
    end
    // write back
    reg [31:0] mem_wb_data_op_result, mem_wb_read_data, mem_wb_mem_address;
    reg [4:0]  mem_wb_rd;
    reg mem_wb_write_ex_to_rd, mem_wb_write_mem_to_rd;

    always @(posedge clk) begin
        if (reset) begin
            mem_wb_rd <= 0; mem_wb_write_ex_to_rd <= 0; mem_wb_write_mem_to_rd <= 0;
        end else begin
            mem_wb_data_op_result <= ex_mem_data_op_result;
            mem_wb_read_data <= read_data;
            mem_wb_mem_address <= ex_mem_mem_address;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_write_ex_to_rd <= ex_mem_write_ex_to_rd;
            mem_wb_write_mem_to_rd <= ex_mem_write_mem_to_rd;
        end
    end
    
    write_back_logic wb (
        .ex_unit_result(mem_wb_data_op_result), 
        .data_mem_output(mem_wb_read_data), 
        .ex_unit_result_write(mem_wb_write_ex_to_rd),
        .data_mem_output_write(mem_wb_write_mem_to_rd), 
        .funct3_val(3'b010), 
        .d_mem_address_2lsbs(mem_wb_mem_address[1:0]), 
        .rd_write_data(rd_write_data_from_wb), 
        .reg_file_write_en(rd_write_en_from_wb)
    );

endmodule