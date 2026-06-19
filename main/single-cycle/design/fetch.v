`timescale 1ns / 1ps

module fetch(
    input clk, fetch_en, decision, clr,
    input [9:0] target, 
    output [31:0] fetched_instruction, 
    output [9:0] pc
);

parameter constant = 10'd4;
wire [9:0] address;
wire [9:0] adder_out;
wire [9:0] old_pc;
wire en;

blk_mem_gen_0 uut (
    .clka(clk),
    .ena(fetch_en),
    .addra(address), 
    .douta(fetched_instruction)
);

mux mux_21(
    .target(target),
    .outadder(adder_out),
    .decision(decision),
    .instruction(address)
);

adder_10 add(
    .a(old_pc),
    .b(constant),
    .sum(adder_out)
);

synchronizer d1(
    .clr(clr),
    .clk(clk),
    .din(address),
    .out(old_pc),
    .en(fetch_en)
);

synchronizer d3(
    .din(old_pc),
    .clk(clk),
    .en(en),
    .clr(clr),
    .out(pc)
);

dff sync(.clr(clr), .en(fetch_en), .clk(clk), .out(en));

endmodule

module dff(
    input clr, clk, en,
    output reg out
);
always @(posedge clk) begin
    if(clr)
        out <= 0;
    else
        out <= en;
end
endmodule

module synchronizer(input clr, clk, en, input [9:0]din, output reg [9:0] out);
    always @(posedge clk) begin 
        if(clr) out <= 0; 
        else if(en) out <= din; 
    end 
endmodule

module mux(
    input [9:0]target, outadder,
    input decision,
    output [9:0]instruction
);
assign instruction = decision ? target : outadder;
endmodule

module adder_10(
    input [9:0]a, b,
    output [9:0] sum
);
assign sum = a + b;
endmodule