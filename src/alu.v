/* verilator lint_off UNUSED */
module alu(
    input wire clk,
    input wire en,
    input wire reset,
    input wire rwEn,
    input wire [31:0] imm,
    input wire [31:0] data1,
    input wire [31:0] data2,
    input wire [31:0] dataCsr,
    output reg [31:0] dataDest,
    output reg [31:0] dataCsrDest,
    input wire [6:0] opcode,
    input wire [14:0] func,
    input wire [31:0] currentPC,
    output reg [31:0] PCdest,
    output reg pcRwEn,
    output reg rwAluEn,
    output reg rwAluEnCsr,
    input wire [4:0] rs1
);

//We will implement the functions in order, first create test functions and the implemnt it

always @(posedge clk) begin
    if(reset) begin
        rwAluEn <= 1'b0;
        dataDest <= 32'h0;
        rwAluEnCsr <= 1'b0;
        pcRwEn <= 1'b0;
        dataCsrDest <= 32'h0;
    end
    else if(en == 1'b1) begin
        rwAluEn <= rwEn;

        case(opcode[6:2])
            5'b00100: begin //OP-IMM normal alu operation
                case(func[2:0])
                    3'b000: begin //ADDI
                        dataDest <= $signed(data1) + $signed(imm);
                    end
                    3'b010: begin //SLTI
                        dataDest <= ($signed(data1) < $signed(imm)) ? 32'h1 : 32'h0;
                    end
                    3'b011: begin //SLTI
                        dataDest <= (data1 < imm) ? 32'h1 : 32'h0;
                    end
                    3'b100: begin //XORI
                        dataDest <= data1 ^ imm;
                    end
                    3'b110: begin //ORI
                        dataDest <= data1 | imm;
                    end
                    3'b111: begin //ANDI
                        dataDest <= data1 & imm;
                    end
                    default: begin
                        case(func[9:3])
                            7'b0000000: begin
                                case(func[2:0])
                                    3'b001: begin
                                        dataDest <= data1 << imm[4:0];
                                    end
                                    3'b101: begin
                                        dataDest <= data1 >> imm[4:0];
                                    end
                                    default: begin

                                    end
                                endcase
                            end
                            7'b0100000: begin
                                case(func[2:0])
                                    3'b101: begin
                                        dataDest <= data1 >>> imm[4:0];
                                    end
                                    default: begin

                                    end
                                endcase
                            end
                            default: begin
                                
                            end
                        endcase
                    end
                endcase
                pcRwEn <= 1'b0;
                rwAluEnCsr <= 1'b0;
            end
            5'b01100: begin //OP normal alu operation
                case(func[9:3])
                    7'b0000000: begin
                        case(func[2:0])
                            3'b000: begin //ADD
                                dataDest <= $signed(data1) + $signed(data2);
                            end
                            3'b001: begin //SLL
                                dataDest <= data1 << data2[4:0];
                            end
                            3'b010: begin //SLT
                                dataDest <= ($signed(data1) < $signed(data2)) ? 32'h1 : 32'h0;
                            end
                            3'b011: begin //SLTU
                                dataDest <= (data1 < data2) ? 32'h1 : 32'h0;
                            end
                            3'b100: begin //XOR
                                dataDest <= data1 ^ data2;
                            end
                            3'b101: begin //SRL
                                dataDest <= data1 >> data2[4:0];
                            end
                            3'b110: begin //OR
                                dataDest <= data1 | data2;
                            end
                            3'b111: begin //AND
                                dataDest <= data1 & data2;
                            end
                            default: begin
                                
                            end
                        endcase
                    end
                    7'b0100000: begin //SUB/SRA
                        case(func[2:0])
                            3'b000: begin //SUB
                                dataDest <= $signed(data1) - $signed(data2);
                            end
                            3'b101: begin //SRA
                                dataDest <= $signed(data1) >>> data2[4:0];
                            end
                            default: begin
                                
                            end
                        endcase
                    end
                    default: begin
                    end
                endcase
                pcRwEn <= 1'b0;
                rwAluEnCsr <= 1'b0;
            end
            5'b01101: begin
                dataDest <= imm;
                pcRwEn <= 1'b0;
                rwAluEnCsr <= 1'b0;
            end
            5'b00101: begin
                dataDest <= imm + currentPC;
                pcRwEn <= 1'b0;
                rwAluEnCsr <= 1'b0;
            end
            5'b11000: begin
                case(func[2:0])
                    3'b000: begin
                        if(data1 == data2) pcRwEn <= 1'b1;
                        else pcRwEn <= 1'b0;
                    end
                    3'b001: begin
                        if(data1 != data2) pcRwEn <= 1'b1;
                        else pcRwEn <= 1'b0;
                    end
                    3'b100: begin
                        if($signed(data1) < $signed(data2)) pcRwEn <= 1'b1;
                        else pcRwEn <= 1'b0;
                    end
                    3'b101: begin
                        if($signed(data1) >= $signed(data2)) pcRwEn <= 1'b1;
                        else pcRwEn <= 1'b0;
                    end
                    3'b110: begin
                        if(data1 < data2) pcRwEn <= 1'b1;
                        else pcRwEn <= 1'b0;
                    end
                    3'b111: begin
                        if(data1 >= data2) pcRwEn <= 1'b1;
                        else pcRwEn <= 1'b0;
                    end
                    default: begin
                        
                    end
                endcase
                PCdest <= currentPC + imm;
                rwAluEnCsr <= 1'b0;
            end
            5'b11011: begin
                pcRwEn <= 1'b1;
                PCdest <= currentPC + imm;
                dataDest <= currentPC + 32'h4;
                rwAluEnCsr <= 1'b0;
            end
            5'b11001: begin
                pcRwEn <= 1'b1;
                PCdest <= data1 + imm;
                dataDest <= currentPC + 32'h4;
                rwAluEnCsr <= 1'b0;
            end
            5'b00000: begin
                pcRwEn <= 1'b0;
                dataDest <= data1 + $signed(imm);
                rwAluEnCsr <= 1'b0;
            end
            5'b01000: begin
                pcRwEn <= 1'b0;
                dataDest <= data1 + $signed(imm);
                rwAluEnCsr <= 1'b0;
            end
            5'b11100: begin
                pcRwEn <= 1'b0;
                case(func[2:0])
                    3'b001: begin
                        dataCsrDest <= data1;
                        dataDest <= dataCsr;
                        rwAluEnCsr <= 1'b1;
                    end
                    3'b010: begin
                        dataCsrDest <= data1 | dataCsr;
                        dataDest <= dataCsr;
                        if(rs1 == 5'h0) rwAluEnCsr <= 1'b0;
                        else rwAluEnCsr <= 1'b1;
                    end
                    3'b011: begin
                        dataCsrDest <= dataCsr & ~(data1);
                        dataDest <= dataCsr;
                        if(rs1 == 5'h0) rwAluEnCsr <= 1'b0;
                        else rwAluEnCsr <= 1'b1;
                    end

                    3'b101: begin
                        dataCsrDest <= {27'h0, rs1};
                        dataDest <= dataCsr;
                        rwAluEnCsr <= 1'b1;
                    end
                    3'b110: begin
                        dataCsrDest <= {27'h0, rs1} | dataCsr;
                        dataDest <= dataCsr;
                        if(rs1 == 5'h0) rwAluEnCsr <= 1'b0;
                        else rwAluEnCsr <= 1'b1;
                    end
                    3'b111: begin
                        dataCsrDest <= dataCsr & ~({27'h0, rs1});
                        dataDest <= dataCsr;
                        if(rs1 == 5'h0) rwAluEnCsr <= 1'b0;
                        else rwAluEnCsr <= 1'b1;
                    end
                    default: begin
                        rwAluEnCsr <= 1'b0;
                    end
                endcase
            end
            default: begin
                pcRwEn <= 1'b0;
                rwAluEnCsr <= 1'b0;
            end
        endcase
    end
end

endmodule