`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Delhi
// Engineer: Naman Jain
//
// Create Date: 09/24/2025 07:45:32 PM
// Design Name:
// Module Name: Display_sprite
// Project Name: Part III - Rival Car Implementation
// Target Devices:
// Tool Versions:
// Description: Complete game with rival car, random positioning, and collision
//
// Dependencies:
//
// Revision:
// Revision 0.06 - Fixed background scrolling syntax and rival car positioning
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module debouncer #(
    parameter DELAY = 2000000  // Set to 0 for simulation, 2000000 for hardware
) (
    input clk,
    input in,
    output out
);
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


module lfsr_8bit #(
    parameter SEED = 8'b10110101  
) (
    input clk,
    input reset,
    input enable,
    output reg [7:0] random_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            random_out <= SEED;
        end else if (enable) begin
            // LFSR feedback: XOR of bits [7,5,4,3]
            random_out <= {random_out[6:0], random_out[7] ^ random_out[5] ^ random_out[4] ^ random_out[3]};
        end
    end
endmodule

module Display_sprite #(
        parameter pixel_counter_width = 10,
        parameter OFFSET_BG_X = 200,
        parameter OFFSET_BG_Y = 150,
        parameter LFSR_SEED = 8'b10110101  // XOR of 8 LSBs of kerberos IDs
    )
    (
        input clk,
        input btn_left,    // BTNL
        input btn_right,   // BTNR
        input btn_center,  // BTNC for reset
        output HS, VS,
        output [11:0] vgaRGB
    );

    localparam bg1_width = 160;
    localparam bg1_height = 240;

    localparam main_car_width = 14;
    localparam main_car_height = 16;

    localparam rival_car_width = 14;
    localparam rival_car_height = 16;

    // Movement parameters
    localparam STEP_SIZE = 2;
    localparam INITIAL_CAR_X = 270;
    localparam INITIAL_CAR_Y = 300;

    // Scrolling parameters
    localparam SCROLL_SPEED = 2;

    // Rival car parameters
    localparam RIVAL_SPEED_FRAMES = 15;  // Update rival car every N frames
    localparam RIVAL_Y_STEP = 2;  // Pixels to move rival car per update
    localparam RIVAL_MIN_X = 44;   // Minimum X position (relative to bg)
    localparam RIVAL_MAX_X = 104;  // Maximum X position (relative to bg)

    // Collision boundaries (relative to screen)
    localparam LEFT_BOUNDARY = 244;   // 200 + 44
    localparam RIGHT_BOUNDARY = 304;  // 200 + 118 - 14

    // FSM States
    localparam START = 3'd0;
    localparam IDLE = 3'd1;
    localparam RIGHT_CAR = 3'd2;
    localparam LEFT_CAR = 3'd3;
    localparam COLLIDE = 3'd4;

    wire pixel_clock;
    wire [3:0] vgaRed, vgaGreen, vgaBlue;
    wire [pixel_counter_width-1:0] hor_pix, ver_pix;
    reg [11:0] output_color;
    reg [11:0] next_color;
    reg [15:0] bg_rom_addr;
    wire [11:0] bg_color;
    reg [7:0] car_rom_addr;
    wire [11:0] car_color;
    reg [7:0] rival_rom_addr;
    wire [11:0] rival_color;

    reg bg_on, car_on, rival_on;
    reg [pixel_counter_width-1:0] car_x_pos;
    reg [pixel_counter_width-1:0] car_y_pos;

    // Rival car position
    reg [pixel_counter_width-1:0] rival_x_pos;
    reg [pixel_counter_width-1:0] rival_y_pos;
    reg rival_active;

    // Frame counter for rival car movement
    reg [5:0] rival_frame_count;

    // Background scrolling offset
    reg [pixel_counter_width-1:0] bg_scroll_offset;

    // FSM state registers
    reg [2:0] current_state, next_state;

    // Debounced button signals
    wire deb_left, deb_right, deb_center;

    // Edge detection
    reg deb_left_prev, deb_right_prev;
    wire left_edge = deb_left && !deb_left_prev;
    wire right_edge = deb_right && !deb_right_prev;

    // Frame sync
    wire frame_end = (hor_pix == 799) && (ver_pix == 524);

    // LFSR for random rival car position
    wire [7:0] random_value;
    reg lfsr_enable;

    lfsr_8bit #(
        .SEED(LFSR_SEED)
    ) random_gen (
        .clk(clk),
        .reset(deb_center || current_state == START),
        .enable(lfsr_enable),
        .random_out(random_value)
    );

    // Instantiate debouncers
    debouncer #(.DELAY(2000000)) db_left (
        .clk(clk),
        .in(btn_left),
        .out(deb_left)
    );

    debouncer #(.DELAY(2000000)) db_right (
        .clk(clk),
        .in(btn_right),
        .out(deb_right)
    );

    debouncer #(.DELAY(2000000)) db_center (
        .clk(clk),
        .in(btn_center),
        .out(deb_center)
    );

    // VGA driver
    VGA_driver #(
        .WIDTH(pixel_counter_width)
    ) display_driver (
        .clk(clk),
        .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue),
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB),
        .pixel_clock(pixel_clock),
        .hor_pix(hor_pix),
        .ver_pix(ver_pix)
    );

    // ROM instantiations
    bg_rom bg1_rom (
        .clk(clk),
        .a(bg_rom_addr),
        .qspo(bg_color)
    );

    main_car_rom car1_rom (
        .clk(clk),
        .a(car_rom_addr),
        .qspo(car_color)
    );

    rival_car_rom rival_rom (
        .clk(clk),
        .a(rival_rom_addr),
        .qspo(rival_color)
    );

    // FSM State Register and Edge Detection
    always @(posedge clk) begin
        if (deb_center)
            current_state <= START;
        else
            current_state <= next_state;

        deb_left_prev <= deb_left;
        deb_right_prev <= deb_right;
    end

    // Collision detection between main car and rival car
    wire main_rival_collision = rival_active &&
                                 (car_x_pos < rival_x_pos + rival_car_width) &&
                                 (car_x_pos + main_car_width > rival_x_pos) &&
                                 (car_y_pos < rival_y_pos + rival_car_height) &&
                                 (car_y_pos + main_car_height > rival_y_pos);

    // FSM Next State Logic
    always @(*) begin
        next_state = current_state;

        case (current_state)
            START: begin
                next_state = IDLE;
            end

            IDLE: begin
                if (main_rival_collision)
                    next_state = COLLIDE;
                else if (right_edge)
                    next_state = RIGHT_CAR;
                else if (left_edge)
                    next_state = LEFT_CAR;
            end

            RIGHT_CAR: begin
                if (main_rival_collision || car_x_pos >= RIGHT_BOUNDARY)
                    next_state = COLLIDE;
                else
                    next_state = IDLE;
            end

            LEFT_CAR: begin
                if (main_rival_collision || car_x_pos <= LEFT_BOUNDARY)
                    next_state = COLLIDE;
                else
                    next_state = IDLE;
            end

            COLLIDE: begin
                next_state = COLLIDE;
            end

            default: begin
                next_state = START;
            end
        endcase
    end

    // Function to scale random value to range [RIVAL_MIN_X, RIVAL_MAX_X]
    // Maps 0-255 to 44-104 (60 pixel range on the road)
    function [9:0] scale_random;
        input [7:0] rand_val;
        reg [15:0] temp;
        begin
            temp = rand_val * 60;  // 0 to 15300
            scale_random = RIVAL_MIN_X + (temp >> 8);  // Divide by 256
        end
    endfunction

    // Rival car logic
    always @(posedge clk) begin
        if (deb_center || current_state == START) begin
            lfsr_enable <= 1;
            rival_x_pos <= OFFSET_BG_X + scale_random(random_value);
            rival_y_pos <= OFFSET_BG_Y;
            rival_active <= 1;
            rival_frame_count <= 0;
        end
        else if (frame_end && current_state != COLLIDE) begin
            lfsr_enable <= 1;

            if (rival_frame_count >= RIVAL_SPEED_FRAMES - 1) begin
                rival_frame_count <= 0;

                if (rival_active) begin
                    if (rival_y_pos >= OFFSET_BG_Y + bg1_height) begin
                        // Respawn at top with new random X
                        rival_x_pos <= OFFSET_BG_X + scale_random(random_value);
                        rival_y_pos <= OFFSET_BG_Y;
                        rival_active <= 1;
                    end else begin
                        rival_y_pos <= rival_y_pos + RIVAL_Y_STEP;
                    end
                end
            end else begin
                rival_frame_count <= rival_frame_count + 1;
            end
        end else begin
            lfsr_enable <= 0;
        end
    end

    // Background scrolling logic
    always @(posedge clk) begin
        if (deb_center || current_state == START) begin
            bg_scroll_offset <= 0;
        end
        else if (frame_end && current_state != COLLIDE) begin
            if (bg_scroll_offset >= bg1_height - 1)
                bg_scroll_offset <= 0;
            else
                bg_scroll_offset <= bg_scroll_offset + SCROLL_SPEED;
        end
    end

    // Car Position Update Logic
    always @(posedge clk) begin
        if (deb_center || current_state == START) begin
            car_x_pos <= INITIAL_CAR_X;
            car_y_pos <= INITIAL_CAR_Y;
        end
        else begin
            if (next_state == RIGHT_CAR && current_state == IDLE) begin
                if (car_x_pos < RIGHT_BOUNDARY)
                    car_x_pos <= car_x_pos + STEP_SIZE;
            end
            else if (next_state == LEFT_CAR && current_state == IDLE) begin
                if (car_x_pos > LEFT_BOUNDARY)
                    car_x_pos <= car_x_pos - STEP_SIZE;
            end
        end
    end

    // Main car location logic
    always @(posedge clk) begin
        if (hor_pix >= car_x_pos && hor_pix < (car_x_pos + main_car_width) &&
            ver_pix >= car_y_pos && ver_pix < (car_y_pos + main_car_height)) begin
            car_rom_addr <= (hor_pix - car_x_pos) + (ver_pix - car_y_pos) * main_car_width;
            car_on <= 1;
        end
        else begin
            car_on <= 0;
        end
    end

    // Rival car location logic
    always @(posedge clk) begin
        if (rival_active &&
            hor_pix >= rival_x_pos && hor_pix < (rival_x_pos + rival_car_width) &&
            ver_pix >= rival_y_pos && ver_pix < (rival_y_pos + rival_car_height)) begin
            rival_rom_addr <= (hor_pix - rival_x_pos) + (ver_pix - rival_y_pos) * rival_car_width;
            rival_on <= 1;
        end
        else begin
            rival_on <= 0;
        end
    end

    // Background location logic with scrolling
    always @(posedge clk) begin
        if (hor_pix >= OFFSET_BG_X && hor_pix < bg1_width + OFFSET_BG_X &&
            ver_pix >= OFFSET_BG_Y && ver_pix < bg1_height + OFFSET_BG_Y) begin

            // Calculate wrapped Y coordinate for scrolling
            bg_rom_addr <= (hor_pix - OFFSET_BG_X) +
                          (((ver_pix - OFFSET_BG_Y) + bg1_height - bg_scroll_offset) % bg1_height) * bg1_width;
            bg_on <= 1;
        end
        else begin
            bg_on <= 0;
        end
    end

    // VGA output multiplexer
    always @(posedge clk) begin
        if (car_on) begin
            if (car_color == 12'b101000001010)
                next_color <= (rival_on && rival_color != 12'b101000001010) ? rival_color :
                              (bg_on ? bg_color : 12'h000);
            else
                next_color <= car_color;
        end
        else if (rival_on) begin
            if (rival_color == 12'b101000001010)
                next_color <= bg_on ? bg_color : 12'h000;
            else
                next_color <= rival_color;
        end
        else if (bg_on) begin
            next_color <= bg_color;
        end
        else
            next_color <= 12'h000;
    end

    // Output register
    always @(posedge pixel_clock) begin
        output_color <= next_color;
    end

    assign vgaRed = output_color[11:8];
    assign vgaGreen = output_color[7:4];
    assign vgaBlue = output_color[3:0];

endmodule