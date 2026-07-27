`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: decoder_r_ld_st_stage
// Description: Full 5-Stage Pipelined RISC-V Decoder wrapper with Hazard Fix.
//              Combines your custom control unit logic with the pipelined 
//              Write-Back destination register indexing and corrected shift decoding.
//////////////////////////////////////////////////////////////////////////////////

module decoder_r_ld_st_stage (
    input [31:0] inst,
    input [31:0] rd_write_data_from_wb,
    input rd_write_en_from_wb,
    input [4:0] rd_wb_index,            // <-- Pipelined write destination index from WB stage
    input clk,
    output reg [31:0] d_au_in1, d_au_in2,
    output reg d_au_in1_type, d_au_in2_type, d_au_op,
    output reg [31:0] logic_unit_in1, logic_unit_in2,
    output reg [1:0] logic_unit_op,
    output reg [31:0] shift_unit_in1,
    output reg [4:0] shift_unit_in2,
    output reg [1:0] shift_unit_op,
    output reg [31:0] a_au_in1, a_au_in2,
    output reg fmt_r, fmt_il, fmt_s, 
    output reg [2:0] funct3,
    output reg [31:0] d_mem_write_data,
    output reg d_mem_en, d_mem_write_en,
    output reg [4:0] rd,
    output reg [4:0] rs1, rs2, 
    output reg mem_read,       
    output reg is_branch,
    output reg is_jal,          
    output reg [31:0] branch_imm,
    output reg write_ex_result_to_rd, write_d_mem_out_to_rd
);

    reg [6:0] funct7, opcode;
    reg [31:0] imm_i, imm_s;
    wire [31:0] d_rs1, d_rs2;
    reg is_strict_r;
    reg is_i_alu;

    // =========================================================================
    // 1. PRIMARY INSTRUCTION DECODING & CONTROL SIGNAL GENERATION
    // =========================================================================
    always @(*) begin
        funct7 = inst[31:25];
        rs2 = inst[24:20];
        rs1 = inst[19:15];
        funct3 = inst[14:12];
        rd = inst[11:7];
        opcode = inst[6:0];
        mem_read = (opcode == 7'b0000011);
        imm_i = {{20{inst[31]}}, inst[31:20]};  
        imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};  
        
        is_strict_r = (opcode == 7'b0110011);
        is_i_alu    = (opcode == 7'b0010011); 
        
        is_branch = (opcode == 7'b1100011);
        is_jal    = (opcode == 7'b1101111);
        
        if (is_jal) begin
            branch_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
        end else begin
            branch_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        end
        
        fmt_r  = (opcode == 7'b0110011 || opcode == 7'b0010011) && !is_branch && !is_jal;
        fmt_il = (opcode == 7'b0000011) && !is_branch && !is_jal;
        fmt_s  = (opcode == 7'b0100011) && !is_branch && !is_jal;
        
        d_mem_write_data = d_rs2;
        d_mem_en = (fmt_il || fmt_s);
        d_mem_write_en = fmt_s;
        
        write_ex_result_to_rd = fmt_r || is_jal;
        write_d_mem_out_to_rd = fmt_il;
    end

    // =========================================================================
    // 2. DATA ARITHMETIC UNIT CONTROL MUXES
    // =========================================================================
    always @(*) begin
        d_au_in1 = d_rs1;
        d_au_in2 = (is_i_alu) ? imm_i : d_rs2;
        d_au_in1_type = (funct3 == 3'b011) ? 0 : 1; 
        d_au_in2_type = (funct3 == 3'b011) ? 0 : 1;
        d_au_op = ((is_strict_r && funct7 == 7'b0100000 && funct3 == 3'b000) || funct3 == 3'b010 || funct3 == 3'b011) ? 1 : 0; 
    end

    // =========================================================================
    // 3. LOGIC UNIT CONTROL MUXES
    // =========================================================================
    always @(*) begin
        logic_unit_in1 = d_rs1;
        logic_unit_in2 = (is_i_alu) ? imm_i : d_rs2; 
        case(funct3)
            3'b100: logic_unit_op = 2'b01; // XOR
            3'b110: logic_unit_op = 2'b10; // OR
            3'b111: logic_unit_op = 2'b11; // AND
            default: logic_unit_op = 2'b00;
        endcase
    end

    // =========================================================================
    // 4. SHIFT UNIT CONTROL MUXES (FIXED: Handles arithmetic/logical shifts safely)
    // =========================================================================
    always @(*) begin
        shift_unit_in1 = d_rs1;
        shift_unit_in2 = (is_i_alu) ? inst[24:20] : d_rs2[4:0];
        
        if (funct3 == 3'b001) begin
            shift_unit_op = 2'b10; // SLL / SLLI
        end 
        else if (funct3 == 3'b101) begin
            if (inst[30]) 
                shift_unit_op = 2'b11; // SRA / SRAI
            else          
                shift_unit_op = 2'b01; // SRL / SRLI
        end 
        else begin
            shift_unit_op = 2'b00; // Default NOP
        end
    end

    // =========================================================================
    // 5. ADDRESS ARITHMETIC UNIT CONTROL MUXES
    // =========================================================================
    always @(*) begin
        a_au_in1 = (fmt_il || fmt_s) ? d_rs1 : 0;
        if (fmt_il) a_au_in2 = imm_i;
        else if (fmt_s) a_au_in2 = imm_s;
        else a_au_in2 = 0;
    end

    // =========================================================================
    // 6. REGISTER FILE INSTANTIATION
    // =========================================================================
    register_file rf (
        .source_reg_1(rs1), 
        .source_reg_2(rs2), 
        .dest_reg(rd_wb_index),         // Synchronized with Write-Back stage to fix structural hazard
        .write_en(rd_write_en_from_wb), 
        .clk(clk), 
        .write_data(rd_write_data_from_wb), 
        .source_reg_1_data(d_rs1), 
        .source_reg_2_data(d_rs2)
    );

endmodule