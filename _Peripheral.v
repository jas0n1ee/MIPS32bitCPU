//定时器外设
module _Timer(R, C, Addr, Read, Write, WData, THData, TLData, ConData);
	input R, C, Read, Write;
	input [31:0] Addr, WData;
	output [31:0] THData, TLData, ConData;
	
	reg [31:0] THData, TLData, ConData;
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			TLData<=32'b0;
			THData<=32'b0;
			ConData<=32'b0;
			end
		else
			begin
			if(Write)
				begin
				if(Addr==32'h4000_0000)
					begin
					THData<=WData;
					end
				else if(Addr==32'h4000_0004)
					begin
					TLData<=WData;
					end
				else if(Addr==32'h4000_0008)
					begin
					ConData[1:0]<=WData[1:0];
					end
				end
			if(Read)
				begin
				if(Addr==32'h4000_0008)
					begin
					ConData[2]<=1'b0;
					end
				end
			if(ConData[0])
				begin
				if(TLData==32'hffff_ffff)
					begin
					TLData<=THData;
//					if(ConData[1])
						begin
						ConData[2]<=1'b1;
						end
					end
				else
					begin
					TLData<=TLData+32'b1;
					end
				end
			end
		end
	
endmodule

//8位Led外设
module _Led(R, C, Addr, Write, WData, LedData, Led);
	input R, C, Write;
	input [31:0] Addr, WData;
	output [7:0] Led;
	output [31:0] LedData;
	
	reg [31:0] LedData;
	
	assign Led=LedData[7:0];
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			LedData<=32'b0;
			end
		else
			begin
			if(Write)
				begin
				if(Addr==32'h4000_000C)
					begin
					LedData<=WData;
					end
				end
			end
		end
		
endmodule

//8位拨动开关外设
module _Switch(R, C, Addr, Write, WData, SwitchData, Switch);
	input R, C, Write;
	input [31:0] Addr, WData;
	input [7:0] Switch;
	output [31:0] SwitchData;
	
	wire [31:0] SwitchData;
	
	assign SwitchData={24'b0, Switch};
		
endmodule

//4位8段数码管外设
module _Hex(R, C, Addr, Write, WData, HexData, Hex);
	input R, C, Write;
	input [31:0] Addr, WData;
	output [31:0] Hex;
	output [31:0] HexData;
	
	reg [31:0] HexData;

	assign Hex[7:0]=HexData[8]?HexData[7:0]:8'd255;
	assign Hex[15:8]=HexData[9]?HexData[7:0]:8'd255;
	assign Hex[23:16]=HexData[10]?HexData[7:0]:8'd255;
	assign Hex[31:24]=HexData[11]?HexData[7:0]:8'd255;
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			HexData<=32'b0;
			end
		else
			begin
			if(Write)
				begin
				if(Addr==32'h4000_0014)
					begin
					HexData<=WData;
					end
				end
			end
		end
		
endmodule

//串口外设
module _UART(R, C, Addr, Read, Write, WData, TxData, RxData, ConData, Tx, Rx);
	input R, C, Read, Write;
	input [31:0] Addr, WData;
	input Rx;
	output Tx;
	output [31:0] TxData, RxData, ConData;
	
	reg [31:0] TxData, ConData;
	wire [31:0] RxData;
	wire RxStatus, TxStatus;
	reg TxEn;
	
	assign RxData[31:8]=24'b0;
	
	_UARTR UartRx(C, Rx, RxStatus, RxData[7:0], R);
	_UARTT UartTx(C, Tx, TxEn, TxStatus, TxData[7:0], R);
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			TxData<=32'b0;
			ConData<=32'b0;
			end
		else
			begin
			if(Write)
				begin
				if(Addr==32'h4000_0018)
					begin
					TxData<={24'b0, WData[7:0]};
					TxEn<=1'b1;
					end
				else if(Addr==32'h4000_0020)
					begin
					ConData<={28'b0, WData[3:0]};
					end
				end
			if(Read)
				begin
				if(Addr==32'h4000_0020)
					begin
					ConData[3:2]<=2'b0;
					end
				end
			if(RxStatus)
				begin
//				if(ConData[1])
					begin
					ConData[3]<=1'b1;
					end
				end
			if(TxStatus && TxEn)
				begin
				TxEn<=1'b0;
//				if(ConData[0])
					begin
					ConData[2]<=1'b1;
					end
				end
			end
		end

endmodule

//9600波特率串口接收器
module _UARTR(C, RX, Status, Data, Reset);
	input C, RX, Reset;
	output Status;
	output [7:0] Data;
	
	reg Ring, Status;
	reg [7:0] Data;
	reg [12:0] Count;
	reg [7:0] DataRecv;
	reg [3:0] BitRecv;
	
	always @(posedge C, negedge Reset)
		begin
		if(!Reset)
			begin
			Ring<=1'b0;
			end
		else
		begin
		if(!Ring)
			begin
			if(!RX)
				begin
				Count<=13'd7811;
				Ring<=1;
				BitRecv<=4'd0;
				DataRecv<=8'd0;
				Status<=1'b0;
				end
			else
				begin
				Count<=13'd0;
				Ring<=0;
				BitRecv<=4'd0;
				DataRecv<=8'd0;
				Status<=1'b0;
				end
			end
		else
			begin
			if(Count==13'd0)
				begin
				if(BitRecv==4'd8)
					begin
					Count<=13'd0;
					Ring<=1'b0;
					BitRecv<=4'd0;
					DataRecv<=DataRecv;
					Data<=DataRecv;
					Status<=1'b1;
					end
				else
					begin
					Count<=13'd5207;
					Ring<=1'b1;
					DataRecv[BitRecv]<=RX;
					BitRecv<=BitRecv+4'd1;
					end
				end
			else
				begin
				Count<=Count-13'd1;
				Ring<=1'b1;
				BitRecv<=BitRecv;
				DataRecv<=DataRecv;
				end
			end
		end
		end

endmodule

//9600波特率串口发送器
module _UARTT(C, TX, En, Status, Data, Reset);
	input C, En, Reset;
	input [7:0] Data;
	output Status, TX;
	
	reg Status, TX, TransStart;
	reg [8:0] DataTrans;
	reg [12:0] Count;
	reg [3:0] BitTrans;
	
	always @(posedge C, negedge Reset)
		begin
		if(~Reset)
			begin
			Status<=1'b1;
			TX<=1'b1;
			end
		else
			begin
			if(Status)
				begin
				if(En)
					begin
					DataTrans<={1'b1, Data};
					Count<=13'd5208;
					BitTrans<=4'd0;
					Status<=1'b0;
					TX<=1'b0;
					end
				end
			else
				begin
				if(Count==13'd0)
					begin
					if(BitTrans==4'd9)
						begin
						Status<=1'b1;
						end
					else
						begin
						TX<=DataTrans[BitTrans];
						Count<=13'd5208;
						BitTrans<=BitTrans+4'd1;
						end
					end
				else
					begin
					Count<=Count-13'd1;
					end
				end
			end	
		end
	
endmodule