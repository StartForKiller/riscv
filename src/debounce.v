module debounce(input pb_1,clk,output pb_out);
wire slow_clk_en;
wire Q1,Q2,Q2_bar,Q0;
clock_div u1(clk,slow_clk_en);
my_dff d0(clk,slow_clk_en,pb_1,Q0);

my_dff d1(clk,slow_clk_en,Q0,Q1);
my_dff d2(clk,slow_clk_en,Q1,Q2);
assign Q2_bar = ~Q2;
assign pb_out = Q1 & Q2_bar;
endmodule