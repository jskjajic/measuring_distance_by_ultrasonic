//`timescale 1ns / 1ns
//`include "para.v"

module clk_div_duty(iCLK,oCLK,div,duty_ratio);
  input iCLK;
  output oCLK;
  parameter WIDE = 32;
  input [WIDE-1:0] div ;
  input [WIDE-1:0] duty_ratio;

  wire oCLK_odd,oCLK_even;

  assign oCLK = div[0] ? oCLK_odd :oCLK_even ;
  div_odd_duty DUT_odd  (.iCLK(iCLK),.oCLK(oCLK_odd),	.div(div),.duty_ratio(duty_ratio));		
  div_even_duty DUT_even (.iCLK(iCLK),.oCLK(oCLK_even),.div(div),.duty_ratio(duty_ratio));
		
endmodule
