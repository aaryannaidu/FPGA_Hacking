module linked_list_tb;

    // Clock and reset
    reg clk;
    reg rst;
    
    // Inputs
    reg [7:0] data_in;
    reg [2:0] operation;
    
    // Outputs
    wire overflow;
    wire underflow;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;
    
    // Operation codes
    localparam OP_IDLE = 3'b000;
    localparam OP_INSERT_HEAD = 3'b100;
    localparam OP_INSERT_TAIL = 3'b101;
    localparam OP_DELETE = 3'b110;
    localparam OP_TRAVERSE = 3'b111;
    
    // Instantiate the Unit Under Test (UUT)
    linked_list #(
        .MAX_NODES(8)  // Smaller for testing
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .operation(operation),
        .overflow(overflow),
        .underflow(underflow),
        .seg(seg),
        .an(an),
        .dp(dp)
    );
    
    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Task to print linked list contents
    task print_list;
        reg [4:0] ptr;
        integer node_count;
        begin
            $display("List contents:");
            if (uut.list_empty) begin
                $display("  (empty)");
            end else begin
                ptr = uut.head;
                node_count = 0;
                $write("  HEAD -> ");
                while (ptr != 5'h1F && node_count < 10) begin
                    $write("0x%02h", uut.data_mem[ptr]);
                    if (uut.next_ptr[ptr] != 5'h1F) begin
                        $write(" -> ");
                    end
                    ptr = uut.next_ptr[ptr];
                    node_count = node_count + 1;
                end
                $write(" -> NULL\n");
                $display("  Count: %0d", uut.count);
            end
        end
    endtask
    
    // Task to verify list contents
    task verify_list;
        input [7:0] expected_data [0:7];
        input integer expected_count;
        reg [4:0] ptr;
        integer i;
        reg match;
        begin
            match = 1;
            if (uut.count != expected_count) begin
                $display("ERROR: Expected count %0d, got %0d", expected_count, uut.count);
                match = 0;
            end else begin
                ptr = uut.head;
                for (i = 0; i < expected_count; i = i + 1) begin
                    if (ptr == 5'h1F) begin
                        $display("ERROR: List ended prematurely at position %0d", i);
                        match = 0;
                        i = expected_count; // break
                    end else if (uut.data_mem[ptr] != expected_data[i]) begin
                        $display("ERROR: At position %0d, expected 0x%02h, got 0x%02h", 
                                 i, expected_data[i], uut.data_mem[ptr]);
                        match = 0;
                    end
                    ptr = uut.next_ptr[ptr];
                end
                if (ptr != 5'h1F) begin
                    $display("ERROR: List is longer than expected");
                    match = 0;
                end
            end
            if (match) begin
                $display("PASS: List contents verified correctly");
            end
        end
    endtask
    
    // Test stimulus
    initial begin
        // Initialize
        $display("========================================");
        $display("  Linked List Testbench Started");
        $display("========================================");
        
        rst = 1;
        data_in = 8'h00;
        operation = OP_IDLE;
        
        // Wait for reset
        #100;
        rst = 0;
        #50;
        
        // Test 1: Insert at head
        $display("\nTest 1: Insert at Head");
        $display("------------------------");
        
        // Insert 0x11 at head
        data_in = 8'h11;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Inserted 0x11 at head");
        print_list();
        
        // Insert 0x22 at head
        data_in = 8'h22;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Inserted 0x22 at head");
        print_list();
        
        // Insert 0x33 at head
        data_in = 8'h33;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Inserted 0x33 at head");
        print_list();
        
        // Verify: List should be 0x33 -> 0x22 -> 0x11
        begin
            reg [7:0] expected [0:7];
            expected[0] = 8'h33;
            expected[1] = 8'h22;
            expected[2] = 8'h11;
            verify_list(expected, 3);
        end
        
        // Test 2: Insert at tail
        $display("\nTest 2: Insert at Tail");
        $display("------------------------");
        
        // Insert 0x44 at tail
        data_in = 8'h44;
        operation = OP_INSERT_TAIL;
        #20;
        operation = OP_IDLE;
        #100; // Extra time for tail insertion
        $display("Inserted 0x44 at tail");
        print_list();
        
        // Insert 0x55 at tail
        data_in = 8'h55;
        operation = OP_INSERT_TAIL;
        #20;
        operation = OP_IDLE;
        #100;
        $display("Inserted 0x55 at tail");
        print_list();
        
        // Verify: List should be 0x33 -> 0x22 -> 0x11 -> 0x44 -> 0x55
        begin
            reg [7:0] expected [0:7];
            expected[0] = 8'h33;
            expected[1] = 8'h22;
            expected[2] = 8'h11;
            expected[3] = 8'h44;
            expected[4] = 8'h55;
            verify_list(expected, 5);
        end
        
        // Test 3: Traverse
        $display("\nTest 3: Traverse List");
        $display("----------------------");
        operation = OP_TRAVERSE;
        #20;
        operation = OP_IDLE;
        #200; // Reduced time for simulation
        $display("Traverse initiated (check display signals in waveform)");
        
        // Test 4: Delete node
        $display("\nTest 4: Delete Node");
        $display("--------------------");
        
        // Delete 0x22 (middle node)
        data_in = 8'h22;
        operation = OP_DELETE;
        #20;
        operation = OP_IDLE;
        #100; // Extra time for search
        $display("Deleted 0x22 from list");
        print_list();
        
        // Verify: List should be 0x33 -> 0x11 -> 0x44 -> 0x55
        begin
            reg [7:0] expected [0:7];
            expected[0] = 8'h33;
            expected[1] = 8'h11;
            expected[2] = 8'h44;
            expected[3] = 8'h55;
            verify_list(expected, 4);
        end
        
        // Delete head (0x33)
        data_in = 8'h33;
        operation = OP_DELETE;
        #20;
        operation = OP_IDLE;
        #100;
        $display("Deleted 0x33 (head) from list");
        print_list();
        
        // Verify: List should be 0x11 -> 0x44 -> 0x55
        begin
            reg [7:0] expected [0:7];
            expected[0] = 8'h11;
            expected[1] = 8'h44;
            expected[2] = 8'h55;
            verify_list(expected, 3);
        end
        
        // Test 5: Delete tail node
        $display("\nTest 5: Delete Tail Node");
        $display("-------------------------");
        data_in = 8'h55;
        operation = OP_DELETE;
        #20;
        operation = OP_IDLE;
        #100;
        $display("Deleted 0x55 (tail) from list");
        print_list();
        
        // Verify: List should be 0x11 -> 0x44
        begin
            reg [7:0] expected [0:7];
            expected[0] = 8'h11;
            expected[1] = 8'h44;
            verify_list(expected, 2);
        end
        
        // Test 6: Delete non-existent node
        $display("\nTest 6: Delete Non-Existent Node");
        $display("----------------------------------");
        data_in = 8'hFF;
        operation = OP_DELETE;
        #20;
        operation = OP_IDLE;
        #100;
        if (underflow) begin
            $display("PASS: Underflow flag set for non-existent node");
        end else begin
            $display("FAIL: Underflow flag should be set");
        end
        print_list();
        #50; // Wait for flag to clear
        
        // Test 7: Overflow test
        $display("\nTest 7: Overflow Test");
        $display("----------------------");
        $display("Current list has %0d nodes, max is 8", uut.count);
        
        // Add nodes to fill the list
        data_in = 8'h66;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Added 0x66");
        
        data_in = 8'h77;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Added 0x77");
        
        data_in = 8'h88;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Added 0x88");
        
        data_in = 8'h99;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Added 0x99");
        
        data_in = 8'hAA;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Added 0xAA");
        
        data_in = 8'hBB;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Added 0xBB (should reach max 8 nodes)");
        print_list();
        
        // Try to insert one more (should overflow)
        data_in = 8'hCC;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        if (overflow) begin
            $display("PASS: Overflow flag set when list is full");
        end else begin
            $display("FAIL: Overflow flag should be set when inserting into full list");
        end
        print_list();
        #50; // Wait for flag to clear
        
        // Test 8: Reset test
        $display("\nTest 8: Reset Test");
        $display("-------------------");
        rst = 1;
        #100;
        rst = 0;
        #50;
        $display("Reset completed");
        print_list();
        
        // Verify empty list
        if (uut.list_empty && uut.count == 0) begin
            $display("PASS: List is empty after reset");
        end else begin
            $display("FAIL: List should be empty after reset");
        end
        
        // Try traverse on empty list
        operation = OP_TRAVERSE;
        #20;
        operation = OP_IDLE;
        #50;
        if (underflow) begin
            $display("PASS: Underflow flag set for empty list traverse");
        end else begin
            $display("FAIL: Underflow flag should be set for empty list");
        end
        #50; // Wait for flag to clear
        
        // Test 9: Insert after reset
        $display("\nTest 9: Operations After Reset");
        $display("--------------------------------");
        data_in = 8'hCC;
        operation = OP_INSERT_HEAD;
        #20;
        operation = OP_IDLE;
        #50;
        $display("Inserted 0xCC after reset");
        print_list();
        
        data_in = 8'hDD;
        operation = OP_INSERT_TAIL;
        #20;
        operation = OP_IDLE;
        #100;
        $display("Inserted 0xDD at tail");
        print_list();
        
        // Verify: List should be 0xCC -> 0xDD
        begin
            reg [7:0] expected [0:7];
            expected[0] = 8'hCC;
            expected[1] = 8'hDD;
            verify_list(expected, 2);
        end
        
        $display("\n========================================");
        $display("  All Tests Completed");
        $display("========================================");
        $display("Review the results above for PASS/FAIL status");
        
        #1000;
        $finish;
    end
    
    // Monitor key signals (reduced verbosity)
    initial begin
        $monitor("Time=%0t | Op=%b | Data=%h | OF=%b | UF=%b | Head=%d | Count=%d | State=%d", 
                 $time, operation, data_in, overflow, underflow, 
                 uut.head, uut.count, uut.main_state);
    end
    
    // Dump waveforms for viewing
    initial begin
        $dumpfile("linked_list_tb.vcd");
        $dumpvars(0, linked_list_tb);
        // Dump internal arrays for debugging
        for (integer i = 0; i < 8; i = i + 1) begin
            $dumpvars(0, uut.data_mem[i]);
            $dumpvars(0, uut.next_ptr[i]);
        end
    end

endmodule