module write_back_logic (
    input [31:0] ex_unit_result, 
    input [31:0] data_mem_output, 
    input ex_unit_result_write, 
    input data_mem_output_write, 
    input [2:0] funct3_val, 
    input [1:0] d_mem_address_2lsbs, 
    output reg [31:0] rd_write_data, 
    output reg reg_file_write_en
);

    always @ (*) begin
        reg_file_write_en = ex_unit_result_write || data_mem_output_write;
    end

    always @ (*) begin
        rd_write_data = 32'd0;
        if (ex_unit_result_write) begin
            rd_write_data = ex_unit_result;
        end else if (data_mem_output_write) begin
            case ({funct3_val, d_mem_address_2lsbs})
                // LB: Sign-Extended Byte
                5'b000_00 : rd_write_data = {{24{data_mem_output[7]}},  data_mem_output[7:0]};
                5'b000_01 : rd_write_data = {{24{data_mem_output[15]}}, data_mem_output[15:8]};
                5'b000_10 : rd_write_data = {{24{data_mem_output[23]}}, data_mem_output[23:16]};
                5'b000_11 : rd_write_data = {{24{data_mem_output[31]}}, data_mem_output[31:24]};
                
                // LH: Sign-Extended Halfword
                5'b001_00 : rd_write_data = {{16{data_mem_output[15]}}, data_mem_output[15:0]};
                5'b001_10 : rd_write_data = {{16{data_mem_output[31]}}, data_mem_output[31:16]};
                
                // LW: Word
                5'b010_00 : rd_write_data = data_mem_output;
                
                // LBU: Zero-Extended Byte
                5'b100_00 : rd_write_data = {24'd0, data_mem_output[7:0]};
                5'b100_01 : rd_write_data = {24'd0, data_mem_output[15:8]};
                5'b100_10 : rd_write_data = {24'd0, data_mem_output[23:16]};
                5'b100_11 : rd_write_data = {24'd0, data_mem_output[31:24]};
                
                // LHU: Zero-Extended Halfword
                5'b101_00 : rd_write_data = {16'd0, data_mem_output[15:0]};
                5'b101_10 : rd_write_data = {16'd0, data_mem_output[31:16]};
                
                default   : rd_write_data = 32'd0;
            endcase
        end
    end

endmodule