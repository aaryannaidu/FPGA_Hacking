`include "include.v"

module neuron #(
    parameter layerNumber=0,
    parameter neuronNumber=0,
    parameter inputCount=784,
    
    parameter dataWidth=16,
    parameter sigmoidAddressWidth=5,
    parameter fixedPointIntWidth=1,

    parameter activationType="relu",
    parameter biasFilePath="",
    parameter weightFilePath="./weights1.mif"
)(
    input                     clk,
    input                     rst,
    
    input                     weightValid,
    input [31:0]              weightValue,

    input [dataWidth-1:0]     inputValue,
    input                     inputValueValid,
    
    input                     biasConfigValid,
    input [31:0]              biasConfigValue,

    // ID of a neuron
    input [31:0]              configTargetLayer,
    input [31:0]              configTargetNeuron,
    
    output [dataWidth-1:0]    out,
    output reg                outVld   
);
    
    parameter addressWidth = $clog2(inputCount);
    
    reg                       weightWriteEnable;
    wire                      weightReadEnable;
    reg [addressWidth-1:0]    weightWriteAddress;
    reg [addressWidth:0]      weightReadAddress;  // Extra bit to count up to inputCount
    reg [dataWidth-1:0]       weightWriteData;
    wire [dataWidth-1:0]      weightReadData;
    
    // For calculations
    reg [2*dataWidth-1:0]     multiplicationResult; 
    reg [2*dataWidth-1:0]     accumulatedSum;
    reg [2*dataWidth-1:0]     biasValue;
    reg [31:0]                biasRegister[0:0];
    reg [dataWidth-1:0]       delayedInputValue;
    reg                       biasAddressIndex = 0;
    
    reg                       inputValidPipelineStage1;
    reg                       inputValidPipelineStage2;
    wire                      inputValidPipelineStage2_wire;
    reg                       activationInputValid; 
    reg                       delayedValidSignal;
    reg                       fallingEdgeDetected;
    
    wire [2*dataWidth:0]      additionResult;
    wire [2*dataWidth:0]      biasAdditionResult;

    // ======= INPUT ADDRESS MANAGEMENT =======
    always @(posedge clk) begin
        if(rst | outVld)
            weightReadAddress <= 0;  
        else if(inputValueValid)
            weightReadAddress <= weightReadAddress + 1;  
    end

    
    // ======= WEIGHT LOADING LOGIC =======
    always @(posedge clk) begin
        if(rst) begin
            weightWriteAddress <= {addressWidth{1'b1}}; // neat trick, +1 is done at later stage
            weightWriteEnable <= 0;
        end
        else if(weightValid & (configTargetLayer == layerNumber) & (configTargetNeuron == neuronNumber)) // write to weight memory
            begin
            weightWriteData <= weightValue;
            weightWriteAddress <= weightWriteAddress + 1; // for rst its all 1s
            weightWriteEnable <= 1;
        end
        else begin
            weightWriteEnable <= 0;
        end
    end

    // ======= BIAS LOADING LOGIC =======
    `ifdef pretrained
        initial begin
            $readmemb(biasFilePath, biasRegister);
        end
        
        always @(posedge clk) begin
            biasValue <= {biasRegister[biasAddressIndex][dataWidth-1:0], {dataWidth{1'b0}}};
        end
    `else
        always @(posedge clk) begin
            if(biasConfigValid & 
               (configTargetLayer == layerNumber) & 
               (configTargetNeuron == neuronNumber)) begin
                biasValue <= {biasConfigValue[dataWidth-1:0], {dataWidth{1'b0}}};
            end
        end
    `endif



    // ======= WEIGHT MEMORY INSTANTIATION =======
    Weight_Memory #(
        .numWeight(inputCount),
        .neuronNo(neuronNumber),
        .layerNo(layerNumber),
        .addressWidth(addressWidth),
        .dataWidth(dataWidth),
        .weightFile(weightFilePath)
    ) weightMemory (
        .clk(clk),
        .wen(weightWriteEnable),
        .ren(weightReadEnable),
        .wadd(weightWriteAddress),
        .radd(weightReadAddress),
        .win(weightWriteData),
        .wout(weightReadData)
    );

    // ========================= CONTROL SIGNAL DEALAY (LATENCY) ================
    always @(posedge clk) begin

        delayedInputValue <= inputValue;
        
        inputValidPipelineStage1 <= inputValueValid;
        inputValidPipelineStage2 <= inputValidPipelineStage1;
        
        activationInputValid <= ((weightReadAddress == inputCount) & fallingEdgeDetected) ? 1'b1 : 1'b0;
        outVld <= activationInputValid;
        
        delayedValidSignal <= inputValidPipelineStage2_wire;
        fallingEdgeDetected <= !inputValidPipelineStage2_wire & delayedValidSignal;
    end

    // ================================= MULTIPLICATION  =========================
    always @(posedge clk) begin
        multiplicationResult <= $signed(delayedInputValue) * $signed(weightReadData);
    end

    assign inputValidPipelineStage2_wire = inputValidPipelineStage2;
    assign additionResult = multiplicationResult + accumulatedSum;
    assign biasAdditionResult = biasValue + accumulatedSum;
    assign weightReadEnable = inputValueValid;


    // ======= ACCUMULATION (including overflow) =======
    always @(posedge clk) begin
        if(rst | outVld)
            accumulatedSum <= 0;  

        else if(inputValidPipelineStage2_wire) 
        begin
            if(!multiplicationResult[2*dataWidth-1] & !accumulatedSum[2*dataWidth-1] & additionResult[2*dataWidth-1]) 
            begin
                accumulatedSum[2*dataWidth-1] <= 1'b0;  
                accumulatedSum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};  
            end
 
             else if(multiplicationResult[2*dataWidth-1] & accumulatedSum[2*dataWidth-1] & !additionResult[2*dataWidth-1]) 
            begin
                accumulatedSum[2*dataWidth-1] <= 1'b1;  
                accumulatedSum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}}; 
            end
            else
                accumulatedSum <= additionResult;
        end

        else if((weightReadAddress == inputCount) & fallingEdgeDetected) 
        begin            
            if(!biasValue[2*dataWidth-1] & !accumulatedSum[2*dataWidth-1] & biasAdditionResult[2*dataWidth-1]) 
            begin
                accumulatedSum[2*dataWidth-1] <= 1'b0;  
                accumulatedSum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};  
            end

            else if(biasValue[2*dataWidth-1] & accumulatedSum[2*dataWidth-1] & !biasAdditionResult[2*dataWidth-1]) 
            begin
                accumulatedSum[2*dataWidth-1] <= 1'b1;  
                accumulatedSum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};  
            end

            else
                accumulatedSum <= biasAdditionResult; 
        end

    end    

    
    // ================================ ACTIVATION FUNCTIONS =======================
    generate
        if(activationType == "sigmoid") begin: sigmoidActivation
            // Use sigmoid lookup table
            Sig_ROM #(
                .inWidth(sigmoidAddressWidth),
                .dataWidth(dataWidth)
            ) sigmoidROM (
                .clk(clk),
                .x(accumulatedSum[2*dataWidth-1-:sigmoidAddressWidth]),
                .out(out)
            );
        end
        else begin: reluActivation
            // Use ReLU activation
            ReLU #(
                .dataWidth(dataWidth),
                .weightIntWidth(fixedPointIntWidth)
            ) reluFunction (
                .clk(clk),
                .x(accumulatedSum),
                .out(out)
            );
        end
    endgenerate



    // ======= DEBUG OUTPUT =======
    `ifdef DEBUG
    always @(posedge clk) begin
        if(outVld)
            $display(neuronNumber,,,,"%b",out);
    end
    `endif
endmodule