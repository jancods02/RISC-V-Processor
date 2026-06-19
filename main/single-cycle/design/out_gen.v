module out_gen (
    output reg [31:0] data_op_result,
    output reg [31:0] data_mem_address,
    input is_fmt_r, 
    input is_fmt_il, 
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
            default: data_op_result = 0;
        endcase
    end else begin 
        // FIX: Default to arithmetic result for I-type math (like ADDI)
        data_op_result = data_arith_result;
    end
end

// Generate data memory address
always @(*) begin
    if (is_fmt_il || is_fmt_s)
        data_mem_address = address_arith_result;
    else
        data_mem_address = 0;
end

endmodule