module Layer_1 #(
    parameter NN = 30,
    parameter numWeight = 784,
    parameter dataWidth = 16,
    parameter layerNum = 1,
    parameter sigmoidSize = 10,
    parameter weightIntWidth = 4,
    parameter actType = "relu"
)(
    input                       clk,
    input                       rst,
    input                       weightValid,
    input                       biasValid,
    input [31:0]                weightValue,
    input [31:0]                biasValue,
    input [31:0]                config_layer_num,
    input [31:0]                config_neuron_num,
    input                       x_valid,
    input [dataWidth-1:0]       x_in,
    output [NN-1:0]             o_valid,
    output [NN*dataWidth-1:0]   x_out
);

    //weight file 
    function [128*8-1:0] get_weight_file;
        input integer neuron_idx;
        begin
            case(neuron_idx)
                0: get_weight_file = "w_1_0.mif";
                1: get_weight_file = "w_1_1.mif";
                2: get_weight_file = "w_1_2.mif";
                3: get_weight_file = "w_1_3.mif";
                4: get_weight_file = "w_1_4.mif";
                5: get_weight_file = "w_1_5.mif";
                6: get_weight_file = "w_1_6.mif";
                7: get_weight_file = "w_1_7.mif";
                8: get_weight_file = "w_1_8.mif";
                9: get_weight_file = "w_1_9.mif";
                10: get_weight_file = "w_1_10.mif";
                11: get_weight_file = "w_1_11.mif";
                12: get_weight_file = "w_1_12.mif";
                13: get_weight_file = "w_1_13.mif";
                14: get_weight_file = "w_1_14.mif";
                15: get_weight_file = "w_1_15.mif";
                16: get_weight_file = "w_1_16.mif";
                17: get_weight_file = "w_1_17.mif";
                18: get_weight_file = "w_1_18.mif";
                19: get_weight_file = "w_1_19.mif";
                20: get_weight_file = "w_1_20.mif";
                21: get_weight_file = "w_1_21.mif";
                22: get_weight_file = "w_1_22.mif";
                23: get_weight_file = "w_1_23.mif";
                24: get_weight_file = "w_1_24.mif";
                25: get_weight_file = "w_1_25.mif";
                26: get_weight_file = "w_1_26.mif";
                27: get_weight_file = "w_1_27.mif";
                28: get_weight_file = "w_1_28.mif";
                29: get_weight_file = "w_1_29.mif";
                default: get_weight_file = "w_1_0.mif";
            endcase
        end
    endfunction

    // bias file 
    function [128*8-1:0] get_bias_file;
        input integer neuron_idx;
        begin
            case(neuron_idx)
                0: get_bias_file = "b_1_0.mif";
                1: get_bias_file = "b_1_1.mif";
                2: get_bias_file = "b_1_2.mif";
                3: get_bias_file = "b_1_3.mif";
                4: get_bias_file = "b_1_4.mif";
                5: get_bias_file = "b_1_5.mif";
                6: get_bias_file = "b_1_6.mif";
                7: get_bias_file = "b_1_7.mif";
                8: get_bias_file = "b_1_8.mif";
                9: get_bias_file = "b_1_9.mif";
                10: get_bias_file = "b_1_10.mif";
                11: get_bias_file = "b_1_11.mif";
                12: get_bias_file = "b_1_12.mif";
                13: get_bias_file = "b_1_13.mif";
                14: get_bias_file = "b_1_14.mif";
                15: get_bias_file = "b_1_15.mif";
                16: get_bias_file = "b_1_16.mif";
                17: get_bias_file = "b_1_17.mif";
                18: get_bias_file = "b_1_18.mif";
                19: get_bias_file = "b_1_19.mif";
                20: get_bias_file = "b_1_20.mif";
                21: get_bias_file = "b_1_21.mif";
                22: get_bias_file = "b_1_22.mif";
                23: get_bias_file = "b_1_23.mif";
                24: get_bias_file = "b_1_24.mif";
                25: get_bias_file = "b_1_25.mif";
                26: get_bias_file = "b_1_26.mif";
                27: get_bias_file = "b_1_27.mif";
                28: get_bias_file = "b_1_28.mif";
                29: get_bias_file = "b_1_29.mif";
                default: get_bias_file = "b_1_0.mif";
            endcase
        end
    endfunction

    // Generate NN neurons
    genvar i;
    generate
        for (i = 0; i < NN; i = i + 1) begin : neuron_gen
            neuron #(
                .numWeight(numWeight),
                .layerNo(layerNum),
                .neuronNo(i),
                .dataWidth(dataWidth),
                .sigmoidSize(sigmoidSize),
                .weightIntWidth(weightIntWidth),
                .actType(actType),
                .weightFile(get_weight_file(i)),
                .biasFile(get_bias_file(i))
            ) neuron_inst (
                .clk(clk),
                .rst(rst),
                .inputValue(x_in),
                .inputValueValid(x_valid),
                .weightValue(weightValue),
                .weightValid(weightValid),
                .biasValue(biasValue),
                .biasValid(biasValid),                
                .configTargetLayer(config_layer_num),
                .configTargetNeuron(config_neuron_num),
                .out(x_out[i*dataWidth +: dataWidth]),
                .outvalid(o_valid[i])
            );
        end
    endgenerate

endmodule