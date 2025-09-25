
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/28/2025 07:01:37 PM
// Design Name:
// Module Name: top
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


module debouncer (
   input clk,
   input in,
   output out
);
   parameter DELAY = 100;
   reg [20:0] count = 0;
   reg sync0, sync1;
   reg out_reg = 0; // Explicitly initialize to 0

   always @(posedge clk) begin
       sync0 <= in;
       sync1 <= sync0;
   end

   wire idle = (out_reg == sync1);
   wire max_count = (count == DELAY - 1);

   always @(posedge clk) begin
       if (!idle) begin
           count <= count + 1;
           if (max_count) begin
               out_reg <= sync1;
           end
       end else begin
           count <= 0;
       end
   end
   assign out = out_reg;
endmodule


module multiplier (
   input [7:0] b,
   input [7:0] c,
   output [15:0] product
);
   assign product = b * c;
endmodule

module accumulator #(
   parameter INIT = 16'h0000
) (
   input clk,
   input rst,
   input enable,
   input [15:0] product,
   output reg [15:0] a = INIT,
   output reg overflow = 1'b0
);
   reg [16:0] temp;
   always @(posedge clk) begin
       if (rst) begin
           a <= INIT;
           overflow <= 0;
       end else if (enable) begin
           temp = a + product;
           a <= temp[15:0];
           overflow <= overflow | temp[16];
       end
   end
endmodule

module display_7seg (
   input clk,
   input rst,
   input overflow,
   input [1:0] read_a_b, // {read_b, read_a}
   input [1:0] index,
   input [31:0] vector_a,
   input [31:0] vector_b,
   input [15:0] dot_product,
   output reg [3:0] an,
   output reg [6:0] seg
);
   // 5-second timer logic
   reg [28:0] timer = 0;
//    localparam TIMER_5S = 500_000_000;
   localparam TIMER_5S = 500;
   reg show_reset_msg = 0;

   always @(posedge clk) begin
       if (rst) begin
           show_reset_msg <= 1'b1;
           timer <= 0;
       end else if (timer >= TIMER_5S) begin
           show_reset_msg <= 1'b0;
       end

       if (show_reset_msg) begin
           timer <= timer + 1;
       end
   end

   // Refresh counter for multiplexing
   reg [19:0] refresh_counter = 0;
   always @(posedge clk) begin
       refresh_counter <= refresh_counter + 1;
   end

   wire [1:0] digit_idx = refresh_counter[19:18];

   // Selected element
   wire [7:0] selected_element = (read_a_b == 2'b01) ? (vector_a >> (index * 8)) & 8'hFF :
                                 (read_a_b == 2'b10) ? (vector_b >> (index * 8)) & 8'hFF : 8'h00;

   // Hex to 7-segment decoder (active low)
   function [6:0] hex_to_seg;
       input [3:0] hex;
       case (hex)
           4'h0: hex_to_seg = 7'b1000000;
           4'h1: hex_to_seg = 7'b1111001;
           4'h2: hex_to_seg = 7'b0100100;
           4'h3: hex_to_seg = 7'b0110000;
           4'h4: hex_to_seg = 7'b0011001;
           4'h5: hex_to_seg = 7'b0010010;
           4'h6: hex_to_seg = 7'b0000010;
           4'h7: hex_to_seg = 7'b1111000;
           4'h8: hex_to_seg = 7'b0000000;
           4'h9: hex_to_seg = 7'b0010000;
           4'hA: hex_to_seg = 7'b0001000;
           4'hB: hex_to_seg = 7'b0000011;
           4'hC: hex_to_seg = 7'b1000110;
           4'hD: hex_to_seg = 7'b0100001;
           4'hE: hex_to_seg = 7'b0000110;
           4'hF: hex_to_seg = 7'b0001110;
           default: hex_to_seg = 7'b1111111;
       endcase
   endfunction

   // Special patterns (active low)
   localparam SEG_MINUS = 7'b0111111; // -
   localparam SEG_R = 7'b0101111;     // r (approximation)
   localparam SEG_S = 7'b0010010;     // S
   localparam SEG_T = 7'b0000111;     // t (approximation)
   localparam SEG_O = 7'b1000000;     // O
   localparam SEG_F = 7'b0001110;     // F
   localparam SEG_L = 7'b1000111;     // L

   always @(*) begin
       // Default off
       seg = 7'b1111111;
       an = 4'b1111;

       if (show_reset_msg) begin
           an = ~(1'b1 << digit_idx);
           case (digit_idx)
               2'd3: seg = SEG_MINUS;
               2'd2: seg = SEG_R;
               2'd1: seg = SEG_S;
               2'd0: seg = SEG_T;
           endcase
       end else if (read_a_b == 2'b11) begin
           an = ~(1'b1 << digit_idx);
           if (overflow) begin
               case (digit_idx)
                   2'd3: seg = SEG_O;
                   2'd2: seg = SEG_F;
                   2'd1: seg = SEG_L;
                   2'd0: seg = SEG_O;
               endcase
           end else begin
               seg = hex_to_seg((dot_product >> (digit_idx * 4)) & 4'hF);
           end
       end else if (read_a_b == 2'b01 || read_a_b == 2'b10) begin
           if (digit_idx < 2) begin
               an = ~(1'b1 << digit_idx);
               seg = hex_to_seg((selected_element >> (digit_idx * 4)) & 4'hF);
           end else begin
               an = 4'b1111;
               seg = 7'b1111111;
           end
       end
       // else blank, already default
   end
endmodule

module top(
   input clk,
   input [15:0] sw,
   input btnc,
   output [15:0] led,
   output [6:0] seg,
   output [3:0] an
);

   // Internal signals
   wire rst;
   wire [15:0] product;
   wire [15:0] acc;
   wire overflow;

   // Instantiate the debouncer
   debouncer u_deb (
       .clk(clk),
       .in(btnc),
       .out(rst)
   );

   // Vector storage
   reg [7:0] A [3:0];
   reg [7:0] B [3:0];
   reg [3:0] A_written;
   reg [3:0] B_written;

   wire [1:0] index = sw[9:8];
   wire write_a = sw[12];
   wire write_b = sw[13];
   wire read_a = sw[14];
   wire read_b = sw[15];
   wire [7:0] data_in = sw[7:0];

   always @(posedge clk) begin
       if (rst) begin
           A[0] <= 8'h00; A[1] <= 8'h00; A[2] <= 8'h00; A[3] <= 8'h00;
           B[0] <= 8'h00; B[1] <= 8'h00; B[2] <= 8'h00; B[3] <= 8'h00;
           A_written <= 4'b0000;
           B_written <= 4'b0000;
       end else begin
           if (write_a) begin
               A[index] <= data_in;
               A_written[index] <= 1'b1;
           end
           if (write_b) begin
               B[index] <= data_in;
               B_written[index] <= 1'b1;
           end
       end
   end

   wire initiate_mac = &A_written & &B_written;

   reg [2:0] counter = 0;
   reg dotprod_comp = 0;

   always @(posedge clk) begin
       if (rst) begin
           counter <= 3'd0;
           dotprod_comp <= 0;
       end else if (initiate_mac && !dotprod_comp) begin
           if (counter < 4) begin
               counter <= counter + 1;
           end else begin
               counter <= counter;
               dotprod_comp <= 1;
           end
       end else if (!initiate_mac) begin
           counter <= 3'd0;
           dotprod_comp <= 0;
       end
   end

   wire mac_enable = initiate_mac && !dotprod_comp;

   reg [7:0] mac_b = 8'h00;
   reg [7:0] mac_c = 8'h00;
   always @(posedge clk) begin
       if (rst) begin
           mac_b <= 8'h00;
           mac_c <= 8'h00;
       end else if (mac_enable) begin
           mac_b <= A[counter];
           mac_c <= B[counter];
       end
   end

   // Instantiate the multiplier
   multiplier u_mult (
       .b(mac_b),
       .c(mac_c),
       .product(product)
   );

   // Instantiate the accumulator
   accumulator u_acc (
       .clk(clk),
       .rst(rst),
       .enable(mac_enable),
       .product(product),
       .a(acc),
       .overflow(overflow)
   );

   // Drive LEDs
   assign led = acc;

   // Pack vectors
   wire [31:0] vec_a = {A[3], A[2], A[1], A[0]};
   wire [31:0] vec_b = {B[3], B[2], B[1], B[0]};

   // Instantiate the display controller
   display_7seg u_disp (
       .clk(clk),
       .rst(rst),
       .overflow(overflow),
       .read_a_b({read_b, read_a}),
       .index(index),
       .vector_a(vec_a),
       .vector_b(vec_b),
       .dot_product(acc),
       .an(an),
       .seg(seg)
   );
endmodule
