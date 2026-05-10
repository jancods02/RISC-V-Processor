module decoder_r_ld_st_stage (
    input [31:0] inst,
    input [31:0] rd_write_data_from_wb,
    input rd_write_en_from_wb,
    input clock,
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
    output reg write_ex_result_to_rd, write_d_mem_out_to_rd
);

reg [6:0] funct7, opcode;
reg [4:0] rs2, rs1;
reg [31:0] imm_i, imm_s;
wire [31:0] d_rs1, d_rs2;

// Local flags for cleanly separating instructions
reg is_strict_r;
reg is_i_alu;

always @(*) begin
    funct7 = inst[31:25];
    rs2 = inst[24:20];
    rs1 = inst[19:15];
    funct3 = inst[14:12];
    rd = inst[11:7];
    opcode = inst[6:0];
    
    imm_i = {{20{inst[31]}}, inst[31:20]};  
    imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};  
    
    is_strict_r = (opcode == 7'b0110011);
    is_i_alu    = (opcode == 7'b0010011); // Detect ADDI, ANDI, ORI, XORI, etc.

    // MINIMAL FIX 1: Group I-Type ALU under fmt_r so out_gen automatically multiplexes it using funct3!
    fmt_r     = is_strict_r || is_i_alu; 
    
    fmt_il    = (opcode == 7'b0000011);
    fmt_s     = (opcode == 7'b0100011);

    // Memory Control
    d_mem_write_data = d_rs2;
    d_mem_en = (fmt_il || fmt_s);
    d_mem_write_en = fmt_s;
    
    // Write Back Control
    write_ex_result_to_rd = fmt_r; // fmt_r now correctly covers both R-type and I-type ALU
    write_d_mem_out_to_rd = fmt_il;
end

// DATA ARITHMETIC UNIT
always @(*) begin
    d_au_in1 = d_rs1;
    
    // MINIMAL FIX 2: Give the Math Unit the Immediate value if it's an I-Type ALU instruction
    d_au_in2 = (is_i_alu) ? imm_i : d_rs2; 
    
    d_au_in1_type = (funct3 == 3'b011) ? 0 : 1; 
    d_au_in2_type = (funct3 == 3'b011) ? 0 : 1;
    
    // Safety check: Ensure only Strict R-types can trigger Subtraction via funct7. (ADDI must always Add).
    d_au_op = ((is_strict_r && funct7 == 7'b0100000 && funct3 == 3'b000) || funct3 == 3'b010 || funct3 == 3'b011) ? 1 : 0; 
end

// LOGIC UNIT
always @(*) begin
    logic_unit_in1 = d_rs1;
    
    // MINIMAL FIX 3: Give the Logic Unit the Immediate value instead of rs2
    logic_unit_in2 = (is_i_alu) ? imm_i : d_rs2; 
    
    case(funct3)
        3'b100: logic_unit_op = 2'b01; // XOR
        3'b110: logic_unit_op = 2'b10; // OR
        3'b111: logic_unit_op = 2'b11; // AND
        default: logic_unit_op = 2'b00;
    endcase
end

// SHIFT UNIT
always @(*) begin
    shift_unit_in1 = d_rs1;
    
    
    shift_unit_in2 = (is_i_alu) ? inst[24:20] : d_rs2[4:0]; 
    
    case({inst[30], funct3})
        4'b0001: shift_unit_op = 2'b10; // SLL
        4'b1001: shift_unit_op = 2'b10; // SLL
        4'b0101: shift_unit_op = 2'b01; // SRL
        4'b1101: shift_unit_op = 2'b11; // SRA
        default: shift_unit_op = 2'b00;
    endcase
end

// ADDRESS ARITHMETIC UNIT
always @(*) begin
    a_au_in1 = (fmt_il || fmt_s) ? d_rs1 : 0;
    if (fmt_il) a_au_in2 = imm_i;
    else if (fmt_s) a_au_in2 = imm_s;
    else a_au_in2 = 0;
end

// Register file instantiation
register_file r0 (
    .source_reg_1(rs1), 
    .source_reg_2(rs2), 
    .dest_reg(rd), 
    .write_en(rd_write_en_from_wb), 
    .clk(clock), 
    .write_data(rd_write_data_from_wb), 
    .source_reg_1_data(d_rs1), 
    .source_reg_2_data(d_rs2)
);

endmodule