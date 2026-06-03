//`include "para.v"
//`define WIDE 16
`timescale 1ns / 1ps
module div_even_duty (iCLK,oCLK,div,duty_ratio);
input iCLK;
parameter WIDE = 32;
input [WIDE-1:0] div;
input [WIDE-1:0] duty_ratio;
output oCLK;
reg outCLK;
initial outCLK = 1'b0;
reg [WIDE-1:0 ]cnt ;
wire [WIDE-1:0] duty_cnt;
assign duty_cnt = (duty_ratio*div )/100;
always @(posedge iCLK)
 begin
 if (cnt<duty_cnt) 
 outCLK <= 1'b1;
 else
 outCLK <= 1'b0;
 end
initial cnt = 0;
 always @ (posedge iCLK)
 begin 
 if (cnt < (div[WIDE-1:0]-1)  ) cnt <= cnt +32'b1;
 else   cnt <= 32'b0;  
 end 
 assign oCLK = (div != 32'd1 ) ?  outCLK :iCLK ; 
 endmodule
 
