module top(
    input wire clk,
    input wire realInClk,
    input wire reset,

    output wire [7:0] ledsState,
    output wire [7:0] sevenSeg,
    output wire [3:0] sevenSegEn//,

    //output wire [31:0] currentPC,
    //output wire [3:0] outStateFinal
);

wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;
wire [6:0] opcode;
wire [31:0] imm;
wire [31:0] data1;
wire [31:0] data2;
wire [31:0] dataCsr;
wire [31:0] dataDest;
wire [31:0] dataCsrDest;
wire [31:0] dataDestValue;
wire [14:0] func;
wire rwEn;
wire [31:0] pcAddr;
wire pcWrEn;
wire rwAluEn;
wire [3:0] outState;
wire [4:0] memOp;
wire csrEn;
wire csrReadEn;

wire [31:0] outputPC;

wire enable_decode;
wire enable_alu;
wire enable_memory;
wire enable_registers;

wire regfileEn;
wire regfileWrEn;
wire rwAluEnCsr;
wire csrfileWrEn;


wire memReady;
wire dataReady;
wire memExecute;
wire memWrite;
wire [1:0] memSize;
wire memSign;
wire [31:0] memAddress;
wire [31:0] inputData;
wire [31:0] outputData;

wire realOutClk;

/*debounce Deb(
    .pb_1(realInClk),
    .clk(clk),
    .pb_out(realOutClk)
);*/

wire realReset;
debounce Deb2(
    .pb_1(reset),
    .clk(clk),
    .pb_out(realReset)
);

/*clock_div2 clkDiv(
    .Clk_100M(clk),
    .slow_clk_en(realOutClk)
);*/
assign realOutClk = clk;

controlUnit cUnit(
    .clk(realOutClk),
    .reset(realReset),
    .opcode(opcode),
    .pcAddr(pcAddr),
    .pcWrEn(pcWrEn),
    .memReady(memReady),
    .dataReady(dataReady),
    .memExecute(memExecute),
    .outState(outState),
    .outputPC(outputPC)
);

decoder cpuDecoder(
    .clk(realOutClk),
    .reset(realReset),
    .en(enable_decode),
    .data(inputData),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .rwEn(rwEn),
    .func(func),
    .imm(imm),
    .memop(memOp),
    .opcode(opcode),
    .csrEn(csrEn),
    .csrReadEn(csrReadEn)
);

regfile registers(
    .clk(realOutClk),
    .en(regfileEn),
    .writeEn(regfileWrEn),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .data1(data1),
    .data2(data2),
    .dataDest(dataDestValue)
);

alu ALU(
    .clk(realOutClk),
    .reset(realReset),
    .en(enable_alu),
    .rwEn(rwEn),
    .imm(imm),
    .data1(data1),
    .data2(data2),
    .dataCsr(dataCsr),
    .dataDest(dataDest),
    .dataCsrDest(dataCsrDest),
    .opcode(opcode),
    .func(func),
    .currentPC(outputPC),
    .PCdest(pcAddr),
    .pcRwEn(pcWrEn),
    .rwAluEn(rwAluEn),
    .rwAluEnCsr(rwAluEnCsr),
    .rs1(rs1)
);

csrfile CsrFile(
    .clk(realOutClk),
    .en(regfileEn),
    .csrReadEn(csrReadEn),
    .writeEn(csrfileWrEn),
    .rsd(func[14:3]),
    .data(dataCsr),
    .dataDest(dataCsrDest)
);

memory Memory(
    .clk(realOutClk),
    .reset(realReset),
    .memReady(memReady),
    .dataReady(dataReady),
    .memExecute(memExecute),
    .memWrite(memWrite),
    .memSize(memSize),
    .memSign(memSign),
    .memAddress(memAddress),
    .outputData(inputData),
    .inputData(outputData),
    .ledState(ledsState[0]),
    .sevenSeg(sevenSeg),
    .sevenSegEn(sevenSegEn)
);

assign enable_decode = outState == 4'b0001;
assign enable_alu = outState == 4'b0010;
assign enable_memory = outState == 4'b0011 || outState > 4'b0101;
assign enable_registers = outState == 4'b0100;

assign regfileEn = enable_decode == 1'b1 || enable_registers == 1'b1;
assign regfileWrEn = rwAluEn == 1'b1 && enable_registers == 1'b1;
assign csrfileWrEn = csrEn == 1'b1 && rwAluEnCsr == 1'b1 && enable_registers == 1'b1;

assign memAddress = (enable_memory == 1'b1) ? dataDest : outputPC;
assign memWrite = (enable_memory == 1'b1 && memOp[4:3] == 2'b10) ? 1'b1 : 1'b0;
assign memSize = (outState == 4'b0000) ? 2'b10 : memOp[1:0];
assign memSign = memOp[2:2] == 1'b0;
assign outputData = data2;

assign dataDestValue = (memOp[4:3] == 2'b01) ? inputData : dataDest;

assign ledsState[7:1] = outputPC[7:1];

//Debug
//assign currentPC = outputPC;
//assign outStateFinal = outState;

endmodule