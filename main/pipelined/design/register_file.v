`timescale 1ns / 1ps

module register_file(
    input [4:0] source_reg_1, 
    input [4:0] source_reg_2, 
    input [4:0] dest_reg,
    input write_en, 
    input clk,
    input [31:0] write_data,
    output reg [31:0] source_reg_1_data, 
    output reg [31:0] source_reg_2_data
);

    reg [31:0] reg_file [0:31]; 
    integer i;

    // Initialize registers with their index values for simulation stability
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            reg_file[i] = i; 
        end
    end

    // SYNCHRONOUS WRITE OPERATION (x0 remains hardwired to 0)
    always @(posedge clk) begin
        if (write_en && (dest_reg != 5'b00000)) begin
            reg_file[dest_reg] <= write_data;
        end
    end

    // ASYNCHRONOUS READ WITH INTERNAL BYPASS FOR REG 1
    always @(*) begin
        if (source_reg_1 == 5'b00000) begin
            source_reg_1_data = 32'd0;
        end else if (write_en && (source_reg_1 == dest_reg)) begin
            source_reg_1_data = write_data; // Internal Forwarding Bypass Loop
        end else begin
            source_reg_1_data = reg_file[source_reg_1];
        end
    end

    // ASYNCHRONOUS READ WITH INTERNAL BYPASS FOR REG 2
    always @(*) begin
        if (source_reg_2 == 5'b00000) begin
            source_reg_2_data = 32'd0;
        end else if (write_en && (source_reg_2 == dest_reg)) begin
            source_reg_2_data = write_data; // Internal Forwarding Bypass Loop
        end else begin
            source_reg_2_data = reg_file[source_reg_2];
        end
    end

endmodule