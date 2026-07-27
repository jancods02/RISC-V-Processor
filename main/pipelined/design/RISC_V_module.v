`timescale 1ns / 1ps

module pipelined_risc (
    input clk,
    input reset,
    output [9:0] pc_counter
);

    wire [31:0] fetched_instruction;
    wire [9:0] pc;
    wire [31:0] pc_plus_4_current;
    
    // --- Stage 2 (Decode) Wires ---
    wire [31:0] d_au_in1, d_au_in2, logic_unit_in1, logic_unit_in2, shift_unit_in1, a_au_in1, a_au_in2;
    wire [4:0] shift_unit_in2, rd, rs1_wire, rs2_wire;
    wire [1:0] logic_unit_op, shift_unit_op;
    wire d_au_in1_type, d_au_in2_type, d_au_op, fmt_r, fmt_il, fmt_s;
    wire d_mem_en, d_mem_write_en, mem_read_wire, write_ex_result_to_rd, write_d_mem_out_to_rd;
    wire [2:0] funct3;
    wire [31:0] d_mem_write_data;
    
    wire stall;
    reg  stall_delayed; 
    wire is_branch;
    wire [31:0] branch_imm;
    wire is_jal;
    wire [9:0] branch_target;
    wire branch_taken;
    wire [1:0] fwdA, fwdB;
    wire [31:0] alu_in1_fwd, alu_in2_fwd;
    wire [31:0] d_au_res, log_res, shift_res, address_arith_res;
    wire flag_lt;
    wire [31:0] intermediate_op_result;
    wire [31:0] final_data_op_result, final_data_mem_address;

    // --- Stage 4 (Memory) Wires ---
    wire [31:0] d_mem_out;

    // --- Stage 5 (Write-Back) Wires ---
    wire [31:0] rd_write_data_from_wb;
    wire rd_write_en_from_wb;

    // --- Pipeline Register Declarations ---
    reg [9:0]  if_id_pc;
    reg [31:0] if_id_instr;
    reg [31:0] if_id_pc_plus_4;

    reg [31:0] id_ex_d_au_in1, id_ex_d_au_in2;
    reg [31:0] id_ex_logic_in1, id_ex_logic_in2;
    reg [31:0] id_ex_shift_in1;
    reg [4:0]  id_ex_shift_in2;
    reg [31:0] id_ex_a_au_in1, id_ex_a_au_in2;
    reg [31:0] id_ex_d_mem_write_data;
    reg [4:0]  id_ex_rd, id_ex_rs1, id_ex_rs2;
    reg [2:0]  id_ex_funct3;
    reg [1:0]  id_ex_logic_op, id_ex_shift_op;
    reg        id_ex_d_au_in1_type, id_ex_d_au_in2_type, id_ex_d_au_op, id_ex_fmt_r, id_ex_fmt_il, id_ex_fmt_s;
    reg        id_ex_d_mem_en, id_ex_d_mem_write_en, id_ex_mem_read, id_ex_write_ex_to_rd, id_ex_write_mem_to_rd;
    reg        id_ex_is_branch, id_ex_is_jal;
    reg [9:0]  id_ex_pc;
    reg [31:0] id_ex_branch_imm;
    reg [31:0] id_ex_instr;
    reg [31:0] id_ex_pc_plus_4;

    reg [4:0]  ex_mem_rd;
    reg        ex_mem_d_mem_en, ex_mem_d_mem_write_en;
    reg        ex_mem_write_ex_to_rd, ex_mem_write_mem_to_rd;
    reg [31:0] ex_mem_data_op_result;
    reg [31:0] ex_mem_mem_address;
    reg [31:0] ex_mem_write_data;
    reg [2:0]  ex_mem_funct3;
    reg [31:0] ex_mem_pc_plus_4;

    reg [31:0] mem_wb_data_op_result, mem_wb_read_data, mem_wb_mem_address;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_write_ex_to_rd, mem_wb_write_mem_to_rd;
    reg [2:0]  mem_wb_funct3; 
    reg [31:0] mem_wb_pc_plus_4;

    // Continuous assignment for tracking program counter
    assign pc_counter = pc;
    assign pc_plus_4_current = {{22{1'b0}}, (pc + 4)};

    
    fetch fetch_unit (
        .clk(clk), 
        .fetch_en(~stall || branch_taken), 
        .decision(branch_taken), 
        .clr(reset), 
        .target(branch_target), 
        .fetched_instruction(fetched_instruction), 
        .pc(pc)
    );

    // --- IF/ID Pipeline Register Synchronizer ---
    always @(posedge clk) begin
        if (reset) 
            stall_delayed <= 1'b0;
        else 
            stall_delayed <= stall;
    end

    always @(posedge clk) begin
        if (reset) begin
            if_id_pc         <= 10'd0;
            if_id_instr      <= 32'h00000033; // Default safe RISC-V NOP (addi x0, x0, 0)
            if_id_pc_plus_4  <= 32'd0;
        end else if (branch_taken) begin
            if_id_pc         <= 10'd0;
            if_id_instr      <= 32'h00000033; 
            if_id_pc_plus_4  <= 32'd0;
        end else if (stall || stall_delayed) begin
            if_id_pc         <= if_id_pc;
            if_id_instr      <= if_id_instr;
            if_id_pc_plus_4  <= if_id_pc_plus_4;
        end else begin
            if_id_pc         <= pc;
            if_id_instr      <= fetched_instruction;
            if_id_pc_plus_4  <= pc_plus_4_current;
        end
    end
    
    decoder_r_ld_st_stage decoder_unit (
        .inst(if_id_instr), 
        .rd_write_data_from_wb(rd_write_data_from_wb), 
        .rd_write_en_from_wb(rd_write_en_from_wb), 
        .rd_wb_index(mem_wb_rd),
        .clk(clk), 
        .d_au_in1(d_au_in1), 
        .d_au_in2(d_au_in2), 
        .d_au_in1_type(d_au_in1_type), 
        .d_au_in2_type(d_au_in2_type), 
        .d_au_op(d_au_op), 
        .logic_unit_in1(logic_unit_in1), 
        .logic_unit_in2(logic_unit_in2), 
        .logic_unit_op(logic_unit_op), 
        .shift_unit_in1(shift_unit_in1), 
        .shift_unit_in2(shift_unit_in2), 
        .shift_unit_op(shift_unit_op), 
        .a_au_in1(a_au_in1), 
        .a_au_in2(a_au_in2), 
        .fmt_r(fmt_r), 
        .fmt_il(fmt_il), 
        .fmt_s(fmt_s), 
        .funct3(funct3), 
        .d_mem_write_data(d_mem_write_data), 
        .d_mem_en(d_mem_en), 
        .d_mem_write_en(d_mem_write_en), 
        .rd(rd), 
        .rs1(rs1_wire), 
        .rs2(rs2_wire), 
        .mem_read(mem_read_wire), 
        .is_branch(is_branch), 
        .branch_imm(branch_imm), 
        .write_ex_result_to_rd(write_ex_result_to_rd), 
        .write_d_mem_out_to_rd(write_d_mem_out_to_rd)
    );

    assign is_jal = (if_id_instr[6:0] == 7'h6f) ? 1'b1 : 1'b0;

    // --- ID/EX Pipeline Registers ---
    always @(posedge clk) begin
        if (reset || branch_taken) begin
            id_ex_d_au_in1         <= 32'd0; 
            id_ex_d_au_in2         <= 32'd0;
            id_ex_logic_in1        <= 32'd0; 
            id_ex_logic_in2        <= 32'd0;
            id_ex_shift_in1        <= 32'd0; 
            id_ex_shift_in2        <= 5'd0;
            id_ex_a_au_in1         <= 32'd0; 
            id_ex_a_au_in2         <= 32'd0;
            id_ex_d_mem_write_data <= 32'd0;
            id_ex_rd               <= 5'd0; 
            id_ex_rs1              <= 5'd0; 
            id_ex_rs2              <= 5'd0;
            id_ex_d_mem_en         <= 1'b0; 
            id_ex_d_mem_write_en   <= 1'b0; 
            id_ex_mem_read         <= 1'b0;
            id_ex_is_branch        <= 1'b0; 
            id_ex_is_jal           <= 1'b0;
            id_ex_pc               <= 10'd0; 
            id_ex_branch_imm       <= 32'd0;
            id_ex_instr            <= 32'h00000033; // Inject NOP
            id_ex_write_ex_to_rd   <= 1'b0;
            id_ex_write_mem_to_rd  <= 1'b0;
            id_ex_funct3           <= 3'd0; 
            id_ex_logic_op         <= 2'd0; 
            id_ex_shift_op         <= 2'd0;
            id_ex_d_au_in1_type    <= 1'b0; 
            id_ex_d_au_in2_type    <= 1'b0; 
            id_ex_d_au_op          <= 1'b0;
            id_ex_fmt_r            <= 1'b0; 
            id_ex_fmt_il           <= 1'b0; 
            id_ex_fmt_s            <= 1'b0;
            id_ex_pc_plus_4        <= 32'd0;
        end else if (stall) begin
            // Stall: Insert structural pipeline bubble into EX stage without clearing registers
            id_ex_d_au_in1         <= 32'd0; 
            id_ex_d_au_in2         <= 32'd0;
            id_ex_logic_in1        <= 32'd0; 
            id_ex_logic_in2        <= 32'd0;
            id_ex_shift_in1        <= 32'd0; 
            id_ex_shift_in2        <= 5'd0;
            id_ex_a_au_in1         <= 32'd0; 
            id_ex_a_au_in2         <= 32'd0;
            id_ex_d_mem_write_data <= 32'd0;
            id_ex_rd               <= 5'd0; 
            id_ex_rs1              <= 5'd0; 
            id_ex_rs2              <= 5'd0;
            id_ex_d_mem_en         <= 1'b0; 
            id_ex_d_mem_write_en   <= 1'b0; 
            id_ex_mem_read         <= 1'b0;
            id_ex_is_branch        <= 1'b0; 
            id_ex_is_jal           <= 1'b0;
            id_ex_pc               <= 10'd0; 
            id_ex_branch_imm       <= 32'd0;
            id_ex_instr            <= 32'h00000033; // Safe NOP
            id_ex_write_ex_to_rd   <= 1'b0; 
            id_ex_write_mem_to_rd  <= 1'b0; 
            id_ex_funct3           <= 3'd0; 
            id_ex_logic_op         <= 2'd0; 
            id_ex_shift_op         <= 2'd0;
            id_ex_d_au_in1_type    <= 1'b0; 
            id_ex_d_au_in2_type    <= 1'b0; 
            id_ex_d_au_op          <= 1'b0;
            id_ex_fmt_r            <= 1'b0; 
            id_ex_fmt_il           <= 1'b0; 
            id_ex_fmt_s            <= 1'b0;
            id_ex_pc_plus_4        <= 32'd0;
        end else begin
            id_ex_d_au_in1         <= d_au_in1;
            id_ex_d_au_in2         <= d_au_in2;
            id_ex_logic_in1        <= logic_unit_in1;
            id_ex_logic_in2        <= logic_unit_in2;
            id_ex_shift_in1        <= shift_unit_in1;
            id_ex_shift_in2        <= shift_unit_in2;
            id_ex_a_au_in1         <= a_au_in1;
            id_ex_a_au_in2         <= a_au_in2;
            id_ex_d_mem_write_data <= d_mem_write_data;
            id_ex_rd               <= rd; 
            id_ex_rs1              <= rs1_wire;
            id_ex_rs2              <= rs2_wire;
            id_ex_mem_read         <= mem_read_wire;
            id_ex_funct3           <= funct3;
            id_ex_logic_op         <= logic_unit_op;
            id_ex_shift_op         <= shift_unit_op;
            id_ex_d_au_in1_type    <= d_au_in1_type;
            id_ex_d_au_in2_type    <= d_au_in2_type;
            id_ex_d_au_op          <= d_au_op;
            id_ex_fmt_r            <= fmt_r;
            id_ex_fmt_il           <= fmt_il;
            id_ex_fmt_s            <= fmt_s;
            id_ex_d_mem_en         <= d_mem_en;
            id_ex_d_mem_write_en   <= d_mem_write_en;
            id_ex_write_ex_to_rd   <= write_ex_result_to_rd;
            id_ex_write_mem_to_rd  <= write_d_mem_out_to_rd;
            id_ex_instr            <= if_id_instr;
            id_ex_is_branch        <= is_branch;
            id_ex_is_jal           <= is_jal;
            id_ex_pc               <= if_id_pc;
            id_ex_branch_imm       <= branch_imm;
            id_ex_pc_plus_4        <= if_id_pc_plus_4;
        end
    end

    // Data Forwarding Multiplexers
    assign alu_in1_fwd = (fwdA == 2'b10) ? ex_mem_data_op_result : 
                         (fwdA == 2'b01) ? rd_write_data_from_wb : 
                                           id_ex_d_au_in1;

    assign alu_in2_fwd = (id_ex_fmt_il || id_ex_fmt_s) ? id_ex_d_au_in2 :
                         (fwdB == 2'b10) ? ex_mem_data_op_result : 
                         (fwdB == 2'b01) ? rd_write_data_from_wb : 
                                           id_ex_d_au_in2;

    arith_unit_data au_data (
        .operand_1(alu_in1_fwd), .operand_2(alu_in2_fwd), 
        .operand_1_type(id_ex_d_au_in1_type), .operand_2_type(id_ex_d_au_in2_type), 
        .operation(id_ex_d_au_op), .result_of_operation(d_au_res), .flag_lt(flag_lt)
    );

    logic_unit lu (
        .operand_1(alu_in1_fwd), .operand_2(alu_in2_fwd), 
        .operation(id_ex_logic_op), .result_of_operation(log_res)
    );

    // Connected to dedicated pipelined register id_ex_shift_in2
    shift_unit su (
        .operand_1(alu_in1_fwd), .operand_2(id_ex_shift_in2), 
        .operation(id_ex_shift_op), .result_of_operation(shift_res)
    );

    arith_unit_address au_addr (
        .operand_1(alu_in1_fwd), .operand_2(id_ex_a_au_in2), 
        .address_arith_result(address_arith_res)
    );

    hazard_detection_unit hazard_unit (
        .if_id_rs1(if_id_instr[19:15]), .if_id_rs2(if_id_instr[24:20]), 
        .id_ex_mem_read(id_ex_mem_read), .id_ex_rd(id_ex_rd), .stall(stall)
    );

    wire ex_mem_reg_write_wire = ex_mem_write_ex_to_rd | ex_mem_write_mem_to_rd;
    
    forwarding_unit fwd_unit (
        .EX_MEM_RegWrite(ex_mem_reg_write_wire), .EX_MEM_RegisterRD(ex_mem_rd), 
        .ID_EX_RegisterRS1(id_ex_rs1), .ID_EX_RegisterRS2(id_ex_rs2), 
        .MEM_WB_RegWrite(rd_write_en_from_wb), .MEM_WB_RegisterRD(mem_wb_rd), 
        .ForwardA(fwdA), .ForwardB(fwdB)
    );
  
    out_gen execute_multiplexer (
        .data_op_result(intermediate_op_result), .data_mem_address(final_data_mem_address), 
        .is_fmt_r(id_ex_fmt_r), .is_fmt_il(id_ex_fmt_il), .is_fmt_s(id_ex_fmt_s), .i_funct3(id_ex_funct3), 
        .data_arith_result(d_au_res), .logic_result(log_res), .shift_result(shift_res), 
        .flag_lt(flag_lt), .address_arith_result(address_arith_res)
    );

    assign final_data_op_result = (id_ex_is_jal) ? id_ex_pc_plus_4 : intermediate_op_result;

    assign branch_taken  = ((id_ex_is_branch && flag_lt) || id_ex_is_jal) && (id_ex_instr != 32'h00000033);
    
    // Explicit signed casting prevents arithmetic truncation during backward relative loops
    wire signed [9:0] signed_imm_10b = id_ex_branch_imm[9:0];
    assign branch_target = $unsigned($signed(id_ex_pc) + signed_imm_10b);

    // --- EX/MEM Pipeline Registers ---
    always @(posedge clk) begin
        if (reset) begin
            ex_mem_rd              <= 5'd0;
            ex_mem_d_mem_en        <= 1'b0;
            ex_mem_d_mem_write_en  <= 1'b0;
            ex_mem_write_ex_to_rd  <= 1'b0;
            ex_mem_write_mem_to_rd <= 1'b0;
            ex_mem_data_op_result  <= 32'd0;
            ex_mem_mem_address     <= 32'd0;
            ex_mem_write_data      <= 32'd0;
            ex_mem_funct3          <= 3'd0;
            ex_mem_pc_plus_4       <= 32'd0;
        end else begin
            ex_mem_data_op_result  <= final_data_op_result;
            ex_mem_mem_address     <= final_data_mem_address;
            ex_mem_write_data      <= alu_in2_fwd;
            ex_mem_funct3          <= id_ex_funct3;
            ex_mem_d_mem_en        <= id_ex_d_mem_en;
            ex_mem_d_mem_write_en  <= id_ex_d_mem_write_en;
            ex_mem_pc_plus_4       <= id_ex_pc_plus_4;
            
            // Architectural Guard: Hard wall against writing to x0
            if (id_ex_rd == 5'd0) begin
                ex_mem_rd              <= 5'd0;
                ex_mem_write_ex_to_rd  <= 1'b0;
                ex_mem_write_mem_to_rd <= 1'b0;
            end else begin
                ex_mem_rd              <= id_ex_rd;
                ex_mem_write_ex_to_rd  <= id_ex_write_ex_to_rd;
                ex_mem_write_mem_to_rd <= id_ex_write_mem_to_rd;
            end
        end
    end

    
    data_mem_16kx8 data_mem_unit (
        .d_mem_address(ex_mem_mem_address[13:0]), .d_mem_data_in(ex_mem_write_data), 
        .d_mem_en(ex_mem_d_mem_en), .d_mem_write_en(ex_mem_d_mem_write_en), .d_mem_clock(clk), 
        .d_mem_rw_size(ex_mem_funct3[1:0]), .d_mem_out(d_mem_out)
    );

    // --- MEM/WB Pipeline Registers ---
    always @(posedge clk) begin
        if (reset) begin
            mem_wb_rd              <= 5'd0;
            mem_wb_write_ex_to_rd  <= 1'b0;
            mem_wb_write_mem_to_rd <= 1'b0;
            mem_wb_data_op_result  <= 32'd0;
            mem_wb_read_data       <= 32'd0;
            mem_wb_mem_address     <= 32'd0;
            mem_wb_funct3          <= 3'd0;
            mem_wb_pc_plus_4       <= 32'd0;
        end else begin
            mem_wb_data_op_result  <= ex_mem_data_op_result;
            mem_wb_read_data       <= d_mem_out; 
            mem_wb_mem_address     <= ex_mem_mem_address;
            mem_wb_rd              <= ex_mem_rd;
            mem_wb_write_ex_to_rd  <= ex_mem_write_ex_to_rd;
            mem_wb_write_mem_to_rd <= ex_mem_write_mem_to_rd;
            mem_wb_funct3          <= ex_mem_funct3;
            mem_wb_pc_plus_4       <= ex_mem_pc_plus_4;
        end
    end

    
    write_back_logic wb_unit (
        .ex_unit_result(mem_wb_data_op_result), 
        .data_mem_output(mem_wb_read_data), 
        .ex_unit_result_write(mem_wb_write_ex_to_rd), 
        .data_mem_output_write(mem_wb_write_mem_to_rd), 
        .funct3_val(mem_wb_funct3), 
        .d_mem_address_2lsbs(mem_wb_mem_address[1:0]), 
        .rd_write_data(rd_write_data_from_wb), 
        .reg_file_write_en(rd_write_en_from_wb)
    );

endmodule