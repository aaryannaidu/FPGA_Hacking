module maxFinder #(
    parameter numInput = 10,           
    parameter inputWidth = 16            
)(
    input                          clk,
    input                          rst,
    input  [numInput*inputWidth-1:0] din,
    input                          din_vld,
    output reg [31:0]              max_idx,
    output reg                     max_idx_vld
);

    reg [inputWidth-1:0] max_val;
    reg [31:0] max_index;
    integer i;

    always @(*) begin
        max_val = din[inputWidth-1:0];
        max_index = 0;
        
        for (i = 1; i < numInput; i = i + 1) begin
            if ($signed(din[(i+1)*inputWidth-1:i*inputWidth]) > $signed(max_val)) begin
                max_val = din[(i+1)*inputWidth-1:i*inputWidth];
                max_index = i;
            end
        end
    end

    // Register the outputs
    always @(posedge clk) begin
        if (rst) begin
            max_idx <= 0;
            max_idx_vld <= 1'b0;
        end
        else begin
            max_idx_vld <= din_vld; 
            if (din_vld) begin
                max_idx <= max_index; 
            end
        end
    end

endmodule