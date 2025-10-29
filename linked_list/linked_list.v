module linked_list #(
    parameter MAX_NODES = 32,
    parameter ADDR_WIDTH = 5  // log2(32) = 5
)(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire [2:0] operation,
    output reg overflow,
    output reg underflow,
    output reg [6:0] seg,
    output reg [3:0] an,
    output reg dp
);

    // Data storage arrays
    reg [7:0] data_mem [0:MAX_NODES-1];
    reg [ADDR_WIDTH-1:0] next_ptr [0:MAX_NODES-1];
    reg [MAX_NODES-1:0] free_list;  // Bitmap for free nodes
    
    // List management
    reg [ADDR_WIDTH-1:0] head;
    reg [ADDR_WIDTH:0] count;  // Extra bit to detect overflow
    reg list_empty;
    
    // Operation codes
    localparam OP_IDLE = 3'b000;
    localparam OP_INSERT_HEAD = 3'b100;
    localparam OP_INSERT_TAIL = 3'b101;
    localparam OP_DELETE = 3'b110;
    localparam OP_TRAVERSE = 3'b111;
    
    // Special value for NULL pointer
    localparam NULL = {ADDR_WIDTH{1'b1}};
    
    // State machines
    reg [3:0] main_state;
    reg [3:0] traverse_state;
    
    localparam MAIN_IDLE = 4'd0;
    localparam MAIN_INSERT_HEAD = 4'd1;
    localparam MAIN_INSERT_TAIL_FIND = 4'd2;
    localparam MAIN_INSERT_TAIL_LINK = 4'd3;
    localparam MAIN_DELETE_SEARCH = 4'd4;
    localparam MAIN_DELETE_UNLINK = 4'd5;
    localparam MAIN_TRAVERSE_START = 4'd6;
    
    localparam TRAV_IDLE = 4'd0;
    localparam TRAV_DISPLAY = 4'd1;
    localparam TRAV_WAIT = 4'd2;
    localparam TRAV_NEXT = 4'd3;
    
    // Working registers
    reg [ADDR_WIDTH-1:0] new_node;
    reg [ADDR_WIDTH-1:0] curr_ptr;
    reg [ADDR_WIDTH-1:0] prev_ptr;
    reg [ADDR_WIDTH-1:0] traverse_ptr;
    reg [31:0] traverse_delay;
    reg [7:0] current_display_data;
    reg [7:0] search_data;
    
    // Reset display
    reg [31:0] reset_timer;
    reg show_reset;
    localparam RESET_DISPLAY_TIME = 32'd500_000_000; // 5 seconds at 100MHz
    
    // 7-segment display refresh
    reg [19:0] refresh_counter;
    wire [1:0] display_select;
    assign display_select = refresh_counter[19:18];
    
    // Previous operation to detect edges
    reg [2:0] prev_operation;
    wire op_trigger;
    assign op_trigger = (operation != prev_operation) && (operation != OP_IDLE) && (main_state == MAIN_IDLE);
    
    integer i;
    
    // Find first free node
    function [ADDR_WIDTH-1:0] find_free_node;
        input dummy;
        integer j;
        begin
            find_free_node = NULL;
            for (j = 0; j < MAX_NODES; j = j + 1) begin
                if (free_list[j] && (find_free_node == NULL)) begin
                    find_free_node = j[ADDR_WIDTH-1:0];
                end
            end
        end
    endfunction
    
    // Main state machine
    always @(posedge clk) begin
        if (rst) begin
            // Reset all
            head <= NULL;
            count <= 0;
            list_empty <= 1;
            overflow <= 0;
            underflow <= 0;
            free_list <= {MAX_NODES{1'b1}};
            main_state <= MAIN_IDLE;
            traverse_state <= TRAV_IDLE;
            show_reset <= 1;
            reset_timer <= RESET_DISPLAY_TIME;
            prev_operation <= OP_IDLE;
            current_display_data <= 8'h00;
            
            for (i = 0; i < MAX_NODES; i = i + 1) begin
                data_mem[i] <= 8'h00;
                next_ptr[i] <= NULL;
            end
        end
        else begin
            prev_operation <= operation;
            
            // Reset display timer
            if (show_reset) begin
                if (reset_timer > 0) begin
                    reset_timer <= reset_timer - 1;
                end else begin
                    show_reset <= 0;
                end
            end
            
            // Auto-clear flags after longer delay (for testbench checking)
            // Flags stay high for at least 2 cycles after returning to IDLE
            
            // Main state machine
            case (main_state)
                MAIN_IDLE: begin
                    if (op_trigger) begin
                        case (operation)
                            OP_INSERT_HEAD: begin
                                if (count >= MAX_NODES) begin
                                    overflow <= 1;
                                end else begin
                                    new_node <= find_free_node(1'b0);
                                    main_state <= MAIN_INSERT_HEAD;
                                end
                            end
                            
                            OP_INSERT_TAIL: begin
                                if (count >= MAX_NODES) begin
                                    overflow <= 1;
                                end else begin
                                    new_node <= find_free_node(1'b0);
                                    if (list_empty) begin
                                        main_state <= MAIN_INSERT_HEAD; // Same as insert head
                                    end else begin
                                        curr_ptr <= head;
                                        main_state <= MAIN_INSERT_TAIL_FIND;
                                    end
                                end
                            end
                            
                            OP_DELETE: begin
                                if (list_empty) begin
                                    underflow <= 1;
                                end else begin
                                    search_data <= data_in;
                                    curr_ptr <= head;
                                    prev_ptr <= NULL;
                                    main_state <= MAIN_DELETE_SEARCH;
                                end
                            end
                            
                            OP_TRAVERSE: begin
                                if (list_empty) begin
                                    underflow <= 1;
                                end else begin
                                    traverse_ptr <= head;
                                    traverse_state <= TRAV_DISPLAY;
                                end
                            end
                        endcase
                    end
                end
                
                MAIN_INSERT_HEAD: begin
                    if (new_node != NULL) begin
                        free_list[new_node] <= 0;
                        data_mem[new_node] <= data_in;
                        next_ptr[new_node] <= head;
                        head <= new_node;
                        count <= count + 1;
                        list_empty <= 0;
                    end else begin
                        overflow <= 1;
                    end
                    main_state <= MAIN_IDLE;
                end
                
                MAIN_INSERT_TAIL_FIND: begin
                    if (next_ptr[curr_ptr] == NULL) begin
                        main_state <= MAIN_INSERT_TAIL_LINK;
                    end else begin
                        curr_ptr <= next_ptr[curr_ptr];
                    end
                end
                
                MAIN_INSERT_TAIL_LINK: begin
                    if (new_node != NULL) begin
                        free_list[new_node] <= 0;
                        data_mem[new_node] <= data_in;
                        next_ptr[new_node] <= NULL;
                        next_ptr[curr_ptr] <= new_node;
                        count <= count + 1;
                    end else begin
                        overflow <= 1;
                    end
                    main_state <= MAIN_IDLE;
                end
                
                MAIN_DELETE_SEARCH: begin
                    if (data_mem[curr_ptr] == search_data) begin
                        main_state <= MAIN_DELETE_UNLINK;
                    end else if (next_ptr[curr_ptr] == NULL) begin
                        // Not found
                        underflow <= 1;
                        main_state <= MAIN_IDLE;
                    end else begin
                        prev_ptr <= curr_ptr;
                        curr_ptr <= next_ptr[curr_ptr];
                    end
                end
                
                MAIN_DELETE_UNLINK: begin
                    if (prev_ptr == NULL) begin
                        // Deleting head
                        head <= next_ptr[curr_ptr];
                    end else begin
                        next_ptr[prev_ptr] <= next_ptr[curr_ptr];
                    end
                    free_list[curr_ptr] <= 1;
                    count <= count - 1;
                    if (count == 1) list_empty <= 1;
                    main_state <= MAIN_IDLE;
                end
                
                default: main_state <= MAIN_IDLE;
            endcase
            
            // Traverse state machine (runs independently)
            case (traverse_state)
                TRAV_IDLE: begin
                    // Waiting
                end
                
                TRAV_DISPLAY: begin
                    if (traverse_ptr != NULL) begin
                        current_display_data <= data_mem[traverse_ptr];
                        traverse_delay <= 32'd100_000_000; // 1 second
                        traverse_state <= TRAV_WAIT;
                    end else begin
                        traverse_state <= TRAV_IDLE;
                    end
                end
                
                TRAV_WAIT: begin
                    if (traverse_delay > 0) begin
                        traverse_delay <= traverse_delay - 1;
                    end else begin
                        traverse_state <= TRAV_NEXT;
                    end
                end
                
                TRAV_NEXT: begin
                    traverse_ptr <= next_ptr[traverse_ptr];
                    traverse_state <= TRAV_DISPLAY;
                end
                
                default: traverse_state <= TRAV_IDLE;
            endcase
        end
    end
    
    // 7-segment display refresh counter
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end
    
    // Display multiplexing and segment generation
    always @(*) begin
        if (show_reset) begin
            // Display "-rSt"
            case (display_select)
                2'b00: begin
                    an = 4'b1110;
                    seg = 7'b0111111; // t
                end
                2'b01: begin
                    an = 4'b1101;
                    seg = 7'b0010010; // S
                end
                2'b10: begin
                    an = 4'b1011;
                    seg = 7'b0101111; // r
                end
                2'b11: begin
                    an = 4'b0111;
                    seg = 7'b0111111; // -
                end
            endcase
        end else begin
            // Display current data in hex
            case (display_select)
                2'b00: begin
                    an = 4'b1110;
                    seg = hex_to_seg(current_display_data[3:0]);
                end
                2'b01: begin
                    an = 4'b1101;
                    seg = hex_to_seg(current_display_data[7:4]);
                end
                default: begin
                    an = 4'b1111; // Turn off other displays
                    seg = 7'b1111111;
                end
            endcase
        end
        dp = 1; // Decimal point off
    end
    
    // Hex to 7-segment converter (common cathode)
    function [6:0] hex_to_seg;
        input [3:0] hex;
        begin
            case (hex)
                4'h0: hex_to_seg = 7'b1000000; // 0
                4'h1: hex_to_seg = 7'b1111001; // 1
                4'h2: hex_to_seg = 7'b0100100; // 2
                4'h3: hex_to_seg = 7'b0110000; // 3
                4'h4: hex_to_seg = 7'b0011001; // 4
                4'h5: hex_to_seg = 7'b0010010; // 5
                4'h6: hex_to_seg = 7'b0000010; // 6
                4'h7: hex_to_seg = 7'b1111000; // 7
                4'h8: hex_to_seg = 7'b0000000; // 8
                4'h9: hex_to_seg = 7'b0010000; // 9
                4'hA: hex_to_seg = 7'b0001000; // A
                4'hB: hex_to_seg = 7'b0000011; // b
                4'hC: hex_to_seg = 7'b1000110; // C
                4'hD: hex_to_seg = 7'b0100001; // d
                4'hE: hex_to_seg = 7'b0000110; // E
                4'hF: hex_to_seg = 7'b0001110; // F
                default: hex_to_seg = 7'b1111111;
            endcase
        end
    endfunction

endmodule

module linked_list_top(
    input wire clk,           // 100MHz clock
    input wire btnC,          // Center button for reset
    input wire [15:0] sw,     // Switches
    output wire [15:0] led,   // LEDs
    output wire [6:0] seg,    // 7-segment cathodes
    output wire [3:0] an,     // 7-segment anodes
    output wire dp            // Decimal point
);

    // Debounce reset button
    reg [19:0] btn_debounce;
    reg rst_sync;
    
    always @(posedge clk) begin
        if (btnC) begin
            if (btn_debounce < 20'hFFFFF)
                btn_debounce <= btn_debounce + 1;
            else
                rst_sync <= 1;
        end else begin
            btn_debounce <= 0;
            rst_sync <= 0;
        end
    end
    
    // Extract inputs from switches
    wire [7:0] data_in = sw[7:0];
    wire [2:0] operation = sw[15:13];
    
    // LED outputs
    wire overflow_flag, underflow_flag;
    
    assign led[0] = overflow_flag;
    assign led[1] = underflow_flag;
    assign led[15:2] = 14'b0;  // Unused LEDs off
    
    // Instantiate linked list module
    linked_list #(
        .MAX_NODES(32)
    ) ll_inst (
        .clk(clk),
        .rst(rst_sync),
        .data_in(data_in),
        .operation(operation),
        .overflow(overflow_flag),
        .underflow(underflow_flag),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

endmodule