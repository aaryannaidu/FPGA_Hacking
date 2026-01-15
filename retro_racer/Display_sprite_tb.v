`timescale 1ns / 1ps


module Display_sprite_part3_tb();

   // Clock period = 10ns (100MHz)
   parameter CLK_PERIOD = 10;

   // Testbench signals
   reg clk;
   reg btn_left;
   reg btn_right;
   reg btn_center;
   wire HS, VS;
   wire [11:0] vgaRGB;

   // Probe signals for waveform observation
   wire [7:0] prng_output;
   wire [9:0] rival_x, rival_y;
   wire [9:0] main_car_x, main_car_y;
   wire [9:0] bg_scroll_offset;
   wire rival_active;
   wire [2:0] fsm_state;
   wire collision_detected;

   // Assign internal signals for observation
   assign prng_output = dut.random_value;
   assign rival_x = dut.rival_x_pos;
   assign rival_y = dut.rival_y_pos;
   assign main_car_x = dut.car_x_pos;
   assign main_car_y = dut.car_y_pos;
   assign bg_scroll_offset = dut.bg_scroll_offset;
   assign rival_active = dut.rival_active;
   assign fsm_state = dut.current_state;
   assign collision_detected = dut.main_rival_collision;

   // Instantiate the DUT
   Display_sprite #(
       .pixel_counter_width(10),
       .OFFSET_BG_X(200),
       .OFFSET_BG_Y(150),
       .LFSR_SEED(8'b10110101)
   ) dut (
       .clk(clk),
       .btn_left(btn_left),
       .btn_right(btn_right),
       .btn_center(btn_center),
       .HS(HS),
       .VS(VS),
       .vgaRGB(vgaRGB)
   );

   // Override debouncer delay to 0 for simulation
   defparam dut.db_left.DELAY = 0;
   defparam dut.db_right.DELAY = 0;
   defparam dut.db_center.DELAY = 0;

   // Clock generation
   initial begin
       clk = 0;
       forever #(CLK_PERIOD/2) clk = ~clk;
   end

   // Frame counter
   integer frame_count = 0;
   reg frame_prev = 0;
   wire frame_pulse = (dut.hor_pix == 799) && (dut.ver_pix == 524);

   always @(posedge clk) begin
       frame_prev <= frame_pulse;
       if (frame_pulse && !frame_prev) begin
           frame_count = frame_count + 1;
       end
   end

   // Monitor PRNG output changes (reduced logging)
   reg [7:0] prng_prev = 0;
   integer prng_change_count = 0;
   always @(posedge clk) begin
       if (prng_output != prng_prev && prng_change_count < 5) begin
           $display("[PRNG] Random value = %d (0x%h)", prng_output, prng_output);
           prng_prev = prng_output;
           prng_change_count = prng_change_count + 1;
       end
   end

   // Monitor rival car spawning only
   reg [9:0] rival_y_prev = 999;
   integer rival_moves = 0;
   always @(posedge clk) begin
       if (rival_y < rival_y_prev && rival_moves < 3) begin
           $display("[RIVAL] Spawned/Respawned at position (%0d, %0d)", rival_x, rival_y);
           rival_moves = rival_moves + 1;
       end
       rival_y_prev = rival_y;
   end

   // Monitor collision detection
   reg collision_prev = 0;
   always @(posedge clk) begin
       if (collision_detected && !collision_prev) begin
           $display("");
           $display("*** COLLISION DETECTED ***");
           $display("Main car: (%0d, %0d)", main_car_x, main_car_y);
           $display("Rival car: (%0d, %0d)", rival_x, rival_y);
           $display("");
       end
       collision_prev = collision_detected;
   end

   // Monitor FSM state changes to COLLIDE only
   reg [2:0] state_prev = 0;
   always @(posedge clk) begin
       if (fsm_state != state_prev && fsm_state == 3'd4) begin
           $display("[FSM] Entered COLLIDE state");
       end
       state_prev = fsm_state;
   end

   // Flag for tracking collision occurrence
   reg collision_occurred = 0;
   always @(posedge clk) begin
       if (collision_detected)
           collision_occurred = 1;
   end

   // Variables for freeze test
   integer frozen_rival_y;
   integer frozen_bg_scroll;

   // Test sequence
   initial begin


       // Initialize inputs
       btn_left = 0;
       btn_right = 0;
       btn_center = 0;

       #100;

       $display("[TEST 1] Observing PRNG and Initial Positions");
       #1000;
       $display("Initial rival X: %d (should be 244-304)", rival_x);
       $display("Initial rival Y: %d (should be 150)", rival_y);
       $display("");

       $display("[TEST 2] Waiting for rival car to move down...");
       // Wait for rival to move several times (about 30 frames)
       repeat(30) begin
           wait(frame_pulse);
           @(posedge clk);
       end

       $display("[TEST 3] Moving main car to cause collision...");

       // Move main car towards rival car's X position
       if (main_car_x < rival_x) begin
           // Move right
           repeat(10) begin
               @(posedge clk);
               btn_right = 1;
               repeat(10) @(posedge clk);
               btn_right = 0;
               repeat(100) @(posedge clk);
           end
       end else begin
           // Move left
           repeat(10) begin
               @(posedge clk);
               btn_left = 1;
               repeat(10) @(posedge clk);
               btn_left = 0;
               repeat(100) @(posedge clk);
           end
       end

       // Wait for rival to approach main car's Y level
       wait(rival_y >= main_car_y - 50);

       // Fine-tune position for collision
       repeat(5) begin
           if (main_car_x < rival_x - 5) begin
               @(posedge clk);
               btn_right = 1;
               repeat(10) @(posedge clk);
               btn_right = 0;
               repeat(100) @(posedge clk);
           end else if (main_car_x > rival_x + 5) begin
               @(posedge clk);
               btn_left = 1;
               repeat(10) @(posedge clk);
               btn_left = 0;
               repeat(100) @(posedge clk);
           end
       end

       // Wait for collision to occur (max 50 frames)
       repeat(50) begin
           wait(frame_pulse);
           @(posedge clk);
           if (collision_occurred) begin
               // Exit loop by disabling further iterations
               repeat(49) begin
                   @(posedge clk);
               end
           end
       end

       if (!collision_occurred) begin
           $display("WARNING: Collision did not occur in expected time");
       end

       $display("");
       $display("[TEST 4] Verifying freeze after collision...");

       // Record positions after collision
       @(posedge clk);
       #1000;

       if (fsm_state == 3'd4) begin
           $display("FSM in COLLIDE state - PASS");
           $display("Rival Y frozen at: %0d", rival_y);
           $display("Background scroll frozen at: %0d", bg_scroll_offset);

           // Store frozen values
           frozen_rival_y = rival_y;
           frozen_bg_scroll = bg_scroll_offset;

           // Wait 20 frames
           repeat(20) begin
               wait(frame_pulse);
               @(posedge clk);
           end

           // Check if values stayed same
           if (rival_y == frozen_rival_y && bg_scroll_offset == frozen_bg_scroll) begin
               $display("After 20 frames:");
               $display("  Rival Y still: %0d - FROZEN ✓", rival_y);
               $display("  BG scroll still: %0d - FROZEN ✓", bg_scroll_offset);
           end else begin
               $display("ERROR: Movement detected after collision!");
           end
       end else begin
           $display("WARNING: Not in COLLIDE state");
       end

       #5000000;

       $display("");
       $display("[TEST 5] Testing reset with BTNC...");
       btn_center = 1;
       #1000;
       btn_center = 0;
       #1000;


       $finish;
   end

   // Timeout watchdog
   initial begin
       #500000000;
       $display("ERROR: Simulation timeout!");
       $finish;
   end

endmodule