`timescale 1ns / 1ps
module top_tb();

   reg clk = 0;
   reg [15:0] sw = 0;
   reg btnc = 0;
   wire [15:0] led;
   wire [6:0] seg;
   wire [3:0] an;

   // Instantiate the top module
   top uut (
       .clk(clk),
       .sw(sw),
       .btnc(btnc),
       .led(led),
       .seg(seg),
       .an(an)
   );

   // Clock generation: 100MHz (period 10ns)
   always #5 clk = ~clk;

   // Test sequence
   initial begin
       // Note: Using reduced DELAY=100 and TIMER_5S=500 for simulation
       $display("Starting simulation...");

       // Initial reset
       btnc = 1; // Assert reset
       #20;
       btnc = 0; // Deassert reset
       #1000; // Wait for debounce (DELAY=100 cycles)

       // Test 1: Normal operation - Vector A: [1, 2, 3, 4], B: [5, 6, 7, 8]
       sw = {1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 2'b00, 8'h01}; // A[0]=1
       #10;
       sw = {1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 2'b01, 8'h02}; // A[1]=2
       #10;
       sw = {1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 2'b10, 8'h03}; // A[2]=3
       #10;
       sw = {1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 2'b11, 8'h04}; // A[3]=4
       #10;
       sw = {1'b0, 1'b0, 1'b1, 1'b0, 2'b00, 2'b00, 8'h05}; // B[0]=5
       #10;
       sw = {1'b0, 1'b0, 1'b1, 1'b0, 2'b00, 2'b01, 8'h06}; // B[1]=6
       #10;
       sw = {1'b0, 1'b0, 1'b1, 1'b0, 2'b00, 2'b10, 8'h07}; // B[2]=7
       #10;
       sw = {1'b0, 1'b0, 1'b1, 1'b0, 2'b00, 2'b11, 8'h08}; // B[3]=8
       #10;

       // Wait for computation (7 cycles: 4 for counter 0-3, 1 for mac_b/mac_c, 1 for product, 1 for acc)
       #70;

       // Check LED == 70 (0x0046)
       if (led !== 16'h0046) $display("Error: Dot product LED = %h, expected 0046", led);
       else $display("Test 1 passed: Dot product = %h", led);

       // Read A[0]: read_a=1, index=00
       sw = {1'b0, 1'b1, 1'b0, 1'b0, 2'b00, 2'b00, 8'h00};
       #100;

       // Read dot product: read_a=1, read_b=1
       sw = {1'b1, 1'b1, 1'b0, 1'b0, 2'b00, 2'b00, 8'h00};
       #100;

       // Test 2: Overflow operation - A: [255, 255, 0, 0], B: [255, 255, 0, 0]
       btnc = 1;
       #20;
       btnc = 0;
       #1000;

       sw = {1'b0, 1'b0, 1'b1, 1'b1, 2'b00, 8'hFF}; // A[0]=255, B[0]=255
       #10;
       sw = {1'b0, 1'b0, 1'b1, 1'b1, 2'b01, 8'hFF}; // A[1]=255, B[1]=255
       #10;
       sw = {1'b0, 1'b0, 1'b1, 1'b1, 2'b10, 8'h00}; // A[2]=0, B[2]=0
       #10;
       sw = {1'b0, 1'b0, 1'b1, 1'b1, 2'b11, 8'h00}; // A[3]=0, B[3]=0
       #10;

       #70; // Compute

       if (led !== 16'hFC02 || uut.u_acc.overflow !== 1) $display("Error: Overflow test failed, LED = %h, overflow = %b", led, uut.u_acc.overflow);
       else $display("Test 2 passed: LED = %h, overflow = %b", led, uut.u_acc.overflow);

       // Read dot product: should show OFLO
       sw = {1'b1, 1'b1, 1'b0, 1'b0, 2'b00, 8'h00};
       #100;

       // Test reset during operation
       sw = {1'b0, 1'b0, 1'b1, 1'b0, 2'b00, 8'h01};
       #10;
       btnc = 1;
       #20;
       btnc = 0;
       #1000;

       $display("Simulation complete.");
       $finish;
   end

   // Monitor display
   always @(posedge clk) begin
       if (|an == 0) begin
           case (an)
               4'b1110: $display("Digit 0: seg=%b", seg);
               4'b1101: $display("Digit 1: seg=%b", seg);
               4'b1011: $display("Digit 2: seg=%b", seg);
               4'b0111: $display("Digit 3: seg=%b", seg);
           endcase
       end
   end
endmodule