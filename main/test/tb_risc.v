`timescale 1ns / 1ps

module tb_single_cycle_risc();
    reg clk;
    reg reset;
    wire [9:0] pc; 
    
    pipelined_risc uut (
        .clk(clk),
        .reset(reset),
        .pc_counter(pc)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    initial begin
        $dumpfile("waveform.vcd"); 
        $dumpvars(0, tb_single_cycle_risc); 

        reset = 1;
        #20;
        reset = 0;
        #500; 
        $finish;
    end

    always @(negedge clk) begin
        if (!reset) begin
            $display("Time=%0t | STAGE 1 (Fetch) PC=%3d | STAGE 2 (Decode) Inst=%h | STAGE 3 (Exec) In1=%h | STAGE 4 (Mem) ALU_Res=%h | STAGE 5 (WB) FinalData=%h", 
                     $time, 
                     pc,                             // What is entering Stage 1
                     uut.if_id_instr,                 // What is entering Stage 2
                     uut.id_ex_d_au_in1,             // What is entering Stage 3
                     uut.ex_mem_data_op_result,      // What is entering Stage 4
                     uut.rd_write_data_from_wb);     // What is exiting Stage 5
        end
    end
    always @(negedge clk) begin
        if (!reset) begin
            $display("Time=%0t | PC=%3d | FwdA=%b FwdB=%b | ALU_In1=%h ALU_In2=%h | ALU_Res=%h", 
                     $time, 
                     pc, 
                     uut.fwdA, uut.fwdB,           // Forwarding control signals
                     uut.alu_in1_fwd,              // The ACTUAL input used by the ALU
                     uut.alu_in2_fwd,              // The ACTUAL input used by the ALU
                     uut.final_data_op_result);    // The calculation output
        end
    end
endmodule