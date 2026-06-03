module  ultrasonic_signal_carrier(iRST,iCLK_50Mhz,
oCLK_40khz,oCLK_100hz,
o_ultrasonic_signal_carrier_TP,
o_ultrasonic_signal_carrier_TN);

input  iCLK_50Mhz,iRST; //50Mhz
output  oCLK_40khz,oCLK_100hz;

output o_ultrasonic_signal_carrier_TP;
output o_ultrasonic_signal_carrier_TN;

wire oCLK_40khz,oCLK_100hz;
wire CLK_40khz,CLK_100hz;

reg [31:0] DIV_100hz;
reg [31:0] DIV_40khz;
reg [31:0] duty_ratio_100hz;

reg [4:0] rom_address;
wire [31:0] ROM_DATA;


always @(negedge iCLK_50Mhz or negedge iRST)
begin
if (!iRST)
     rom_address = 5'b0;
else
     if (rom_address > 30 )  rom_address =  rom_address ;
	  else rom_address = rom_address + 5'b1;
end

DIV_ROM DUT_DIV_100hz(
	.address(rom_address),
	.clock(iCLK_50Mhz),
	.q(ROM_DATA));	
	
//  DIV_40khz
always @(posedge iCLK_50Mhz or negedge iRST)
begin
if (!iRST)
   DIV_40khz = 32'd1220;
else
     if (rom_address == 32'd1 )  DIV_40khz = 50_000_000/ROM_DATA;
end

//  DIV_100hz
always @(posedge iCLK_50Mhz or negedge iRST)
begin
if (!iRST)
   DIV_100hz = 32'd500_000;
else
     if (rom_address == 32'd2 )  DIV_100hz = 50_000_000/ROM_DATA;
end

//  duty_ratio_100hz
always @(posedge iCLK_50Mhz or negedge iRST)
begin
if (!iRST)
   duty_ratio_100hz = 32'd20;
else
     if (rom_address == 32'd3 )  duty_ratio_100hz = ROM_DATA;
end

clk_div_duty   clk_div_40khz  (.iCLK(iCLK_50Mhz),.oCLK(CLK_40khz),.div(DIV_40khz),.duty_ratio(32'd50));
clk_div_duty   clk_div_100hz  (.iCLK(iCLK_50Mhz),.oCLK(CLK_100hz),.div(DIV_100hz),.duty_ratio(duty_ratio_100hz));

assign  oCLK_40khz = CLK_40khz;
assign  oCLK_100hz = CLK_100hz;
assign o_ultrasonic_signal_carrier_TP =  CLK_40khz  &  CLK_100hz ;
assign o_ultrasonic_signal_carrier_TN =  ~ o_ultrasonic_signal_carrier_TP ;

endmodule
