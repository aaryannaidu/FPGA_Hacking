`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2025 02:36:00 PM
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
    reg out_reg = 0;

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

module display_7seg (
    input clk,
    input rst,
    input [1:0] mode,  // 2-bit mode (01 for read)
    input [3:0] a_out,  // ROM A
    input [3:0] b_out,  // RAM0 B
    input [4:0] c_out,  // RAM1 C (5-bit)
    output reg [3:0] an,
    output reg [6:0] seg
);
    reg [28:0] timer = 0;
    localparam TIMER_5S = 500_000_00;  
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

    // Refresh counter
    reg [19:0] refresh_counter = 0;
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end

    wire [1:0] digit_idx = refresh_counter[19:18];  // 0: right (A), 3: left (C high)

    // Hex to 7-seg (active low)
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

    localparam SEG_MINUS = 7'b0111111;  // -
    localparam SEG_R     = 7'b0101111;  // r
    localparam SEG_S     = 7'b0010010;  // S
    localparam SEG_T     = 7'b0000111;  // t

    always @(*) begin
        seg = 7'b1111111;
        an = 4'b1111;

        if (show_reset_msg) begin
            an = ~(4'b0001 << digit_idx);
            case (digit_idx)
                2'd3: seg = SEG_MINUS;
                2'd2: seg = SEG_R;
                2'd1: seg = SEG_S;
                2'd0: seg = SEG_T;
            endcase
        end else if (mode == 2'b01) begin
            an = ~(4'b0001 << digit_idx);
            case (digit_idx)
                2'd0: seg = hex_to_seg(a_out);  // Right: A
                2'd1: seg = hex_to_seg(b_out);  // B
                2'd2: seg = hex_to_seg(c_out[3:0]);  // C low
                2'd3: seg = hex_to_seg({3'b0, c_out[4]});  // C high (0 or 1)
            endcase
        end
    end
endmodule

module top (
    input clk,
    input [15:0] sw,
    input btnc,
    output [6:0] seg,
    output [3:0] an
);

    wire rst;
    debouncer u_deb (.clk(clk), .in(btnc), .out(rst));

    reg [15:0] sw_sync1, sw_sync2;
    always @(posedge clk) sw_sync1 <= sw;
    always @(posedge clk) sw_sync2 <= sw_sync1;

    wire [9:0] addr = sw_sync2[13:4];
    wire [3:0] din  = sw_sync2[3:0];
    wire [1:0] md   = sw_sync2[15:14];

    reg [1:0] md_prev;
    always @(posedge clk) md_prev <= md;
    wire write_pulse = (md == 2'b10) && (md_prev != 2'b10);
    wire inc_pulse   = (md == 2'b11) && (md_prev != 2'b11);


    reg [1:0] inc_state = 2'b00;
    reg [9:0] inc_addr;
    reg [3:0] inc_a;
    reg [3:0] inc_b;

    always @(posedge clk) begin
        if (rst) begin
            inc_state <= 2'b00; inc_addr <= 10'b0;
            inc_a <= 4'b0;      inc_b <= 4'b0;
        end else begin
            case (inc_state)
                2'b00: if (inc_pulse) begin
                    inc_state <= 2'b01;
                    inc_addr  <= addr;
                end
                2'b01: begin
                    inc_state <= 2'b10;
                    inc_a     <= a_out;
                    inc_b     <= b_out;
                end
                2'b10: inc_state <= 2'b00;
                default: inc_state <= 2'b00;
            endcase
        end
    end

    
    reg [1:0] write_state = 2'b00;
    reg [9:0] write_addr;
    reg [3:0] write_a;
    reg [3:0] write_din;

    always @(posedge clk) begin
        if (rst) begin
            write_state <= 2'b00;
            write_addr <= 10'b0;
            write_a <= 4'b0;
            write_din <= 4'b0;
        end else begin
            case (write_state)
                2'b00: if (write_pulse) begin
                    write_state <= 2'b01;
                    write_addr <= addr;
                    write_din <= din;
                end
                2'b01: begin
                    write_state <= 2'b10;
                    write_a <= a_out;
                end
                2'b10: write_state <= 2'b00;
                default: write_state <= 2'b00;
            endcase
        end
    end

    reg init_done = 0;
    reg [1:0] init_phase = 0;
    reg [9:0] init_addr = 0;

    always @(posedge clk) begin
        if (rst) begin
            init_done <= 0;
            init_phase <= 0;
            init_addr <= 0;
        end else if (!init_done) begin
            case (init_phase)
                2'd0: begin
                    init_phase <= 2'd1;
                    init_addr <= 0;
                end
                2'd1: begin
                    init_phase <= 2'd2;
                end
                2'd2: begin
                    if (init_addr == 10'd1023) begin
                        init_done <= 1;
                        init_phase <= 2'd0;
                    end else begin
                        init_addr <= init_addr + 1;
                        init_phase <= 2'd1;
                    end
                end
                default: init_phase <= 2'd0;
            endcase
        end
    end

    // --- Unified address
    wire [9:0] op_addr = (!init_done) ? init_addr :
                         (write_state != 2'b00) ? write_addr :
                         (inc_state != 2'b00) ? inc_addr : addr;
    wire [9:0] mem_addr = op_addr;

    // --- Memories (unchanged instantiation)
    wire [3:0] a_out;
    vector_a_rom rom_a (.clk(clk), .a(mem_addr), .qspo(a_out));

    wire [3:0] b_out;
    wire [3:0] inc_new_b = inc_b + 4'b0001;
    wire b_we = (write_state == 2'b10) || (inc_state == 2'b10);
    wire [3:0] b_d = (write_state == 2'b10) ? write_din : (inc_state == 2'b10 ? inc_new_b : din);
    vector_b_ram ram_b (.clk(clk), .we(b_we), .a(mem_addr), .d(b_d), .qspo(b_out));

    wire [4:0] c_out;
    wire c_we = b_we || (init_phase == 2'd2);
    wire [4:0] c_d = (init_phase == 2'd2) ? ({1'b0, a_out} + {1'b0, b_out}) :
                     (write_state == 2'b10) ? ({1'b0, write_a} + {1'b0, write_din}) :
                     (inc_state == 2'b10) ? ({1'b0, inc_a} + {1'b0, inc_new_b}) : 5'b0;
    vector_c_ram ram_c (.clk(clk), .we(c_we), .a(mem_addr), .d(c_d), .qspo(c_out));

    // --- Display (unchanged) ---
    display_7seg u_disp (
        .clk(clk), .rst(rst), .mode(md),
        .a_out(a_out), .b_out(b_out), .c_out(c_out),
        .an(an), .seg(seg)
    );

endmodule