// Interleaver for 64 bits = 8 bytes
// Input data from SPI Interface
// Uses "SPI_Slave.v" as submodule

module Interleaver

	#(
	// Parameters
	parameter SPI_MODE 	= 1,
	parameter DATABYTES = 8
	)

	(	
	// FPGA Signals
	input clk, rst_n,
	
	// SPI Interface
	input i_MOSI,
	input i_SPCK,
	input i_CS_n,

	// Interleaved Data
	output reg [DATABYTES*8-1:0] o_Interleaved_Bits,
	output reg [DATABYTES*8-1:0] o_RX_Bits,
	output reg o_RX_Frame_Ready
	);
	
	reg [$clog2(DATABYTES+1):0] r_RX_Count_Bytes;
	reg [DATABYTES*8-1:0] r_RX_Bits;
	reg r_RX_Frame_Ready;
	reg r_RX_Byte_En;
	
	wire [7:0] w_RX_byte;
	wire r_RX_Byte_Ready;
	wire w_RX_Byte_En;

	// Instantiate SPI_Slave
	SPI_Slave
	#(.SPI_MODE(SPI_MODE)) SPI_Slave_Inst 
	
	(
	// FPGA Signals
	.clk(clk),
	.rst_n(rst_n),

	// SPI Interface
	.i_MOSI(i_MOSI),
	.i_SPCK(i_SPCK),
	.i_CS_n(i_CS_n),

	// SPI MOSI Signals
	.o_RX_Byte(w_RX_byte),
	.o_RX_Ready(w_RX_Byte_Ready)
	);
	
	// Put input data in one register
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			r_RX_Bits <= 0;
			r_RX_Count_Bytes <= DATABYTES;
			r_RX_Frame_Ready <= 1'b0; 
		end
		else
		begin
			if (w_RX_Byte_En)
			begin
				r_RX_Frame_Ready <= 1'b0;
				r_RX_Count_Bytes <= r_RX_Count_Bytes - 1;
				r_RX_Bits <= {r_RX_Bits[8*(DATABYTES-1)-1:0], w_RX_byte};
			end
			else if (r_RX_Count_Bytes == 0)
			begin
				r_RX_Count_Bytes <= DATABYTES;
				r_RX_Frame_Ready <= 1'b1;	
			end	
		end
	end

	// Rising Edge detector
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			r_RX_Byte_En <= 1'b0;
		end
		else
		begin
			r_RX_Byte_En <= w_RX_Byte_Ready; 
		end
	end

	assign w_RX_Byte_En = w_RX_Byte_Ready & ~r_RX_Byte_En;	// Pulse then Rising Edge


	// Interleave bits in r_RX_Bits register according to algorithm
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			o_Interleaved_Bits <= 0;	 
		end
		else
		begin
			if (r_RX_Frame_Ready)
			begin
				o_RX_Frame_Ready 	<= r_RX_Frame_Ready;
				o_RX_Bits 			<= r_RX_Bits; 
				o_Interleaved_Bits 	<= {r_RX_Bits[63-53],	r_RX_Bits[63-40],	r_RX_Bits[63-27],	r_RX_Bits[63-14],	
							r_RX_Bits[63-1],	r_RX_Bits[63-54],	r_RX_Bits[63-50],	r_RX_Bits[63-33],
							r_RX_Bits[63-15],	r_RX_Bits[63-6], r_RX_Bits[63-56],	r_RX_Bits[63-43],	
							r_RX_Bits[63-36],	r_RX_Bits[63-17],	r_RX_Bits[63-10],	r_RX_Bits[63-60],
							r_RX_Bits[63-44],	r_RX_Bits[63-31],	r_RX_Bits[63-21],	r_RX_Bits[63-8],
							r_RX_Bits[63-55],	r_RX_Bits[63-42],	r_RX_Bits[63-35],	r_RX_Bits[63-16],
							r_RX_Bits[63-9],	r_RX_Bits[63-58],	r_RX_Bits[63-46],	r_RX_Bits[63-37],
							r_RX_Bits[63-19],	r_RX_Bits[63-2],	r_RX_Bits[63-51],	r_RX_Bits[63-38],	
							r_RX_Bits[63-25],	r_RX_Bits[63-12],	r_RX_Bits[63-63],	r_RX_Bits[63-41],
							r_RX_Bits[63-32],	r_RX_Bits[63-24],	r_RX_Bits[63-7],	r_RX_Bits[63-61],
							r_RX_Bits[63-48],	r_RX_Bits[63-29],	r_RX_Bits[63-22],	r_RX_Bits[63-3],
							r_RX_Bits[63-57],	r_RX_Bits[63-47],	r_RX_Bits[63-34],	r_RX_Bits[63-18],	
							r_RX_Bits[63-5],	r_RX_Bits[63-62],	r_RX_Bits[63-49],	r_RX_Bits[63-30],	
							r_RX_Bits[63-23],	r_RX_Bits[63-4],	r_RX_Bits[63-59],	r_RX_Bits[63-45],
							r_RX_Bits[63-28],	r_RX_Bits[63-20],	r_RX_Bits[63-11],	r_RX_Bits[63-52],	
							r_RX_Bits[63-39],	r_RX_Bits[63-26],	r_RX_Bits[63-13],	r_RX_Bits[63-0]};
			end	
		end	
	end
endmodule
