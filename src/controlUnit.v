/* verilator lint_off UNUSED */
module controlUnit(
    input wire clk,
    input wire reset,
    input wire [6:0] opcode,
    input wire [31:0] pcAddr,
    input wire pcWrEn,

    input wire memReady,
    input wire dataReady,
    output reg memExecute,

    output wire [3:0] outState,
    output wire [31:0] outputPC
);

reg [31:0] PC = 32'h0; //Program counter
reg [3:0] state = 4'h0;
reg [1:0] memState = 2'h0;

assign outState = state;

always @(posedge clk) begin
    case(reset)
        1'b1: begin
            state <= 4'h0;
            PC <= 32'h0; //Initial value, change this
            memState <= 2'h0;
            memExecute <= 1'b0;
        end
        1'b0: begin
            case(state)
                4'b0000: begin //Fetch
                    case(memState)
                        2'b00: begin //Wait for mem to be ready for operations
                            if(memReady == 1'b1) begin
                                memState <= 2'b01;
                                memExecute <= 1'b1;
                            end
                        end
                        2'b01: begin //Release the execute signal and advance
                            memExecute <= 1'b0;
                            memState <= 2'b010;
                        end
                        2'b10: begin //Wait for the data to be ready
                            if(dataReady == 1'b1) begin //Advance to the next stage if true
                                state <= 4'b0001;
                                memState <= 2'b000;
                            end
                        end
                        default: begin
                            
                        end
                    endcase
                end
                4'b0001: begin //Decode, done by another module
                    state <= 4'b0010;
                end
                4'b0010: begin //Execute, done by the alu
                    if(opcode == 7'b0000011 || opcode == 7'b0100011)
                        state <= 4'b0011; //If load or store goto mem stage
                    else
                        state <= 4'b0100; //Else we don't need to write or load to mem
                end
                4'b0011: begin //Memory stage, to be done
                    case(memState)
                        2'b00: begin //Wait for mem to be ready for operations
                            if(memReady == 1'b1) begin
                                memState <= 2'b01;
                                memExecute <= 1'b1;
                            end
                        end
                        2'b01: begin //Release the execute signal and advance
                            memExecute <= 1'b0;
                            memState <= 2'b10;
                        end
                        2'b10: begin
                            if(opcode[6:2] == 5'b01000) begin
                                memState <= 2'b00;
                                state <= 4'b0110; //One delay stage
                            end
                            else if(dataReady == 1'b1) begin
                                memState <= 2'b00;
                                state <= 4'b0100;
                            end
                        end
                        default: begin
                            
                        end
                    endcase
                end
                4'b0100: begin //Writeback stage
                    state <= 4'b0101;
                    if(pcWrEn == 1'b1) begin
                        PC <= pcAddr;
                    end
                    else begin
                        PC <= PC + 31'h4; //Instruction size, continue normal execution
                    end
                end
                4'b0101: begin
                    state <= 4'b0000;
                end
                //TODO, interrupts
                default: begin
                    state <= 4'b0000;
                    PC <= PC + 31'h4; //Stores always increments pc
                end
            endcase
        end
    endcase
end

assign outputPC = PC;

endmodule