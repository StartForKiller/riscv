module clock_div2(input Clk_100M, output slow_clk_en

    );
    reg [8:0]counter=0;
    always @(posedge Clk_100M)
    begin
       counter <= (counter>=100)?0:counter+1;
    end
    assign slow_clk_en = (counter >= 49)?1'b1:1'b0;
endmodule