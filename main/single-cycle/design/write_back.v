module write_back_logic (ex_unit_result, data_mem_output, ex_unit_result_write,
data_mem_output_write, funct3_val, d_mem_address_2lsbs, rd_write_data, reg_file_write_en);
input [31:0] ex_unit_result, data_mem_output;
input ex_unit_result_write, data_mem_output_write;
input [2:0] funct3_val;
input [1:0] d_mem_address_2lsbs;
output [31:0] rd_write_data;
reg [31:0] rd_write_data;
output reg_file_write_en;
reg reg_file_write_en;

always @ (*)
reg_file_write_en = ex_unit_result_write || data_mem_output_write;

always @ (*)
begin
rd_write_data = 0;
if (ex_unit_result_write)
rd_write_data = ex_unit_result;
else if (data_mem_output_write)
case ({funct3_val, d_mem_address_2lsbs })
5 'b00000 : rd_write_data = {{24 {data_mem_output [31]}}, data_mem_output [31:24]};
5 'b00100 : rd_write_data = {{16 {data_mem_output [31]}}, data_mem_output [31:16]};
5 'b01000 : rd_write_data = data_mem_output [31:0];
5 'b10000 : rd_write_data = {{24 {1 'b0 }}, data_mem_output [31:24]};
5 'b10100 : rd_write_data = {{16 {1 'b0 }}, data_mem_output [31:15]};
5 'b00001 : rd_write_data = {{24 {data_mem_output [23] }}, data_mem_output [23:16]};
5 'b10001 : rd_write_data = {{24 {1 'b0 }}, data_mem_output [23:16]};
5 'b00010 : rd_write_data = {{24 {data_mem_output [15] }}, data_mem_output [15:8]};

5 'b00110 : rd_write_data = {{16 {data_mem_output [15] }}, data_mem_output [15:0]};
5 'b10010 : rd_write_data = {{24 {1 'b0 }}, data_mem_output [15:8]};
5 'b10110 : rd_write_data = {{16 {1 'b0 }}, data_mem_output [15:0]};
5 'b00011 : rd_write_data = {{24 {data_mem_output [7]}}, data_mem_output [7:0]};
//5 'b00011 : rd_write_data = {{24 {1 'b0 }}, data_mem_output [7:0]};
default : rd_write_data = 0;
endcase
else
rd_write_data = 0;
end

endmodule