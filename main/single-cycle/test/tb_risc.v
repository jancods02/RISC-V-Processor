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
        clk = 1;
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
    
   always @(posedge clk) begin
    if (!reset) begin
        $display("\n======================= CYCLE Snapshot | Time: %0d ns =======================", $time);
        $display("x00-x03 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[0],  uut.decoder_unit.rf.reg_file[1],  uut.decoder_unit.rf.reg_file[2],  uut.decoder_unit.rf.reg_file[3]);
        $display("x04-x07 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[4],  uut.decoder_unit.rf.reg_file[5],  uut.decoder_unit.rf.reg_file[6],  uut.decoder_unit.rf.reg_file[7]);
        $display("x08-x11 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[8],  uut.decoder_unit.rf.reg_file[9],  uut.decoder_unit.rf.reg_file[10], uut.decoder_unit.rf.reg_file[11]);
        $display("x12-x15 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[12], uut.decoder_unit.rf.reg_file[13], uut.decoder_unit.rf.reg_file[14], uut.decoder_unit.rf.reg_file[15]);
        $display("x16-x19 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[16], uut.decoder_unit.rf.reg_file[17], uut.decoder_unit.rf.reg_file[18], uut.decoder_unit.rf.reg_file[19]);
        $display("x20-x23 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[20], uut.decoder_unit.rf.reg_file[21], uut.decoder_unit.rf.reg_file[22], uut.decoder_unit.rf.reg_file[23]);
        $display("x24-x27 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[24], uut.decoder_unit.rf.reg_file[25], uut.decoder_unit.rf.reg_file[26], uut.decoder_unit.rf.reg_file[27]);
        $display("x28-x31 : %h  %h  %h  %h", uut.decoder_unit.rf.reg_file[28], uut.decoder_unit.rf.reg_file[29], uut.decoder_unit.rf.reg_file[30], uut.decoder_unit.rf.reg_file[31]);
        $display("============================================================================");
    end

end
endmodule