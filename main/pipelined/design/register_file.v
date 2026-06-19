`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2026 02:09:03 PM
// Design Name: 
// Module Name: register
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module register_file(source_reg_1, source_reg_2, dest_reg, write_en, clk, write_data,
source_reg_1_data, source_reg_2_data);
input [4:0] source_reg_1, source_reg_2, dest_reg;
input write_en, clk;
input [31:0] write_data;
output [31:0] source_reg_1_data, source_reg_2_data;
reg [31:0] source_reg_1_data, source_reg_2_data;
reg [31:0] reg_file [0:31]; //32 x 32-bit register file

integer i;
initial begin
    
    for (i = 0; i < 32; i = i + 1) begin
        reg_file[i] = i; 
    end
end

//WRITE TO REGISTER FILE: SYNCHRONOUSLY AT THE NEGATIVE EDGE OF THE CLOCK
always @(posedge clk)
begin
if(write_en)
casex (dest_reg)
5'b00000: reg_file[dest_reg] <= 0;
default : reg_file[dest_reg] <= write_data;
endcase
end

//ASYNCHRONOUS READ OPERATION FROM source_reg_1
always @(*)
begin
casex (source_reg_1)
5'b00000 : source_reg_1_data = 0;
default : source_reg_1_data = reg_file [source_reg_1];
endcase
end
//ASYNCHRONOUS READ OPERATION FROM source_reg_2
always @(*)
begin
casex (source_reg_2)
5'b00000 : source_reg_2_data = 0;
default : source_reg_2_data = reg_file [source_reg_2];
endcase
end
endmodule