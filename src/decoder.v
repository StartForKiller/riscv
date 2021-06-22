//Memop:
// 0b00 | width -> None
// 0b01 | width -> Load
// 0b10 | width -> Store
// 0b11 | width -> Misc-mem

/* verilator lint_off UNUSED */
module decoder(
    input wire clk,
    input wire en,
    input wire reset,
    input wire [31:0] data,
    output reg [4:0] rd,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg rwEn,
    output reg [14:0] func,
    output reg [31:0] imm,
    output reg [4:0] memop,
    output reg [6:0] opcode,
    output reg csrEn,
    output reg csrReadEn
);

always @(posedge clk) begin
    rs1 <= data[19:15];
    rs2 <= data[24:20];

    if(reset) begin
        rd <= 5'h0;
        rwEn <= 1'b0;
        func <= 15'h0;
        imm <= 32'h0;
        memop <= 5'h0;
        opcode <= 7'h0;
        csrEn <= 1'b0;
        csrReadEn <= 1'b0;
    end
    else if(en == 1'b1) begin
        rd <= data[11:7];
        opcode <= data[6:0];

        case(data[6:2])
            5'b00000: begin //LOAD
                if(data[31:31] == 1'b1) begin
                    imm <= {20'hFFFFF, data[31:20]};
                end
                else begin
                    imm <= {20'h00000, data[31:20]};
                end
                memop <= {2'b01, data[14:12]};
                func <= 15'h00;
                rwEn <= 1'b1;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b00011: begin //MISC-MEM
                func <= {data[31:20], data[14:12]};
                memop <= 5'b11000;
                imm <= 32'h00000000;
                rwEn <= 1'b0;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b00100: begin //OP-IMM
                if(data[31:31] == 1'b1) begin
                    imm <= {20'hFFFFF, data[31:20]};
                end
                else begin
                    imm <= {20'h00000, data[31:20]};
                end
                func <= {5'h0, data[31:25], data[14:12]};
                memop <= 5'h0;
                rwEn <= 1'b1;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b00101: begin //AUIPC
                imm <= {data[31:12], 12'h000};
                func <= 15'h00;
                memop <= 5'h0;
                rwEn <= 1'b1;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b01000: begin //STORE
                if(data[31:31] == 1'b1) begin
                    imm <= {20'hFFFFF, data[31:25], data[11:7]};
                end
                else begin
                    imm <= {20'h00000, data[31:25], data[11:7]};
                end
                memop <= {2'b10, data[14:12]};
                func <= 15'h00;
                rwEn <= 1'b0;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b01100: begin //OP
                func <= {5'h0, data[31:25], data[14:12]};
                memop <= 5'h0;
                imm <= 32'h00000000;
                rwEn <= 1'b1;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b01101: begin //LUI
                imm <= {data[31:12], 12'h000};
                func <= 15'h00;
                memop <= 5'h0;
                rwEn <= 1'b1;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b11000: begin //BRANCH
                if(data[31:31] == 1'b1) begin
                    imm <= {3'h7, 16'hFFFF, data[31:31], data[7:7], data[30:25], data[11:8], 1'b0};
                end
                else begin
                    imm <= {3'h0, 16'h0000, data[31:31], data[7:7], data[30:25], data[11:8], 1'b0};
                end
                func <= {12'h0, data[14:12]};
                memop <= 5'h0;
                rwEn <= 1'b0;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b11001: begin //JALR
                if(data[31:31] == 1'b1) begin
                    imm <= {20'hFFFFF, data[31:20]};
                end
                else begin
                    imm <= {20'h00000, data[31:20]};
                end
                func <= 15'h00;
                memop <= 5'h0;
                rwEn <= 1'b1;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b11011: begin //JAL
                if(data[31:31] == 1'b1) begin
                    imm <= {3'h7, 8'hFF, data[31:31], data[19:12], data[20:20], data[30:21], 1'b0};
                end
                else begin
                    imm <= {3'h0, 8'h00, data[31:31], data[19:12], data[20:20], data[30:21], 1'b0};
                end
                memop <= 5'h0;
                func <= 15'h00;
                rwEn <= 1'b1;
                csrEn <= 1'b0;
                csrReadEn <= 1'b0;
            end
            5'b11100: begin //SYSTEM
                func <= {data[31:20], data[14:12]};
                memop <= 5'h0;
                imm <= 32'h00000000;
                rwEn <= 1'b0;
                if(data[13:12] != 2'b000) begin
                    csrEn <= 1'b1;
                    if(data[11:7] == 5'h0) csrReadEn <= 1'b0;
                    else csrReadEn <= 1'b1;
                end
                else begin
                    csrEn <= 1'b0;
                    csrReadEn <= 1'b0;
                end
            end
            default: begin
                
            end
        endcase
    end
end

endmodule