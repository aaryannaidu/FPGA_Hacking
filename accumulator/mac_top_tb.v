`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2025 09:08:22 PM
// Design Name: 
// Module Name: mac_top_tb
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


module mac_top_tb;

    reg clk;
    reg [12:0] sw;
    reg btnc;
    wire [15:0] led;
    wire [6:0]  seg;
    wire [3:0]  an;
    
    top uut (
        .clk(clk),
        .sw(sw),
        .btnc(btnc),
        .led(led),
        .seg(seg),
        .an(an)
    );
     
    defparam uut.u_deb.DELAY = 2;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Every 5ns, invert the clock
    end
    
    task simulate_button_press;
        input integer on_bounces;          // Number of bounces when button is pressed
        input integer off_bounces;         // Number of bounces when button is released
        input integer on_duration;         // Duration the button is held down (stable)
        input integer on_glitch_duration;  // Duration of the '1' part of a bounce glitch
        input integer off_glitch_duration; // Duration of the '0' part of a bounce glitch

        begin
            $display("T=%0t: Simulating button press with %0d ON bounces and %0d OFF bounces.", $time, on_bounces, off_bounces);
             // === Bouncing on press (transition from 0 to 1) ===
            btnc = 1'b1; // Initial press
            repeat (on_bounces) begin
                #(off_glitch_duration) btnc = 1'b0;
                #(on_glitch_duration)  btnc = 1'b1;
            end

            // === Stable ON period ===
            #(on_duration);

            // === Bouncing on release (transition from 1 to 0) ===
            btnc = 1'b0; // Initial release
            repeat (off_bounces) begin
                #(on_glitch_duration)  btnc = 1'b1;
                #(off_glitch_duration) btnc = 1'b0;
            end
            $display("T=%0t: Button press simulation finished.", $time);
        end
    endtask
    
    initial begin
        // 1. Initialize all inputs to a known state (0)
        $display("T=%0t: --- Simulation Starting, Initializing inputs ---", $time);
        sw = 13'b0;
        btnc = 1'b0;
        #20; // Wait for 20ns

        // 2. Simulate a reset using BOUNCE SCENARIO 1
        // 1 bounce ON, 2 bounces OFF, 30ns ON duration, 5ns ON glitch, 2ns OFF glitch
        $display("\n--- [TEST CASE 1] Reset with Bounce Scenario 1 ---");
        simulate_button_press(1, 2, 30, 5, 2);
        #100; // Wait for debouncer to settle and reset to propagate
        $display("T=%0t: Reset complete. LED output: %h (%d)", $time, led, led);

        // 3. Functional Test: Load B=10, C=5 and accumulate
        $display("\n--- [FUNCTIONAL TEST] Load and Accumulate 10 * 5 ---");
        sw[10] = 1'b1; sw[7:0] = 8'd10; #10; sw[10] = 1'b0; #10; // Load B
        sw[11] = 1'b1; sw[7:0] = 8'd5;  #10; sw[11] = 1'b0; #10; // Load C
        sw[12] = 1'b1; #10; sw[12] = 1'b0; #10; // Accumulate
        $display("T=%0t: LED output: %h (%d)", $time, led, led); // Should be 50

        // 4. Simulate a reset using BOUNCE SCENARIO 2
        // 2 bounces ON, 2 bounces OFF, 30ns ON duration, 2ns ON glitch, 5ns OFF glitch
        $display("\n--- [TEST CASE 2] Reset with Bounce Scenario 2 ---");
        simulate_button_press(2, 2, 30, 2, 5);
        #100; // Wait for debouncer to settle
        $display("T=%0t: Reset complete. LED output: %h (%d)", $time, led, led);

        // 5. Functional Test: Load B=20, C=10 and accumulate
        $display("\n--- [FUNCTIONAL TEST] Load and Accumulate 20 * 10 ---");
        sw[10] = 1'b1; sw[7:0] = 8'd20; #10; sw[10] = 1'b0; #10; // Load B
        sw[11] = 1'b1; sw[7:0] = 8'd10; #10; sw[11] = 1'b0; #10; // Load C
        sw[12] = 1'b1; #10; sw[12] = 1'b0; #10; // Accumulate
        $display("T=%0t: LED output: %h (%d)", $time, led, led); // Should be 200

        // 6. Simulate a reset using BOUNCE SCENARIO 3
        // 2 bounces ON, 2 bounces OFF, 40ns ON duration, 5ns ON glitch, 5ns OFF glitch
        $display("\n--- [TEST CASE 3] Reset with Bounce Scenario 3 ---");
        simulate_button_press(2, 2, 40, 5, 5);
        #100; // Wait for debouncer to settle
        $display("T=%0t: Reset complete. LED output: %h (%d)", $time, led, led);

        // 7. Functional Test: Trigger an overflow condition
        $display("\n--- [FUNCTIONAL TEST] Triggering Overflow ---");
        sw[10] = 1'b1; sw[7:0] = 8'd200; #10; sw[10] = 1'b0; #10; // Load B=200
        sw[11] = 1'b1; sw[7:0] = 8'd200; #10; sw[11] = 1'b0; #10; // Load C=200
        // First accumulation: 0 + (200*200) = 40000. No overflow.
        sw[12] = 1'b1; #10; sw[12] = 1'b0; #10;
        $display("T=%0t: LED output after first large accumulation: %h (%d)", $time, led, led);
        // Second accumulation: 40000 + 40000 = 80000. This will overflow.
        sw[12] = 1'b1; #10; sw[12] = 1'b0; #10;
        $display("T=%0t: Overflow should be triggered now. Waiting to observe state.", $time);
        #50;

        // 8. Simulate a reset using BOUNCE SCENARIO 4 to clear overflow
        // 3 bounces ON, 3 bounces OFF, 40ns ON duration, 2ns ON glitch, 2ns OFF glitch
        $display("\n--- [TEST CASE 4] Reset from Overflow with Bounce Scenario 4 ---");
        simulate_button_press(3, 3, 40, 2, 2);
        #100; // Wait for debouncer to settle
        $display("T=%0t: Reset complete. LED output: %h (%d)", $time, led, led);

        // 9. End simulation
        $display("\n--- Simulation Finished ---");
        $finish;
    end

    // Optional: Monitor changes in key signals
    initial begin
        // This will print the values of the signals whenever any of them change.
        $monitor("T=%0t | sw: %b | btnc: %b | led: %d | overflow: %b | seg: %b | an: %b",
                 $time, sw, btnc, led, uut.overflow, seg, an);
    end
    

  
endmodule
