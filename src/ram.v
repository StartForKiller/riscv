module ram
#(
    parameter RAM_SIZE = 32768
)
(
    input wire clk,
    input wire enable,
    input wire [31:0] addr,
    input wire [31:0] inData,
    output reg [31:0] outData,
    input wire write
);

reg [31:0] mem [0:(RAM_SIZE / 4)-1];

initial begin
    $readmemh("/home/jesus/proyectos/riscvcpu/test/testprogram/test.hex", mem);
end

always @(posedge clk) begin
    case({enable, write})
        2'b10: begin //Load
            outData <= mem[addr[14:2]];
        end
        2'b11: begin
            mem[addr[14:2]] <= inData;
        end
        default: begin
            
        end
    endcase
end

endmodule