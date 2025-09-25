`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/21/2025 03:36:06 PM
// Design Name: 
// Module Name: top_module_tb
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


module top_module_tb;

    
    reg clk;
    reg [13:0] sw;

    
    wire [3:0] an;
    wire [6:0] seg;

    // Instantiate your top-level module
    top_module uut (
        .clk(clk),
        .sw(sw),
        .an(an),
        .seg(seg)
    );

    // Clock generation: 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test procedure
    initial begin
        // Initial state
        sw = 14'd0;
        #20;

        // Test: store digit 3 (say value '7')
        sw[9:0] = 10'b0000001000; // Only SW3 ON (for digit 3)
        sw[13] = 1'b1;           // Enable SW13 (digit 3)
        #20;
        sw = 1'b0;           // Turn off enable
        #20;
        
        // Test: store digit 2 (value '5')
        sw[9:0] = 10'b0000100000; // Only SW5 ON
        sw = 1'b1;           // Enable SW12 (digit 2)
        #20;
        sw = 1'b0;
        #20;

        // Test: store digit 1 (value '9')
        sw[9:0] = 10'b1000000000; // Only SW9 ON
        sw = 1'b1;           // Enable SW11 (digit 1)
        #20;
        sw = 1'b0;
        #20;

        // Test: store digit 0 (value '0')
        sw[9:0] = 10'b0000000001;
        sw = 1'b1;
        #20;
        sw = 1'b0;
        #40;

        // Done: halt simulation
        $stop;
    end

    // Optionally monitor outputs
//    initial begin
//        $monitor("Time %0t | sw=%b | an=%b | seg=%b", $time, sw, an, seg);
//    end
endmodule


