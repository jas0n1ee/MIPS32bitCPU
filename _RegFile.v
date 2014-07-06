module _RegFile(C, AAddr, AData, BAddr, BData, Write, WAddr, WData);
	input C, Write;
	input [4:0] AAddr, BAddr, WAddr;
	output [31:0] AData, BData;
	input [31:0] WData;

	reg [31:0] RFData[31:0];

	assign AData=AAddr?RFData[AAddr]:32'b0;
	assign BData=BAddr?RFData[BAddr]:32'b0;

	always @(posedge C)
		begin
		if(Write)	
			begin
			RFData[WAddr]<=WData;
			end
		end
		
endmodule
