module	Rst_Delay(iCLK,iKey,oRESET);
input		iCLK;
input		iKey;
output reg	oRESET;
reg	[19:0]	Cont;

always@(posedge iCLK or negedge  iKey)
begin
if (!iKey)
begin
  Cont=20'h0;
  oRESET	<=	1'b0;
  end
else
	begin
	
	if(Cont!=20'hFFFFF)
	begin
		Cont	<=	Cont+1;
		oRESET	<=	1'b0;
	end
	else
	oRESET	<=	1'b1;
	end
	
end

endmodule
