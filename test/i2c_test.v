`timescale 1ns / 1ps


module i2c_test(
    // MASTER Signals:
    input clk,
    input rst,
    input write,
    input read,
    input  [1:0] speed_mode,
	input  [6:0] addr,         
	input  [7:0] data_wr,       // data to be written
	output [7:0] data_rd,  // data read
	output done,           // wr/rd operation is done
	output ack_error,      // ACK error
	
	// SLAVE Signals:
    output [7:0] data_wr_slv1,
    input  [7:0] data_rd_slv1,
    input  [6:0] addr_slv1,
    output done_slv1,
    output [7:0] data_wr_slv2,
    input  [7:0] data_rd_slv2,
    input  [6:0] addr_slv2,
    output done_slv2
);

	wire  SDA;
	wire  SCL;   
      
      
    i2c_master MST(
		.clk(clk),
		.rst(rst),
		.write(write),
		.read(read),
		.speed_mode(speed_mode),
		.addr(addr),
		.data_wr(data_wr),
		.data_rd(data_rd),
		.done(done),
		.ack_error(ack_error),
		.SDA(SDA),
		.SCL(SCL)    
    );
    
    
    i2c_slave SLV1(
		.rst(rst),
		.addr(addr_slv1),
		.data_rd(data_rd_slv1),
		.data_wr(data_wr_slv1),
		.done(done_slv1),
		.SDA(SDA),
		.SCL(SCL)    
    );

    i2c_slave SLV2(
		.rst(rst),
		.addr(addr_slv2),
		.data_rd(data_rd_slv2),
		.data_wr(data_wr_slv2),
		.done(done_slv2),
		.SDA(SDA),
		.SCL(SCL)    
    );
    
    
endmodule
