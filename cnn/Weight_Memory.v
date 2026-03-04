`include "include.v"

module Weight_Memory #(parameter numWeight = 3, neuronNo=5,layerNo=1,addressWidth=10,dataWidth=16,weightFile="weights1.mif") 
    // using memory initialization file (fixed point representation)
    ( 
    input clk,
    input wen,
    input ren,
    // adderess width is 10 due to number convention followed in the design
    // fixed point represetation
    // wadd and radd are bounded by numWeight
    input [addressWidth-1:0] wadd,
    input [addressWidth-1:0] radd,
    input [dataWidth-1:0] win,
    output reg [dataWidth-1:0] wout);
    
    reg [dataWidth-1:0] mem [numWeight-1:0];

    `ifdef pretrained
        initial
		begin
	        $readmemb(weightFile, mem);
	    end
	`else
		always @(posedge clk)
		begin
			if (wen)
			begin
				mem[wadd] <= win;
			end
		end 
    `endif
    
    always @(posedge clk)
    begin
        if (ren)
        begin
            wout <= mem[radd];
        end
        else 
        begin
            wout <= {dataWidth{1'b0}}; // 0 output if not reading
        end
    end 
endmodule