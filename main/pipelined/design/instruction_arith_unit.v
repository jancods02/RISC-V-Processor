module arith_unit_address (operand_1, operand_2, address_arith_result);
/* This module computes:
(1) the operand address in data memory for read / write access by the Load / Store instructions.
For instruction-specific address computation detail please see the comments after the module.
For remaining instructions, it outputs value 0.
It is a sub-module of the execute stage */
input [31:0] operand_1, operand_2;
output [31:0] address_arith_result; //computed data memory address for LD/ST type instr.
reg [31:0] address_arith_result;
reg [32:0] extd_operand_1, extd_operand_2; //one bit extended operands as per signage
reg [33:0] extd_arith_result; //result of address computation in one bit extended representation
always @(*)
begin
extd_operand_1 = {1 'b0, operand_1};
extd_operand_2 = {operand_2 [31], operand_2};
extd_arith_result = extd_operand_1 + extd_operand_2;
address_arith_result = extd_arith_result [31:0];
end
endmodule
