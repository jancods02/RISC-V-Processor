module out_gen (
    output reg [31:0] data_op_result,
    output reg [31:0] data_mem_address,
    input is_fmt_r, 
    input is_fmt_il, // Make sure this is driven by your Control Unit for loads!
    input is_fmt_s, 
    input [2:0] i_funct3, 
    input [31:0] data_arith_result,
    input [31:0] logic_result, 
    input [31:0] shift_result, 
    input flag_lt, 
    input [31:0] address_arith_result
);

// Generate final data operation result
always @(*) begin
    if (is_fmt_r) begin
        casex (i_funct3)
            3'b000: data_op_result = data_arith_result;
            3'b01x: data_op_result = {31'b0, flag_lt};
            3'b100: data_op_result = logic_result; 
            3'b110: data_op_result = logic_result; 
            3'b111: data_op_result = logic_result;
            3'b001: data_op_result = shift_result;
            3'b101: data_op_result = shift_result;
            default: data_op_result = 32'd0;
        endcase
    end 
    // FIX: Load and Store instructions shouldn't pass ALU math to rd data path
    else if (is_fmt_s || is_fmt_il) begin
        data_op_result = 32'd0; 
    end
    else begin 
        data_op_result = data_arith_result; // Regular I-type arithmetic (addi, etc.)
    end
end

// Generate data memory address
always @(*) begin
    if (is_fmt_il || is_fmt_s)
        data_mem_address = address_arith_result;
    else
        data_mem_address = 32'd0;
end

endmodule