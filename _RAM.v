//主存、外设接口，统一编址
module _RAM(R, C, Addr, Read, RData, Write, WData, TCOvf, Led, 
			Switch, Hex, Rx, Tx, RxRdy, TxRdy);
	input R, C, Read, Write;
	input [31:0] Addr, WData;
	output [31:0] RData;
	
	wire [31:0] RamRData, IORData;
	
	//外设接口
	output TCOvf;
	output [7:0] Led;
	input [7:0] Switch;
	output [31:0] Hex;
	input Rx;
	output Tx, RxRdy, TxRdy;

	assign RData=Read?((Addr[31:30]==2'b00)?RamRData:IORData):32'b0;
	
	//外设部分
	wire [31:0] TimerTHData, TimerTLData, TimerTConData;
	wire [31:0] LedData;
	wire [31:0] SwitchData;
	wire [31:0] HexData;
	wire [31:0] UartTxData, UartRxData, UartConData;
	
	_Timer Timer1(R, C, Addr, Read, Write, WData, TimerTHData, TimerTLData, TimerTConData);
	_Led Led1(R, C, Addr, Write, WData, LedData, Led);
	_Switch Switch1(R, C, Addr, Write, WData, SwitchData, Switch);
	_Hex Hex1(R, C, Addr, Write, WData, HexData, Hex);
	_UART Uart1(R, C, Addr, Read, Write, WData, UartTxData, UartRxData, UartConData, Tx, Rx);
	
	assign IORData=(Addr==32'h4000_0000)?TimerTHData:
				   (Addr==32'h4000_0004)?TimerTLData:
				   (Addr==32'h4000_0008)?TimerTConData:
				   (Addr==32'h4000_000c)?LedData:
				   (Addr==32'h4000_0010)?SwitchData:
				   (Addr==32'h4000_0014)?HexData:
				   (Addr==32'h4000_0018)?UartTxData:
				   (Addr==32'h4000_001c)?UartRxData:
				   (Addr==32'h4000_0020)?UartConData:
				   32'b0;
	assign TCOvf=TimerTConData[1]&TimerTConData[2];
	assign RxRdy=UartConData[1]&UartConData[3];
	assign TxRdy=UartConData[0]&UartConData[2];
	
	//RAM部分
	reg [31:0] RAMDATA[31:0];
	
	assign RamRData=(Addr[31:7]==25'b0 && Addr[1:0]==2'b0)?RAMDATA[Addr[6:2]]:32'b0;
	
	always @(posedge C) 
		begin
		if(Write)
			begin
			if(Addr[31:7]==25'b0 && Addr[1:0]==2'b0)
				begin
				RAMDATA[Addr[6:2]]<=WData;
				end
			end 
		end

endmodule
