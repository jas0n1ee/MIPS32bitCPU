module _Control(Op, Funct, Out, ErrInst);
	input [5:0] Op, Funct;
	output [21:0] Out;
	output ErrInst;
	
	reg [21:0] Out;
	reg ErrInst;
	
	always @(*)
		begin
		if(Op==6'b0)
			begin
			case(Funct)
				6'b100000:{Out, ErrInst}=23'b000000_x_000_0_1_x_00_00_00_0_0_1_0;
				6'b100001:{Out, ErrInst}=23'b000000_x_000_0_1_x_00_00_00_0_0_0_0;
				6'b100010:{Out, ErrInst}=23'b000001_x_000_0_1_x_00_00_00_0_0_1_0;
				6'b100011:{Out, ErrInst}=23'b000001_x_000_0_1_x_00_00_00_0_0_0_0;
				6'b100100:{Out, ErrInst}=23'b011000_x_000_0_1_x_00_00_00_0_0_x_0;
				6'b100101:{Out, ErrInst}=23'b011110_x_000_0_1_x_00_00_00_0_0_x_0;
				6'b100110:{Out, ErrInst}=23'b010110_x_000_0_1_x_00_00_00_0_0_x_0;
				6'b100111:{Out, ErrInst}=23'b010001_x_000_0_1_x_00_00_00_0_0_x_0;
				6'b000000:{Out, ErrInst}=23'b100000_x_001_0_1_x_00_00_00_0_0_x_0;
				6'b000010:{Out, ErrInst}=23'b100001_x_001_0_1_x_00_00_00_0_0_x_0;
				6'b000011:{Out, ErrInst}=23'b100011_x_001_0_1_x_00_00_00_0_0_x_0;
				6'b101010:{Out, ErrInst}=23'b110101_1_000_0_1_x_00_00_00_0_0_x_0;
				6'b001000:{Out, ErrInst}=23'b000000_x_000_x_0_x_11_xx_xx_0_0_x_0;
				6'b001001:{Out, ErrInst}=23'b000000_x_000_x_1_x_11_10_10_0_0_x_0;
				default:{Out, ErrInst}=23'bxxxxxx_x_xxx_x_x_x_xx_xx_xx_x_x_x_1;
			endcase
			end
		else
			begin
			case(Op)
				6'b100011:{Out, ErrInst}=23'b000000_x_000_1_1_1_00_01_01_0_1_x_0;
				6'b101011:{Out, ErrInst}=23'b000000_x_000_1_0_1_00_xx_xx_1_0_x_0;
				6'b001111:{Out, ErrInst}=23'b100000_x_010_1_1_x_00_01_00_0_0_x_0;
				6'b001000:{Out, ErrInst}=23'b000000_x_000_1_1_1_00_01_00_0_0_1_0;
				6'b001001:{Out, ErrInst}=23'b000000_x_000_1_1_1_00_01_00_0_0_x_0;
				6'b001100:{Out, ErrInst}=23'b011000_x_000_1_1_0_00_01_00_0_0_x_0;
				6'b001010:{Out, ErrInst}=23'b000001_1_000_1_1_1_00_01_00_0_0_x_0;
				6'b001011:{Out, ErrInst}=23'b000001_0_000_1_1_0_00_01_00_0_0_x_0;
				6'b000100:{Out, ErrInst}=23'b000001_1_000_0_0_1_01_xx_xx_0_0_x_0;
				6'b000101:{Out, ErrInst}=23'b000001_1_000_0_0_1_01_xx_xx_0_0_x_0;
				6'b000110:{Out, ErrInst}=23'b000001_1_000_0_0_1_01_xx_xx_0_0_x_0;
				6'b000111:{Out, ErrInst}=23'b000001_1_000_0_0_1_01_xx_xx_0_0_x_0;
				6'b000001:{Out, ErrInst}=23'b000001_1_000_0_0_1_01_xx_xx_0_0_x_0;
				6'b000010:{Out, ErrInst}=23'b000000_x_000_x_0_x_10_xx_xx_0_0_x_0;
				6'b000011:{Out, ErrInst}=23'b000000_x_000_x_1_x_10_10_10_0_0_x_0;
				6'b010100:{Out, ErrInst}=23'b011010_x_011_x_1_x_00_01_00_0_0_x_0;
				6'b010101:{Out, ErrInst}=23'b011010_x_100_x_1_x_00_01_00_0_0_x_0;
				default:{Out, ErrInst}=23'bxxxxxx_x_xxx_x_x_x_xx_xx_xx_x_x_x_1;
			endcase
			end
		end
	
endmodule