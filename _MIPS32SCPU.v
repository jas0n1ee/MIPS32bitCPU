module _MIPS32SCPU(Rst, Clk, Led, Switch, Hex, Rx, Tx, PC, IRQ);
//Pipeline version
	input Rst, Clk;
	
	output [31:0] PC;
	output IRQ;
	
	output [7:0] Led;
	input [7:0] Switch;
	output [31:0] Hex;
	input Rx;
	output Tx;

	wire [31:0] ALUA, ALUB, RegA, RegB, RegC, ALUOut, RAMOut;
	wire [31:0] EXTOut, EXTOutLS2, ConBA, ConBAOut;
	wire [31:0] PCP4, PCP4T, NextPC, Instruct, Exec;
	wire [25:0] JT;
	wire [15:0] Imm16, EXT16;
	wire [5:0] ALUFunc;
	wire [4:0] Rd, Rt, Rs, Shamt, RegDstOut, Ra, Xp;
	wire [2:0] ALUSrc1;
	wire [1:0] PCSrc, RegDst, MemToReg;
	wire RegWr, ALUSrc2, EXTOp, Sign, MemRd, MemWr;
	wire ErrInst, Ovf, TCOvf, RxRdy, TxRdy, OvfEn, IRQ;
	
	reg [31:0] EPC, Cause, PC;
	
	//异常和中断部分
	assign IRQ=(Ovf&OvfEn)|ErrInst|TCOvf|RxRdy|TxRdy;
	assign Exec=32'h8000_0008;
	
	always @(posedge Clk, negedge Rst)
	begin
	if(~Rst)
		begin
		EPC<=32'h8000_0000;
		Cause<=32'h0000_0000;
		end
	else
		begin
		EPC<=PC;
		Cause<={27'b0, TxRdy, RxRdy, TCOvf, Ovf&OvfEn, ErrInst};
		end
	end
	
	//ALU、MEM相关
	assign ALUA=(ALUSrc1==3'd0)?RegA:
				(ALUSrc1==3'd1)?{27'b0, Shamt[4:0]}:
				(ALUSrc1==3'd2)?32'd16:
				(ALUSrc1==3'd3)?EPC:
				Cause;
	assign ALUB=ALUSrc2?EXTOut:RegB;
	assign EXT16=Imm16[15]?16'b1111_1111_1111_1111:16'b0;
	assign EXTOut=EXTOp?{EXT16, Imm16}:{16'b0, Imm16};
	assign RegDstOut=(RegDst==2'd0)?Rd:
					 (RegDst==2'd1)?Rt:
					 5'd31;
	assign RegC=(MemToReg==2'd0)?ALUOut:
				(MemToReg==2'd1)?RAMOut:
				PCP4;
	
	_32LShift2 Shift1(EXTOut, EXTOutLS2);
	_32AdderA Adder1(PCP4, EXTOutLS2, 1'b0, 1'b0, ConBA);
	_32ALU ALU1(ALUA, ALUB, ALUFunc, Sign, ALUOut, Ovf);
	_RegFile RegFile1(Clk, Rs, RegA, Rt, RegB, RegWr&(~IRQ), RegDstOut, RegC);
	_RAM RAM1(Rst, Clk, ALUOut, MemRd, RAMOut, MemWr&(~IRQ), RegB, TCOvf, Led, 
			  Switch, Hex, Rx, Tx, RxRdy, TxRdy);
	
	//PC相关
	assign NextPC=(PCSrc==2'd0)?PCP4:
				  (PCSrc==2'd1)?ConBAOut:
				  (PCSrc==2'd2)?{4'b0, JT, 2'b0}:
				  RegA;
	assign ConBAOut=ALUOut[0]?ConBA:PCP4;
	assign PCP4={PC[31], PCP4T[30:0]};

	_32AdderA Adder2(PC, 32'd4, 1'b0, 1'b0, PCP4T);
	_ROM ROM1(PC, Instruct);
	
	always @(posedge Clk, negedge Rst)
		begin
		if(~Rst)
			begin
			PC<=32'h8000_0000;
			end
		else
			begin
			PC<=IRQ?Exec:NextPC;
			end
		end
	
	//译码相关
	assign JT=Instruct[25:0];
	assign Imm16=Instruct[15:0];
	assign Shamt=Instruct[10:6];
	assign Rd=Instruct[15:11];
	assign Rt=Instruct[20:16];
	assign Rs=Instruct[25:21];
	
	_Control Control1(Instruct[31:26], Instruct[5:0], 
					  {ALUFunc, Sign, ALUSrc1, ALUSrc2, RegWr, EXTOp, 
					  PCSrc, RegDst, MemToReg, MemWr, MemRd, OvfEn}, ErrInst);
	
endmodule
	