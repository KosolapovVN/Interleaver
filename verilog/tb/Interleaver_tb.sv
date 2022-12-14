// For simulation needs "SPI_Master.v", "SPI_Master_CS.v" in work folder.
// Variable "Interleaved_Bytes" compare with "data_out_hex.dat" 
// which is generated after running MATLAB script
 
` timescale 1ns/1ns

module Interleaver_tb();
	
	// Parameters
	parameter SPI_MODE = 3;
	parameter CLKS_PER_HALF_BIT = 4;
	parameter CS_INACTIVE_CLKS = 1;
	parameter MAX_BYTES_PER_CS	= 8;
	parameter MAIN_CLK_DELAY = 2;
	parameter DATABYTES = 8;


	// Main Signals	
	logic 	r_rst_n	= 1'b0;
	logic 	r_clk	= 1'b0;
  
  	// Master/Slave Connection
	logic 	w_SPCK;
  	logic 	w_CS_n;
  	logic 	w_MOSI;
  	
  	// Master Specific
  	logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_Master_RX_Count;
	logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] r_Master_TX_Count = MAX_BYTES_PER_CS;
	logic [7:0] r_Master_TX_Byte = 0;
  	logic [7:0] r_Master_RX_Byte;
	logic r_Master_TX_En = 1'b0;
  	logic w_MasterCS_TX_Ready;
	logic r_Master_RX_EN;	
	
  
  	// Interleaver Specific
  	logic [DATABYTES*8-1:0] w_RX_Bits;
	logic [DATABYTES*8-1:0] w_Interleaved_Bits;

	// Variables
	logic [11:0] i;
	logic [7:0] Interleaved_Bytes;

	
	// Clock Generation
  	always #(MAIN_CLK_DELAY) r_clk = ~r_clk;

	// Instantiate Slave UUT
	Interleaver 
	#(	
	// Parameters
	.SPI_MODE(SPI_MODE),
	.DATABYTES(DATABYTES)) Interleaver_UUT

	(
	// Control/Data Signals,
	.rst_n(r_rst_n),      
	.clk(r_clk),          
	.o_RX_Bits(w_RX_Bits),
	.o_Interleaved_Bits(w_Interleaved_Bits),
 
	// SPI Interface
   	.i_SPCK(w_SPCK),
   	.i_MOSI(w_MOSI),
   	.i_CS_n(w_CS_n)
   	);


	// Instantiate Master
  	SPI_Master_CS
  	#(.SPI_MODE(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
    .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS),
	.MAX_BYTES_PER_CS(MAX_BYTES_PER_CS)) SPI_Master_CS_UUT
  
	(
	// Control/Data Signals,
   	.rst_n(r_rst_n),   	  
   	.clk(r_clk),        
   	.i_TX_Byte(r_Master_TX_Byte),     
   	.i_TX_En(r_Master_TX_En),         
   	.o_TX_Ready(w_MasterCS_TX_Ready),     
	.i_TX_Count(r_Master_TX_Count),

	// MISO signals
	.o_RX_Byte(r_Master_RX_Byte),
	.o_RX_En(r_Master_RX_En),
	.o_RX_Count(w_Master_RX_Count),
 
	// SPI Interface
	.o_SPCK(w_SPCK),
	.o_CS_n(w_CS_n),
	.i_MISO(w_MOSI),
	.o_MOSI(w_MOSI)
   	);

	// Task to send one byte
	task SendByte(input [7:0] data);
		@(posedge r_clk);
		r_Master_TX_Byte 	<= data;
		r_Master_TX_En 	<= 1'b1;
		@(posedge r_clk);
		r_Master_TX_En		<= 1'b0;
		@(posedge w_MasterCS_TX_Ready);
	endtask

	initial
	begin
		repeat(10) @(posedge r_clk);
		r_rst_n = 1'b0;
		repeat(10) @(posedge r_clk);
		r_rst_n = 1'b1;
		repeat(10) @(posedge r_clk);
      
		for (i = 1; i < MAX_BYTES_PER_CS + 1; i = i + 1)
		begin
			SendByte(i);
			$display("Sent out 0x%X", i, "  Received 0x%X", r_Master_RX_Byte); 
		end  
		repeat(10) @(posedge r_clk);
		
		for (i = 1; i < MAX_BYTES_PER_CS + 1; i = i + 1)
		begin
			Interleaved_Bytes = w_Interleaved_Bits[8*(MAX_BYTES_PER_CS-i+1)-1 -: 8]; 
			$display("Interleaved Data Bytes 0x%X", Interleaved_Bytes); 
		end  
		$finish();
	end	
endmodule
