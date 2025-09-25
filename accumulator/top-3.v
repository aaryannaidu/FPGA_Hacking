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
    parameter DELAY = 1000000;
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
    output reg [15:0] a,
    output reg overflow
);
    reg [16:0] temp;
    always @(posedge clk) begin
        if (rst) begin
            a <= INIT;
            overflow <= 0;
        end else if (overflow) begin
            // Stay in overflow state until reset
            a <= 16'h0000;
        end else if (enable) begin
            temp = a + product;
              a <= temp[15:0];          // Store lower 16 bits
              overflow <= temp[16];
        end
    end


endmodule

module display_7seg (
    input clk,
    input rst,
    input overflow,
    output reg [3:0] an,
    output reg [6:0] seg
);
    // 5-second timer logic (this part was correct)
    reg [28:0] timer = 0;
    localparam TIMER_5S = 500_000_000;
    reg show_reset_msg = 0;

    always @(posedge clk) begin
        if (rst) begin
            show_reset_msg <= 1'b1;
            timer <=0;
        end else if(timer >= TIMER_5S ) begin
            show_reset_msg <= 1'b0;
        end
        
        if(show_reset_msg) begin
            timer <= timer + 1;
        end
    end

    // Refresh counter for multiplexing (this part was correct)
    reg [19:0] refresh_counter = 0;
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end

    // --- FIX 1: Correctly select the digit index ---
    // Use the top two bits of the counter to get a cycling 00, 01, 10, 11 value.
    wire [1:0] digit_idx = refresh_counter[19:18];

    // --- FIX 2: Simplified and corrected anode/segment logic ---
    // A single always block is clearer here.
    always @(*) begin
        // Default to all segments and anodes OFF
        seg = 7'b1111111; // All segments off
        an = 4'b1111;      // All anodes off (high = off)

        if (show_reset_msg) begin // Priority 1: Reset message
            an = ~(1'b1 << digit_idx); // Enable the correct anode
            case (digit_idx)
                3: seg = 7'b1111110; // -
                2: seg = 7'b1111010; // r
                1: seg = 7'b0100110; // S
                0: seg = 7'b1110000; // t
            endcase
        end else if (overflow) begin // Priority 2: Overflow message
            an = ~(1'b1 << digit_idx); // Enable the correct anode
            case (digit_idx)
                3: seg = 7'b0000001; // O
                2: seg = 7'b0001110; // F
                1: seg = 7'b1000111; // L
                0: seg = 7'b0000001; // O
            endcase
        end
    end
endmodule    

module top(
    input clk,
    input [12:0] sw,
    input btnc,
    output [15:0] led,
    output [6:0] seg,
    
    output [3:0] an
    
    );
    
    
    
    // Internal signals
    wire rst;
    wire [15:0] product;
    wire [15:0] accumulated_value;
    wire overflow;

    // Instantiate the debouncer for the reset button.
    debouncer u_deb (
        .clk(clk),
        .in(btnc),
        .out(rst)
    );

    
    reg [7:0] b_reg = 0;
    reg [7:0] c_reg = 0;

    always @(posedge clk) begin
        if (rst) begin
            b_reg <= 0;
            c_reg <= 0;
        end else begin
            if (sw[10]) b_reg <= sw[7:0]; // Load b
            if (sw[11]) c_reg <= sw[7:0]; // Load c
        end
    end

    // Use a rising edge detector for the accumulation enable signal.
    reg sw12_del;
    always @(posedge clk) begin
        sw12_del <= sw[12];
    end
    wire accumulate_enable = sw[12] & ~sw12_del;

    // Instantiate the multiplier.
    multiplier u_mult (
        .b(b_reg),
        .c(c_reg),
        .product(product)
    );

    // Instantiate the accumulator.
    accumulator u_acc (
        .clk(clk),
        .rst(rst),
        .enable(accumulate_enable),
        .product(product),
        .a(accumulated_value),
        .overflow(overflow)
    );

    // Drive LEDs with the accumulated value.
    assign led = accumulated_value;

    // Instantiate the display controller.
    display_7seg u_disp (
        .clk(clk),
        .rst(rst),
        .overflow(overflow),
        .an(an),
        .seg(seg)
    );

endmodule
