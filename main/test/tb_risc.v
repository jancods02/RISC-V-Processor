`timescale 1ns / 1ps

module tb_single_cycle_risc();
    reg clk;
    reg reset;
    wire [9:0] pc; 
    single_cycle_risc uut (
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
        #200; 
    end

    always @(negedge clk) begin
        if (!reset) begin
            $display("Time=%0t | PC=%3d | Inst=%h | RegWr=%b | RegData=%h | MemWr=%b | MemAddr=%h | MemWriteData=%h", 
                     $time, 
                     pc, 
                     uut.fetched_instruction, 
                     uut.rd_write_en_from_wb, 
                     uut.rd_write_data_from_wb,
                     uut.d_mem_write_en, 
                     uut.final_data_mem_address, 
                     uut.d_mem_write_data);
        end
    end

endmodule