module _MIPS32PCPU(R, C, Led, Switch, Hex, Rx, Tx);
	input R, C;
	
	output [7:0] Led;
	input [7:0] Switch;
	output [31:0] Hex;
	input Rx;
	output Tx;
	
	wire [31:0] Exec;
	wire [1:0] ForwardA, ForwardB, ForwardAJump;
	wire ErrInst, Ovf, TCOvf, RxRdy, TxRdy, IRQ, Stall, Branch, Jump;
	reg [31:0] Cause, EPC;
	
	//IF段变量
	wire [31:0] Instruct, PCP4, NextPC, ForwardRegAJump;
	reg [31:0] PC;
	//IF/ID寄存器变量
	reg [31:0] IFID_Instruct, IFID_PCP4, IFID_PC;
	reg IFID_Flushed;
	wire [25:0] IFID_JT;
	wire [15:0] IFID_Imm16;
	wire [5:0] IFID_OpCode, IFID_Funct;
	wire [4:0] IFID_Rd, IFID_Rt, IFID_Rs, IFID_Shamt;
	wire IFIDFLush;
	//ID段变量
	wire [31:0] RegA, RegB, EXTOut;
	wire [15:0] EXT16;
	wire [5:0] ALUFunc;
	wire [2:0] ALUSrc1;
	wire [1:0] PCSrc, RegDst, MemToReg;
	wire RegWr, ALUSrc2, EXTOp, Sign, MemWr, MemRd, OvfEn;
	//ID/EX寄存器变量
	reg [31:0] IDEX_PCP4, IDEX_RegA, IDEX_RegB, IDEX_EXTOut, IDEX_PC;
	reg [5:0] IDEX_ALUFunc;
	reg [4:0] IDEX_RegDstOut, IDEX_Rs, IDEX_Rt, IDEX_Shamt;
	reg [2:0] IDEX_ALUSrc1;
	reg [1:0] IDEX_PCSrc, IDEX_RegDst, IDEX_MemToReg;
	reg IDEX_RegWr, IDEX_ALUSrc2, IDEX_EXTOp, IDEX_Sign;
	reg IDEX_MemWr, IDEX_MemRd, IDEX_OvfEn, IDEX_Flushed;
	wire IDEXFlush;	
	//EX段变量
	wire [31:0] EXTOutLS2, ConBA, ALUA, ALUB, ALUOut, ForwardRegA, ForwardRegB;
	wire [4:0] RegDstOut;
	//EX/MEM寄存器变量
	reg [31:0] EXMEM_PCP4, EXMEM_ALUOut, EXMEM_RegB;
	reg [4:0] EXMEM_RegDstOut;
	reg [1:0] EXMEM_MemToReg;
	reg EXMEM_RegWr, EXMEM_MemRd, EXMEM_MemWr, EXMEM_Flushed;
	wire EXMEMFlush;
	//MEM段变量
	wire [31:0] RAMOut;
	//MEM/WB寄存器变量
	reg [31:0] MEMWB_PCP4, MEMWB_ALUOut, MEMWB_RAMOut;
	reg [4:0] MEMWB_RegDstOut;
	reg [1:0] MEMWB_MemToReg;
	reg MEMWB_RegWr;
	//WB段变量
	wire [31:0] RegC;
	
	//IF段------------------------------------------------------------------------
	assign ForwardRegAJump=(ForwardAJump==2'd0)?RegA:
						   (ForwardAJump==2'd1)?ALUOut:
					   	   (ForwardAJump==2'd2)?EXMEM_ALUOut:
					   	   RegC;
	assign NextPC=(Branch)?ConBA:
				  (Jump)?((PCSrc==2'd2)?{PC[31:28], IFID_JT, 2'b0}:ForwardRegAJump):
				  {PC[31], PCP4[30:0]};

	_32AdderA Adder2(PC, 32'd4, 1'b0, 1'b0, PCP4);
	_ROM ROM1(PC, Instruct);
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			PC<=32'h8000_0000;
			end
		else
			begin
			PC<=(Stall && (~Jump) && (~Branch))?PC:(IRQ?Exec:NextPC);
			end
		end
		
	//IF/ID寄存器-----------------------------------------------------------------
	assign IFIDFlush=(Jump || Branch || IRQ);
	
	assign IFID_JT=IFID_Instruct[25:0];
	assign IFID_Imm16=IFID_Instruct[15:0];
	assign IFID_OpCode=IFID_Instruct[31:26];
	assign IFID_Funct=IFID_Instruct[5:0];
	assign IFID_Shamt=IFID_Instruct[10:6];
	assign IFID_Rd=IFID_Instruct[15:11];
	assign IFID_Rt=IFID_Instruct[20:16];
	assign IFID_Rs=IFID_Instruct[25:21];
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			IFID_Instruct<=32'b0;
			end
		else
			begin
			IFID_PCP4<=Stall?IFID_PCP4:PCP4;
			IFID_PC<=Stall?IFID_PC:PC;
			IFID_Instruct<=IFIDFlush?32'b0:(Stall?IFID_Instruct:Instruct);
			IFID_Flushed<=IFIDFlush?1'd1:1'd0;
			end
		end
	
	//ID段------------------------------------------------------------------------
	assign EXT16=IFID_Imm16[15]?16'b1111_1111_1111_1111:16'b0;
	assign EXTOut=EXTOp?{EXT16, IFID_Imm16}:{16'b0, IFID_Imm16};
	assign RegDstOut=(RegDst==2'd0)?IFID_Rd:
					 (RegDst==2'd1)?IFID_Rt:
					 5'd31;
					 
	_Control Control1(IFID_OpCode, IFID_Instruct[5:0], 
					  {ALUFunc, Sign, ALUSrc1, ALUSrc2, RegWr, EXTOp, 
					  PCSrc, RegDst, MemToReg, MemWr, MemRd, OvfEn}, ErrInst);
	_RegFile RegFile1(~C, IFID_Rs, RegA, IFID_Rt, RegB, MEMWB_RegWr, MEMWB_RegDstOut, RegC);	
	
	//ID/EX寄存器-----------------------------------------------------------------
	assign IDEXFlush=(Stall || Branch || IRQ);
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			IDEX_ALUFunc<=6'b100000;
			IDEX_ALUSrc1<=3'd1;
			IDEX_ALUSrc2<=1'd0;
			IDEX_RegWr<=1'd1;
			IDEX_PCSrc<=2'd0;
			IDEX_RegDstOut<=5'd0;
			IDEX_Rs<=5'd0;
			IDEX_Rt<=5'd0;
			IDEX_MemToReg<=2'd0;
			IDEX_MemWr<=1'd0;
			IDEX_MemRd<=1'd0;
			IDEX_RegA<=32'd0;
			IDEX_RegB<=32'd0;
			IDEX_EXTOut<=32'd0;
			IDEX_Shamt<=5'd0;
			end
		else
			begin
			IDEX_PCP4<=IFID_PCP4;
			IDEX_RegA<=IDEXFlush?32'd0:RegA;
			IDEX_RegB<=IDEXFlush?32'd0:RegB;
			IDEX_EXTOut<=IDEXFlush?32'd0:EXTOut;
			IDEX_PC<=IFID_PC;
			IDEX_ALUFunc<=IDEXFlush?6'b100000:ALUFunc;
			IDEX_Shamt<=IDEXFlush?5'd0:IFID_Shamt;
			IDEX_ALUSrc1<=IDEXFlush?3'd1:ALUSrc1;
			IDEX_PCSrc<=IDEXFlush?2'd0:PCSrc;
			IDEX_RegDstOut<=IDEXFlush?5'd0:RegDstOut;
			IDEX_Rs<=IDEXFlush?5'd0:IFID_Rs;
			IDEX_Rt<=IDEXFlush?5'd0:IFID_Rt;
			IDEX_MemToReg<=IDEXFlush?2'd0:MemToReg;
			IDEX_RegWr<=IDEXFlush?1'd0:RegWr;
			IDEX_ALUSrc2<=IDEXFlush?1'd0:ALUSrc2;
			IDEX_Sign<=Sign;
			IDEX_MemWr<=IDEXFlush?1'd0:MemWr;
			IDEX_MemRd<=IDEXFlush?1'd0:MemRd;
			IDEX_OvfEn<=OvfEn;
			IDEX_Flushed<=IDEXFlush?1'd1:IFID_Flushed;
			end
		end	
	
	//EX段------------------------------------------------------------------------
	assign ForwardRegA=(ForwardA==2'd0)?IDEX_RegA:
					   (ForwardA==2'd1)?RegC:
					   EXMEM_ALUOut;
	assign ForwardRegB=(ForwardB==2'd0)?IDEX_RegB:
					   (ForwardB==2'd1)?RegC:
					   EXMEM_ALUOut;
	assign ALUA=(IDEX_ALUSrc1==3'd0)?ForwardRegA:
				(IDEX_ALUSrc1==3'd1)?{27'b0, IDEX_Shamt[4:0]}:
				(IDEX_ALUSrc1==3'd2)?32'd16:
				(IDEX_ALUSrc1==3'd3)?EPC:
				Cause;
	assign ALUB=IDEX_ALUSrc2?IDEX_EXTOut:ForwardRegB;
	
	_32LShift2 Shift1(IDEX_EXTOut, EXTOutLS2);
	_32AdderA Adder1(IDEX_PCP4, EXTOutLS2, 1'b0, 1'b0, ConBA);
	_32ALU ALU1(ALUA, ALUB, IDEX_ALUFunc, IDEX_Sign, ALUOut, Ovf);

	//EX/MEM寄存器----------------------------------------------------------------
	assign EXMEMFlush=IRQ;

	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			EXMEM_ALUOut<=32'd0;
			EXMEM_RegB<=32'd0;
			EXMEM_RegDstOut<=5'd0;
			EXMEM_MemToReg<=2'd0;
			EXMEM_RegWr<=1'd1;
			EXMEM_MemRd<=1'd0;
			EXMEM_MemWr<=1'd0;
			end
		else
			begin
			EXMEM_PCP4<=IDEX_PCP4;
			EXMEM_ALUOut<=EXMEMFlush?32'd0:ALUOut;
			EXMEM_RegB<=EXMEMFlush?32'd0:ForwardRegB;
			EXMEM_RegDstOut<=EXMEMFlush?5'd0:IDEX_RegDstOut;
			EXMEM_MemToReg<=EXMEMFlush?2'd0:IDEX_MemToReg;
			EXMEM_RegWr<=EXMEMFlush?1'd1:IDEX_RegWr;
			EXMEM_MemRd<=EXMEMFlush?1'd0:IDEX_MemRd;
			EXMEM_MemWr<=EXMEMFlush?1'd0:IDEX_MemWr;
			EXMEM_Flushed<=EXMEMFlush?1'd1:IDEX_Flushed;
			end
		end

	//MEM段-----------------------------------------------------------------------
	_RAM RAM1(R, C, EXMEM_ALUOut, EXMEM_MemRd, RAMOut, EXMEM_MemWr, 
			  EXMEM_RegB, TCOvf, Led, Switch, Hex, Rx, Tx, RxRdy, TxRdy);

	//MEM/WB寄存器-----------------------------------------------------------------
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			MEMWB_ALUOut<=32'd0;
			MEMWB_RegDstOut<=5'd0;
			MEMWB_MemToReg<=2'd0;
			MEMWB_RegWr<=1'd1;
			end
		else
			begin
			MEMWB_PCP4<=EXMEM_PCP4;
			MEMWB_ALUOut<=EXMEM_ALUOut;
			MEMWB_RAMOut<=RAMOut;
			MEMWB_RegDstOut<=EXMEM_RegDstOut;
			MEMWB_MemToReg<=EXMEM_MemToReg;
			MEMWB_RegWr<=EXMEM_RegWr;
			end
		end

	//WB段-------------------------------------------------------------------------
	assign RegC=(MEMWB_MemToReg==2'd0)?MEMWB_ALUOut:
				(MEMWB_MemToReg==2'd1)?MEMWB_RAMOut:
				MEMWB_PCP4;
	
	//异常和中断部分
	assign IRQ=((Ovf&&IDEX_OvfEn) || ErrInst || (TCOvf||RxRdy||TxRdy)) && (~IDEX_PC[31]) && (~IFID_PC[31]) && (~PC[31]);
	assign Exec=32'h8000_0004;
	
	always @(posedge C, negedge R)
		begin
		if(~R)
			begin
			EPC<=32'h8000_0000;
			Cause<=32'h0000_0000;
			end
		else
			begin
			if(IRQ)
				begin
				EPC<=~IDEX_Flushed?IDEX_PC:
					 ~IFID_Flushed?IFID_PC:
					 PC;
				Cause<={27'b0, TxRdy, RxRdy, TCOvf, Ovf&IDEX_OvfEn, ErrInst};
				end
			end
		end
		
	//转发单元
	assign ForwardA=EXMEM_RegWr && (EXMEM_RegDstOut!=5'b0) && (EXMEM_RegDstOut==IDEX_Rs)?2'd2:
					MEMWB_RegWr && (MEMWB_RegDstOut!=5'b0) && (MEMWB_RegDstOut==IDEX_Rs)?2'd1:
					2'd0;
	assign ForwardB=EXMEM_RegWr && (EXMEM_RegDstOut!=5'b0) && (EXMEM_RegDstOut==IDEX_Rt)?2'd2:
					MEMWB_RegWr && (MEMWB_RegDstOut!=5'b0) && (MEMWB_RegDstOut==IDEX_Rt)?2'd1:
					2'd0;
	assign ForwardAJump=IDEX_RegWr && (IDEX_RegDstOut!=5'b0) && (IDEX_RegDstOut==IFID_Rs)?2'd1:
						EXMEM_RegWr && (EXMEM_RegDstOut!=5'b0) && (EXMEM_RegDstOut==IFID_Rs)?2'd2:
						MEMWB_RegWr && (MEMWB_RegDstOut!=5'b0) && (MEMWB_RegDstOut==IFID_Rs)?2'd3:
						2'd0;				
					
   
   //冒险检测单元
   assign Stall=(IDEX_MemRd && ((IDEX_Rt==IFID_Rs) || (IDEX_Rt==IFID_Rt)));
   
   //分支单元
   assign Branch=(IDEX_PCSrc==2'd1)?ALUOut[0]:1'b0;
   
   //跳转单元
   assign Jump=(IFID_OpCode[5:1]==5'b00001) || ((IFID_OpCode==6'b0) && (IFID_Funct[5:1]==5'b00100));
 
endmodule