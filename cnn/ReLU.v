module ReLU  #(parameter dataWidth=16,weightIntWidth=4) (
    input           clk,
    input   [2*dataWidth-1:0]   num,
    output  reg [dataWidth-1:0]  out
);


always @(posedge clk)
begin
    if($signed(num) >= 0)
    begin
        if(|num[2*dataWidth-1-:weightIntWidth+1]) //over flow 
            out <= {1'b0,{(dataWidth-1){1'b1}}};
        else
            out <= num[2*dataWidth-1-weightIntWidth-:dataWidth];
    end
    else 
        out <= 0;      
end

endmodule