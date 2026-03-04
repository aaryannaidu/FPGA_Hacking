module Sigmoid #(parameter inWidth=10, dataWidth=16) (
    input           clk,
    input   [inWidth-1:0]   num,
    output  [dataWidth-1:0]  out
    );
    
    reg [dataWidth-1:0] mem [2**inWidth-1:0];
    reg [inWidth-1:0] y;
	
	initial
	begin
		$readmemb("Sigmoid_LUT.mif",mem);
	end
    
    always @(posedge clk) 
    begin // mem address mapping, 
        if($signed(num) >= 0)
            y <= num+(2**(inWidth-1));
        else 
            y <= num-(2**(inWidth-1));      
    end
    
    assign out = mem[y];
    
endmodule