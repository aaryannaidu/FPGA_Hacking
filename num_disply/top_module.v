`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/21/2025 01:57:50 PM
// Design Name: 
// Module Name: top_module
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


module top_module(
    input clk,
    input [13:0] sw,
    output [3:0] an,
    output reg [6:0] seg

);
    reg [9:0] dataout0=0,dataout1=0,dataout2=0,dataout3=0;
    always @(posedge clk) begin
        if (sw[10])
            dataout0 <= sw[9:0]; // Sample slider switches' positions when sw10 is high
        if (sw[11])
            dataout1 <= sw[9:0];
        if (sw[12])
            dataout2 <= sw[9:0];
        if (sw[13]) 
            dataout3 <= sw[9:0];
    end
    
    reg [16:0] counter = 0;
    reg [1 :0] active_anode =0;
    always @(posedge clk) begin // Increment cycle counter every clock
        counter <= counter + 1;
        // After 100,000 cycles (1ms), move to next signal
        if (counter == 17'd99999) begin
            counter <= 0;
            active_anode <= (active_anode==2'd3)? 2'd0 : active_anode + 1;
        // anyways active_anode can wrap over if it is 2-bit wide
        end
    end
        // Activate the anodes based on counter value
    assign an[0] = ~(active_anode == 2'd0);
    assign an[1] = ~(active_anode == 2'd1);
    assign an[2] = ~(active_anode == 2'd2);
    assign an[3] = ~(active_anode == 2'd3);
    
    
    reg [9:0] current_digit;
    always @(*) begin
        case(active_anode)
            2'd0:
            current_digit= dataout0;
            2'd1:
            current_digit= dataout1;
            2'd2:
            current_digit= dataout2;
            
            2'd3:
            current_digit= dataout3; 
            
            default:
            current_digit=4'd0;
        endcase
    end
    
    always @(*) begin
        casex(current_digit)
//            10'd0000000000: seg=7'b1000000;
//            10'd1: seg=7'b1111001;
//            10'd2: seg=7'b0100100;
//            10'd3: seg=7'b0110000;
//            10'd4: seg=7'b0011001;
//            10'd5: seg=7'b0010010;
//            10'd6: seg=7'b0000010;
//            10'd7: seg=7'b1111000;
//            10'd8: seg=7'b0000000;
//            10'd9: seg=7'b0010000;
            10'b1xxxxxxxxx: seg = 7'b0010000; // 9
            10'b01xxxxxxxx: seg = 7'b0000000; // 8
            10'b001xxxxxxx: seg = 7'b1111000; // 7
            10'b0001xxxxxx: seg = 7'b0000010; // 6
            10'b00001xxxxx: seg = 7'b0010010; // 5
            10'b000001xxxx: seg = 7'b0011001; // 4
            10'b0000001xxx: seg = 7'b0110000; // 3
            10'b00000001xx: seg = 7'b0100100; // 2
            10'b000000001x: seg = 7'b1111001; // 1
            10'b0000000001: seg = 7'b1000000; // 0
            default: seg = 7'b1111111; // active_anode 
            
        endcase
    end
    
    
     
endmodule
