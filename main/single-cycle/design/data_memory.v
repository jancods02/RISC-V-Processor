`timescale 1ns / 1ps

module data_mem_16kx8 (
    input [13:0] d_mem_address,
    input [31:0] d_mem_data_in,
    input d_mem_en,
    input d_mem_write_en,
    input d_mem_clock,
    input [1:0] d_mem_rw_size,
    output [31:0] d_mem_out
);

// ================= REG DECLARATIONS =================
reg [7:0] write_data_0, write_data_1, write_data_2, write_data_3;
reg [11:0] address_0, address_1, address_2, address_3;
reg write_enable_0, write_enable_1, write_enable_2, write_enable_3;
reg enable_0, enable_1, enable_2, enable_3;

// ================= COMBINATIONAL LOGIC =================
always @(*) begin

// DEFAULTS
write_data_0 = 0; write_data_1 = 0;
write_data_2 = 0; write_data_3 = 0;

write_enable_0 = 0; write_enable_1 = 0;
write_enable_2 = 0; write_enable_3 = 0;

enable_0 = 0; enable_1 = 0;
enable_2 = 0; enable_3 = 0;

// ======================================================
// BYTE 0 (MSB → [31:24])
// ======================================================
casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})

    // WORD WRITE
    6'b1110xx: begin
        write_data_0 = d_mem_data_in[31:24];
        write_enable_0 = 1;
    end

    // HALF WORD (upper half)
    6'b11011x: begin
        write_data_0 = d_mem_data_in[15:8];
        write_enable_0 = 1;
    end

    // BYTE WRITE
    6'b110011: begin
        write_data_0 = d_mem_data_in[7:0];
        write_enable_0 = 1;
    end

endcase

casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})
    6'b1x10xx: enable_0 = 1;   // word
    6'b1x011x: enable_0 = 1;   // half upper
    6'b1x0011: enable_0 = 1;   // byte
endcase

// ======================================================
// BYTE 1 ([23:16])
// ======================================================
casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})

    6'b1110xx: begin
        write_data_1 = d_mem_data_in[23:16];
        write_enable_1 = 1;
    end

    6'b11011x: begin
        write_data_1 = d_mem_data_in[7:0];
        write_enable_1 = 1;
    end

    6'b110010: begin
        write_data_1 = d_mem_data_in[7:0];
        write_enable_1 = 1;
    end

endcase

casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})
    6'b1x10xx: enable_1 = 1;
    6'b1x011x: enable_1 = 1;
    6'b1x0010: enable_1 = 1;
endcase

// ======================================================
// BYTE 2 ([15:8])
// ======================================================
casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})

    6'b1110xx: begin
        write_data_2 = d_mem_data_in[15:8];
        write_enable_2 = 1;
    end

    6'b11010x: begin
        write_data_2 = d_mem_data_in[15:8];
        write_enable_2 = 1;
    end

    6'b110001: begin
        write_data_2 = d_mem_data_in[7:0];
        write_enable_2 = 1;
    end

endcase

casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})
    6'b1x10xx: enable_2 = 1;
    6'b1x010x: enable_2 = 1;
    6'b1x0001: enable_2 = 1;
endcase

// ======================================================
// BYTE 3 (LSB [7:0])
// ======================================================
casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})

    6'b1110xx: begin
        write_data_3 = d_mem_data_in[7:0];
        write_enable_3 = 1;
    end

    6'b11010x: begin
        write_data_3 = d_mem_data_in[7:0];
        write_enable_3 = 1;
    end

    6'b110000: begin
        write_data_3 = d_mem_data_in[7:0];
        write_enable_3 = 1;
    end

endcase

casex ({d_mem_en, d_mem_write_en, d_mem_rw_size, d_mem_address[1:0]})
    6'b1x10xx: enable_3 = 1;
    6'b1x010x: enable_3 = 1;
    6'b1x0000: enable_3 = 1;
endcase

// ================= ADDRESS =================
address_0 = d_mem_address[13:2];
address_1 = d_mem_address[13:2];
address_2 = d_mem_address[13:2];
address_3 = d_mem_address[13:2];

end

// ================= BRAM OUTPUT WIRES =================
wire [7:0] out_0, out_1, out_2, out_3;

// ================= CORRECT INSTANCES =================
// FIX: Using ~d_mem_clock to force memory fetch on the falling edge!
blk_mem_gen_0 d_mem_byte_0(
    .clka(~d_mem_clock), 
    .ena(enable_0),
    .wea(write_enable_0),
    .addra(address_0),
    .dina(write_data_0),
    .douta(out_0)
);

blk_mem_gen_0 d_mem_byte_1(
    .clka(~d_mem_clock),
    .ena(enable_1),
    .wea(write_enable_1),
    .addra(address_1),
    .dina(write_data_1),
    .douta(out_1)
);

blk_mem_gen_0 d_mem_byte_2(
    .clka(~d_mem_clock),
    .ena(enable_2),
    .wea(write_enable_2),
    .addra(address_2),
    .dina(write_data_2),
    .douta(out_2)
);

blk_mem_gen_0 d_mem_byte_3(
    .clka(~d_mem_clock),
    .ena(enable_3),
    .wea(write_enable_3),
    .addra(address_3),
    .dina(write_data_3),
    .douta(out_3)
);

// ================= SIMPLE READ =================
assign d_mem_out = {out_0, out_1, out_2, out_3};

endmodule