module arith_unit_data (operand_1, operand_2, operand_1_type, operand_2_type, operation,
result_of_operation, flag_lt);
/* This module computes the result of arithmetic operation performed by an instructions on its data
and generates the outputs needed by the instructions for further execution*/
/* Please see the instruction specific details in the comments at the end of the Verilog module */
/* It is a sub-module of the execute stage logic */
input [31:0] operand_1, operand_2;
input operand_1_type, operand_2_type; // operand type: 0/1 (unsigned/signed)
input operation; // 0/1 (add/sub)
output [31:0] result_of_operation; //result of operation
output flag_lt; //flag reflecting the result of "less than" comparison performed
//on signed or unsigned operands: 0 = false, 1 = true

reg [31:0] result_of_operation;
reg flag_lt;
reg [32:0] extd_operand_1, extd_operand_2; //one bit extended unsigned/signed operands
reg [33:0] extd_arith_result; //result of arith op on extended operands
always @(*)
begin
    if (operand_1_type == 0) //Operand_1 extension by 1 bit
        extd_operand_1 = {1'b0, operand_1};
    else
        extd_operand_1 = {operand_1 [31], operand_1};

    if (operand_2_type == 0) //Operand_2 extension by 1 bit
        extd_operand_2 = {1'b0, operand_2};
    else
        extd_operand_2 = {operand_2 [31], operand_2};

    // FIX: Added begin/end blocks to prevent overwriting results
    if (operation == 0) begin // ADD
        result_of_operation = (extd_operand_1 + extd_operand_2);
        flag_lt = 1'b0; 
    end 
    else begin // SUBTRACT
        extd_arith_result = extd_operand_1 + ~(extd_operand_2) + 1;
        result_of_operation = extd_arith_result[31:0]; // 32-bit result
        flag_lt = extd_arith_result[32];
    end
end
endmodule
