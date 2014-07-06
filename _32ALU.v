//32bit算术逻辑单元
module _32ALU(A, B, Func, Sign, Result, Ovf);
	input [31:0] A, B;
	input [5:0] Func;
	input Sign;
	output [31:0] Result;
	output Ovf;
	
	wire Zero, AdderOvf, Neg, Cin;
	wire [31:0] AB, AResult, LResult, SResult, CResult;
	
	_32AdderA Adder1(A, AB, Cin, Sign, AResult, Zero, AdderOvf, Neg);
	_32Logic Logic1(A, B, Func[3:0], LResult);
	_32Shift Shift1(A[4:0], B, Func[1:0], SResult);
	_CMP CMP1(Zero, Ovf, Neg, Func[3:1], CResult);
	
	assign Result=(Func[5:4]==2'b00)?AResult:
				  (Func[5:4]==2'b01)?LResult:
				  (Func[5:4]==2'b10)?SResult:
				  CResult; 
	assign Cin=Func[0]?1'b1:1'b0;
	assign AB=(Func[0])?((Func[3])?(~32'b0):(~B)):B;
	assign Ovf=(Func[5:4]==2'b00)?AdderOvf:1'b0;
	
endmodule

//8bit超前进位加法器, 包含组产生和组传播信号, 输出后两位进位输出
module _8AdderA(A, B, Cin, Result, GroupP, GroupG, Co, Col);
	input [7:0] A, B;
	input Cin;
	output [7:0] Result;
	output Co, Col, GroupP, GroupG;
	
	wire [7:0] G, P, C;
	
	assign Col=C[7];
	assign G=A&B;
	assign P=A^B;
	assign C[0]=Cin;
	assign C[1]=G[0]|(P[0]&Cin);
	assign C[2]=G[1]|(P[1]&G[0])|(P[1]&P[0]&Cin);
	assign C[3]=G[2]|(P[2]&G[1])|(P[2]&P[1]&G[0])|
				(P[2]&P[1]&P[0]&Cin);
	assign C[4]=G[3]|(P[3]&G[2])|(P[3]&P[2]&G[1])|
				(P[3]&P[2]&P[1]&G[0])|(P[3]&P[2]&P[1]&P[0]&Cin);
	assign C[5]=G[4]|(P[4]&G[3])|(P[4]&P[3]&G[2])|
				(P[4]&P[3]&P[2]&G[1])|(P[4]&P[3]&P[2]&P[1]&G[0])|
				(P[4]&P[3]&P[2]&P[1]&P[0]&Cin);
	assign C[6]=G[5]|(P[5]&G[4])|(P[5]&P[4]&G[3])|
				(P[5]&P[4]&P[3]&G[2])|(P[5]&P[4]&P[3]&P[2]&G[1])|
				(P[5]&P[4]&P[3]&P[2]&P[1]&G[0])|
				(P[5]&P[4]&P[3]&P[2]&P[1]&P[0]&Cin);
	assign C[7]=G[6]|(P[6]&G[5])|(P[6]&P[5]&G[4])|
				(P[6]&P[5]&P[4]&G[3])|(P[6]&P[5]&P[4]&P[3]&G[2])|
				(P[6]&P[5]&P[4]&P[3]&P[2]&G[1])|
				(P[6]&P[5]&P[4]&P[3]&P[2]&P[1]&G[0])|
				(P[6]&P[5]&P[4]&P[3]&P[2]&P[1]&P[0]&Cin);
	assign   Co=G[7]|(P[7]&G[6])|(P[7]&P[6]&G[5])|
				(P[7]&P[6]&P[5]&G[4])|(P[7]&P[6]&P[5]&P[4]&G[3])|
				(P[7]&P[6]&P[5]&P[4]&P[3]&G[2])|
				(P[7]&P[6]&P[5]&P[4]&P[3]&P[2]&G[1])|
				(P[7]&P[6]&P[5]&P[4]&P[3]&P[2]&P[1]&G[0])|
				(P[7]&P[6]&P[5]&P[4]&P[3]&P[2]&P[1]&P[0]&Cin);
	assign Result=P^C;
	assign GroupP=P[7]&P[6]&P[5]&P[4]&P[3]&P[2]&P[1]&P[0];
	assign GroupG=G[7]|(P[7]&G[6])|(P[7]&P[6]&G[5])|
				(P[7]&P[6]&P[5]&G[4])|(P[7]&P[6]&P[5]&P[4]&G[3])|
				(P[7]&P[6]&P[5]&P[4]&P[3]&G[2])|
				(P[7]&P[6]&P[5]&P[4]&P[3]&P[2]&G[1])|
				(P[7]&P[6]&P[5]&P[4]&P[3]&P[2]&P[1]&G[0]);

endmodule

//32bit加法器, 包括Zero, Overflow, Negetive信号产生
module _32AdderA(A, B, Cin, Sign, Result, Zero, Ovf, Neg);
	input [31:0] A, B;
	input Cin, Sign;
	output [31:0] Result;
	output Zero, Ovf, Neg;
	
	wire [4:0] Ct;
	wire [3:0] GroupP, GroupG;
	
	assign Ct[0]=GroupG[0]|(GroupP[0]&Cin);
	assign Ct[1]=GroupG[1]|(GroupP[1]&GroupG[0])|
				 (GroupP[1]&GroupP[0]&Cin);
	assign Ct[2]=GroupG[2]|(GroupP[2]&GroupG[1])|
				 (GroupP[2]&GroupP[1]&GroupG[0])|
				 (GroupP[2]&GroupP[1]&GroupP[0]&Cin);
	
	_8AdderA Adder1(A[7:0], B[7:0], Cin, Result[7:0], GroupP[0], GroupG[0]);
	_8AdderA Adder2(A[15:8], B[15:8], Ct[0], Result[15:8], GroupP[1], GroupG[1]);
	_8AdderA Adder3(A[23:16], B[23:16], Ct[1], Result[23:16], GroupP[2], GroupG[2]);
	_8AdderA Adder4(A[31:24], B[31:24], Ct[2], Result[31:24], GroupP[3], GroupG[3], Ct[4], Ct[3]);
	
	assign Zero=(Result==32'b0)?1'b1:1'b0;
	assign Ovf=Sign?(Ct[3]^Ct[4]):Ct[4];
	assign Neg=Sign?Result[31]:(~Ct[4]);
	
endmodule 

//32bit逻辑运算单元
module _32Logic(A, B, Func, Result);
	input [31:0] A, B;
	input [3:0] Func;
	output [31:0] Result;
	
	assign Result=(Func==4'b1000)?(A&B):
				  (Func==4'b1110)?(A|B):
				  (Func==4'b0110)?(A^B):
				  (Func==4'b0001)?(~(A|B)):
				  A;
	
endmodule

//32bit移位运算单元
module _32Shift(A, B, Func, Result);
	input [31:0] B;
	input [4:0] A;
	input [1:0] Func;
	output [31:0] Result;
	
	wire [31:0] LShift, RShift, ARShift;
	
	_32LShift Shift1(B, A, LShift);
	_32RShift Shift2(B, A, RShift);
	_32ARShift Shift3(B, A, ARShift);
	
	assign Result=(Func==2'b00)?LShift:
				  (Func==2'b01)?RShift:
				  ARShift;	
				  
endmodule

//比较单元
module _CMP(Zero, Ovf, Neg, Func, Result);
	input Zero, Ovf, Neg;
	input [2:0] Func;
	output [31:0] Result;
	
	assign Result[31:1]=31'b0;
	assign Result[0]=(Func[2])?(
					 (Func[1])?(
					 (Func[0])?((~Neg)&(~Zero)):(Neg|Zero)):(
					 (Func[0])?1'b0:(~Neg))):(
					 (Func[1])?(
					 (Func[0])?1'b0:Neg):(
					 (Func[0])?Zero:(~Zero))); 
					 
endmodule

//1位逻辑左移位单元
module _32LShift1(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={A[30:0], 1'b0};
	
endmodule

//2位逻辑左移位单元
module _32LShift2(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={A[29:0], 2'b0};
	
endmodule
//4位逻辑左移位单元
module _32LShift4(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={A[27:0], 4'b0};
	
endmodule
//8位逻辑左移位单元
module _32LShift8(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={A[23:0], 8'b0};
	
endmodule

//16位逻辑左移位单元
module _32LShift16(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={A[15:0], 16'b0};
	
endmodule

//1位逻辑右移位单元
module _32RShift1(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={1'b0, A[31:1]};
	
endmodule

//2位逻辑右移位单元
module _32RShift2(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={2'b0, A[31:2]};
	
endmodule

//4位逻辑右移位单元
module _32RShift4(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={4'b0, A[31:4]};
	
endmodule

//8位逻辑右移位单元
module _32RShift8(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={8'b0, A[31:8]};
	
endmodule

//16位逻辑右移位单元
module _32RShift16(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	assign Result={16'b0, A[31:16]};
	
endmodule

//1位算术右移位单元
module _32ARShift1(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	wire [1:0] Temp;
	
	assign Temp=A[31]?2'b11:2'b0;	
	assign Result={Temp, A[30:1]};
	
endmodule

//2位算术右移位单元
module _32ARShift2(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	wire [2:0] Temp;
	
	assign Temp=A[31]?3'b111:3'b0;	
	assign Result={Temp, A[30:2]};
	
endmodule

//4位算术右移位单元
module _32ARShift4(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	wire [4:0] Temp;
	
	assign Temp=A[31]?5'b1_1111:5'b0;	
	assign Result={Temp, A[30:4]};
	
endmodule

//8位算术右移位单元
module _32ARShift8(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	wire [8:0] Temp;
	
	assign Temp=A[31]?9'b1_1111_1111:9'b0;	
	assign Result={Temp, A[30:8]};
	
endmodule

//16位算术右移位单元
module _32ARShift16(A, Result);
	input [31:0] A;
	output [31:0] Result;
	
	wire [16:0] Temp;
	
	assign Temp=A[31]?17'b1_1111_1111_1111_1111:17'b0;	
	assign Result={Temp, A[30:16]};
	
endmodule

//32位逻辑左移单元
module _32LShift(A, Shift, Result);
	input [31:0] A;
	input [4:0] Shift;
	output [31:0] Result;
	
	wire [31:0] RTemp[0:5];
	wire [31:0] ATemp[0:4];
	
	_32LShift1 Shift1(A, RTemp[0]);
	_32LShift2 Shift2(ATemp[0], RTemp[1]);
	_32LShift4 Shift3(ATemp[1], RTemp[2]);
	_32LShift8 Shift4(ATemp[2], RTemp[3]);
	_32LShift16 Shift5(ATemp[3], RTemp[4]);
	
	assign ATemp[0]=Shift[0]?RTemp[0]:A;
	assign ATemp[1]=Shift[1]?RTemp[1]:ATemp[0];
	assign ATemp[2]=Shift[2]?RTemp[2]:ATemp[1];
	assign ATemp[3]=Shift[3]?RTemp[3]:ATemp[2];
	assign Result=Shift[4]?RTemp[4]:ATemp[3];
	
endmodule

//32位逻辑右移单元
module _32RShift(A, Shift, Result);
	input [31:0] A;
	input [4:0] Shift;
	output [31:0] Result;
	
	wire [31:0] RTemp[0:5];
	wire [31:0] ATemp[0:4];
	
	_32RShift1 Shift1(A, RTemp[0]);
	_32RShift2 Shift2(ATemp[0], RTemp[1]);
	_32RShift4 Shift3(ATemp[1], RTemp[2]);
	_32RShift8 Shift4(ATemp[2], RTemp[3]);
	_32RShift16 Shift5(ATemp[3], RTemp[4]);
	
	assign ATemp[0]=Shift[0]?RTemp[0]:A;
	assign ATemp[1]=Shift[1]?RTemp[1]:ATemp[0];
	assign ATemp[2]=Shift[2]?RTemp[2]:ATemp[1];
	assign ATemp[3]=Shift[3]?RTemp[3]:ATemp[2];
	assign Result=Shift[4]?RTemp[4]:ATemp[3];
	
endmodule

//32位算术右移单元
module _32ARShift(A, Shift, Result);
	input [31:0] A;
	input [4:0] Shift;
	output [31:0] Result;
	
	wire [31:0] RTemp[0:5];
	wire [31:0] ATemp[0:4];
	
	_32ARShift1 Shift1(A, RTemp[0]);
	_32ARShift2 Shift2(ATemp[0], RTemp[1]);
	_32ARShift4 Shift3(ATemp[1], RTemp[2]);
	_32ARShift8 Shift4(ATemp[2], RTemp[3]);
	_32ARShift16 Shift5(ATemp[3], RTemp[4]);
	
	assign ATemp[0]=Shift[0]?RTemp[0]:A;
	assign ATemp[1]=Shift[1]?RTemp[1]:ATemp[0];
	assign ATemp[2]=Shift[2]?RTemp[2]:ATemp[1];
	assign ATemp[3]=Shift[3]?RTemp[3]:ATemp[2];
	assign Result=Shift[4]?RTemp[4]:ATemp[3];
	
endmodule