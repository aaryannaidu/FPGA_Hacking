`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2025 03:33:52 PM
// Design Name: 
// Module Name: tb_top
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



module tb_top;

    reg clk = 0;
    reg [15:0] sw;
    reg btnc;
    wire [6:0] seg;
    wire [3:0] an;
    wire [3:0] tb_a_out;
    wire [3:0] tb_b_out;
    wire [4:0] tb_c_out;

    top uut (
        .clk(clk),
        .sw(sw),
        .btnc(btnc),
        .seg(seg),
        .an(an)
    );

    assign tb_a_out = uut.a_out;
    assign tb_b_out = uut.b_out;
    assign tb_c_out = uut.c_out;

    always #5 clk = ~clk;

    initial begin
        clk = 0; sw = 16'h0000; btnc = 0;

        $dumpfile("tb.vcd");
        $dumpvars(0, tb_top);

        $display("=== Reset ===");
        btnc = 1; #20; btnc = 0; #200;

        $display("=== Default addition at addr=0 (A+B init) ===");
        sw[15:14] = 2'b01; sw[13:4] = 10'b0; sw[3:0] = 4'b0;
        #100;
        $display("A: %h, B: %h, C: %h", tb_a_out, tb_b_out, tb_c_out);

        $display("=== Update B[0] via switch to 5, then add ===");
        sw[15:14] = 2'b10; sw[13:4] = 10'b0; sw[3:0] = 4'h5;
        #20;
        sw[15:14] = 2'b01;
        #100;
        $display("A: %h, B: %h (updated), C: %h (A+5)", tb_a_out, tb_b_out, tb_c_out);

        $display("=== Increment B[0], then add ===");
        sw[15:14] = 2'b11; sw[13:4] = 10'b0;
        #20;
        sw[15:14] = 2'b01;
        #100;
        $display("A: %h, B: %h (inc), C: %h (A+inc)", tb_a_out, tb_b_out, tb_c_out);

        #50; $finish;
    end

endmodule