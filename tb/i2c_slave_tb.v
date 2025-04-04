`timescale 1ns / 1ps



module i2c_slave_tb();

	// System Signals
	reg  rst              = 0;
	reg  [6:0] addr       = 0;
	reg  [7:0] data_rd    = 0;
	wire [7:0] data_wr;
	wire done;
	// I2C Signals
	reg  SCL              = 0;		
	wire SDA;
    
	always #50 SCL <= ~SCL;

	i2c_slave I2C(
		.rst(rst),
		.addr(addr),
		.data_rd(data_rd),
		.data_wr(data_wr),
		.done(done),
		.SDA(SDA),
		.SCL(SCL)
	);
	
    reg SDA_reg = 1'b1;
    reg SDA_en  = 1'b1;
    
    assign SDA = SDA_en ? SDA_reg : 1'bz;


	initial
	begin
       #200;
       rst = 1;
       #50;
       rst = 0;
       #200;
       
       write_proc( 7'b0001111, 8'b10101011);
       write_proc( 7'b0001111, 8'b10101011);
       read_proc ( 7'b0001111, 8'b10101011);
       read_proc ( 7'b0001111, 8'b10101011);
	end
    
    
	task write_proc( input [6:0] address, input [7:0] data_write );
    begin
        addr    = address;
        SDA_en  = 1'b1;
		SDA_reg = 1'b1;
		// START:
        @(posedge SCL);
		SDA_reg = 1'b0;
		// ADDRESS:
            @(posedge SCL);
			SDA_reg = address[6];
			@(posedge SCL);
			SDA_reg = address[5];
			@(posedge SCL);
			SDA_reg = address[4];
			@(posedge SCL);
			SDA_reg = address[3];
			@(posedge SCL);
			SDA_reg = address[2];
			@(posedge SCL);
			SDA_reg = address[1];
			@(posedge SCL);
			SDA_reg = address[0];
			@(posedge SCL);
			SDA_reg = 1'b0;     // write
		// ACK:
        @(posedge SCL);
        SDA_en  = 1'b0;
        // DATA:
		    @(posedge SCL);
			SDA_en  = 1'b1;
			SDA_reg = data_write[7];
			@(posedge SCL);
			SDA_reg = data_write[6];
			@(posedge SCL);
			SDA_reg = data_write[5];
			@(posedge SCL);
			SDA_reg = data_write[4];
			@(posedge SCL);
			SDA_reg = data_write[3];
			@(posedge SCL);
			SDA_reg = data_write[2];
			@(posedge SCL);
			SDA_reg = data_write[1];
			@(posedge SCL);
			SDA_reg = data_write[0];
	    // ACK:
		@(posedge SCL);
        SDA_en  = 1'b0;
        // STOP:
		@(posedge SCL);
		SDA_en  = 1'b1;
		SDA_reg = 1'b0;
		@(posedge SCL);
		SDA_reg = 1'b1;
		@(posedge SCL);
    end
	endtask

	task read_proc( input [6:0] address, input [7:0] data_read );
    begin
        addr    = address;
        data_rd = data_read;
        SDA_en  = 1'b1;
		SDA_reg = 1'b1;
		// START:
        @(posedge SCL);
		SDA_reg = 1'b0;
		// ADDRESS:
            @(posedge SCL);
			SDA_reg = address[6];
			@(posedge SCL);
			SDA_reg = address[5];
			@(posedge SCL);
			SDA_reg = address[4];
			@(posedge SCL);
			SDA_reg = address[3];
			@(posedge SCL);
			SDA_reg = address[2];
			@(posedge SCL);
			SDA_reg = address[1];
			@(posedge SCL);
			SDA_reg = address[0];
			@(posedge SCL);
			SDA_reg = 1'b1;      // read
		// ACK:
        @(posedge SCL);
        SDA_en  = 1'b0;
        // DATA:
            repeat(8) @(posedge SCL);
        // NACK:
        SDA_en  = 1'b1;
		SDA_reg = 1'b1;
		// STOP:
		@(posedge SCL);
        SDA_en  = 1'b1;
		SDA_reg = 1'b0;
		@(posedge SCL);
        SDA_en  = 1'b1;
		SDA_reg = 1'b1;
		@(posedge SCL);
    end
	endtask
endmodule