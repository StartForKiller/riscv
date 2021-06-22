/* verilator lint_off UNUSED */
module memory(
    input wire clk,
    input wire reset,
    output reg memReady,
    output reg dataReady,
    input wire memExecute,
    input wire memWrite,
    input wire [1:0] memSize,
    input wire memSign,
    input wire [31:0] memAddress,
    output reg [31:0] outputData,
    input wire [31:0] inputData,
    output reg ledState,
    output reg [7:0] sevenSeg,
    output reg [3:0] sevenSegEn
);

reg [2:0] memState = 3'h0;

reg [31:0] memAddressSaved;

wire ramEnable;
reg [31:0] inputDataInternal = 32'h0;
wire [31:0] outputDataInternal;
reg [31:0] internalData = 32'h0;
wire [31:0] resultOutputDataInternal;

wire [31:0] ramAddress;

wire ramWrite;

ram #(.RAM_SIZE(32768)) RamBlock (
    .clk(clk),
    .enable(ramEnable),
    .addr(ramAddress),
    .inData(inputDataInternal),
    .outData(outputDataInternal),
    .write(ramWrite)
);

wire ramZone;
assign ramZone = memAddress < 32'h8000;
assign ramWrite = ramZone && memState == 3'b100 && memWrite;
assign ramEnable = reset == 1'b0 && ramZone && (ramWrite || (memState == 3'b001 && memExecute));
assign resultOutputDataInternal = ramZone ? outputDataInternal : internalData; 
assign ramAddress = (memState == 3'b001) ? memAddress : memAddressSaved;

//Implement all registers
always @(posedge clk) begin
    case(reset)
        1'b1: begin
            memReady <= 1'b0;
            dataReady <= 1'b0;
            memState <= 3'b000;
            outputData <= 32'h0;
            memAddressSaved <= 32'h0;
        end
        1'b0: begin
            case(memState)
                3'b000: begin //Restart cycle
                    memReady <= 1'b1;

                    memState <= 3'b001;
                end
                3'b001: begin
                    if(memExecute == 1'b1) begin
                        memReady <= 1'b0;
                        dataReady <= 1'b0;
                        memState <= 3'b010;
                        memAddressSaved <= memAddress;
                    end
                end
                3'b010: begin //Wait here
                    if(ramZone) begin
                        if(memWrite) begin
                            case(memSize)
                                2'b00: begin
                                    inputDataInternal <= {outputDataInternal[31:8], inputData[7:0]};
                                end
                                2'b01: begin
                                    inputDataInternal <= {outputDataInternal[31:16], inputData[15:0]};
                                end
                                2'b10: begin
                                    inputDataInternal <= inputData;
                                end
                                default: begin
                                    
                                end
                            endcase
                        end
                    end
                    else if(memAddressSaved == 32'h10000) begin //Led
                        if(memWrite == 1'b1) begin
                            ledState <= ((inputData & 32'h1) != 32'h0) ? 1'b1 : 1'b0;
                            sevenSeg <= inputData[8:1];
                            sevenSegEn <= inputData[12:9];
                        end
                        else internalData <= 32'h0;
                    end
                    else begin
                        if(memWrite == 1'b0) internalData <= 32'h0; //No data, create exception better
                    end

                    if(memWrite == 1'b1) begin
                        memState <= 3'b100;
                    end
                    else begin
                        memState <= 3'b011;
                    end
                end
                3'b011: begin //Sign extend the data
                    case(memSize)
                        2'b00: begin
                            if(resultOutputDataInternal[7:7] == 1'b1 && memSign) outputData <= {24'hFFFFFF, resultOutputDataInternal[7:0]};
                            else  outputData <= {24'h000000, resultOutputDataInternal[7:0]};
                        end
                        2'b01: begin
                            if(resultOutputDataInternal[15:15] == 1'b1 && memSign) outputData <= {16'hFFFF, resultOutputDataInternal[15:0]};
                            else  outputData <= {16'h0000, resultOutputDataInternal[15:0]};
                        end
                        default: begin
                            outputData <= resultOutputDataInternal;
                        end
                    endcase
                    dataReady <= 1'b1;
                    memReady <= 1'b1;
                    memState <= 3'b000;
                end
                3'b100: begin //Delay phase on write
                    memReady <= 1'b1;
                    memState <= 3'b000;
                end
                default: begin
                    
                end
            endcase
        end
    endcase
end

endmodule