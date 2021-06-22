/* verilator lint_off UNUSED */
module regfile(
    input wire clk,
    input wire en,
    input wire writeEn,
    input wire [4:0] rd,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    output reg [31:0] data1,
    output reg [31:0] data2,
    input wire [31:0] dataDest
);

reg [31:0] registers [31:0];

integer i;
initial begin
    for(i = 0; i < 32; i = i + 1) registers[i] = 32'h0;
end

always @(posedge clk) begin
    if(en == 1'b1) begin
        data1 <= registers[rs1];
        data2 <= registers[rs2];
        if(writeEn == 1'b1 && rd != 5'h0) begin
            registers[rd] <= dataDest;
        end
    end
end

endmodule