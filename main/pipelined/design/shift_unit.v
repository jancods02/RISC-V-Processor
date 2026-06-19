module shift_unit (operand_1, operand_2, operation, result_of_operation);
input [31:0] operand_1;
input [4:0] operand_2;
input [1:0] operation;
output [31:0] result_of_operation;
reg [31:0] result_of_operation;
always @(*)
begin
casex (operation)
2 'b01 : result_of_operation = operand_1 >> operand_2;
2 'b10 : result_of_operation = operand_1 << operand_2;
2 'b11 : result_of_operation = operand_1 >>> operand_2;
default : result_of_operation = {32{1 'b0}};
endcase
end
endmodule