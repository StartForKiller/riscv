/* verilator lint_off UNUSED */
module csrfile(
    input wire clk,
    input wire en,
    input wire writeEn,
    input wire csrReadEn,
    input wire [11:0] rsd,
    output reg [31:0] data,
    input wire [31:0] dataDest
);

//Implement all registers
always @(posedge clk) begin
    if(en == 1'b1) begin
        if(csrReadEn == 1'b1) begin
            case(rsd)
                default: begin
                    data <= 32'h0;
                end
            endcase
        end
        if(writeEn == 1'b1) begin
            case(rsd)
                default: begin
                    //data <= 32'h0;
                end
            endcase
        end
    end
end

endmodule