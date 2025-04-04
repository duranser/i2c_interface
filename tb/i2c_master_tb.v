`timescale 1ns / 1ps



module i2c_master_tb();
	
	// System Signals
	reg  clk              = 0;		
	reg  rst              = 0;
	reg  write            = 0;	
	reg  read             = 0;
	reg  [1:0] speed_mode = 2'b10;
	reg  [6:0] addr       = 0;
	reg  [7:0] data_wr    = 0;
	wire [7:0] data_rd;
	wire done;
	wire ack_error;
	// I2C Signals
	wire SDA;
	wire SCL;
    
	// Clock
	always #5 clk <= ~clk;

	
	// DUT
	i2c_master I2C(
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
	
    reg SDA_reg = 1'b0;
    reg SDA_en  = 1'b0;
    
    assign SDA = SDA_en ? SDA_reg : 1'bz;


	initial
	begin
       repeat(200) @(posedge clk);
       rst = 1;
       repeat(100) @(posedge clk);
       rst = 0;
       repeat(200) @(posedge clk);	
       
       write_proc( 7'b0001111, 8'b10101011);
       write_proc( 7'b0001111, 8'b10101011);
       read_proc ( 7'b0001111, 8'b10101011);
       read_proc ( 7'b0001111, 8'b10101011);

	end
    
    
	task write_proc( input [6:0] address, input [7:0] data_write );
    begin
        addr    = address;
        data_wr = data_write;
        write   = 1;
        read    = 0;
        SDA_en  = 1'b0;
        repeat(3) @(posedge SCL);
        repeat(8) @(posedge SCL);
        SDA_en  = 1'b1;
        SDA_reg = 1'b0;
        @(posedge SCL);
        SDA_en  = 1'b0;
        repeat(8) @(posedge SCL);
        SDA_en  = 1'b1;
        SDA_reg = 1'b0;
        @(posedge SCL);
        SDA_en  = 1'b0;
        @(posedge SCL);
    end
	endtask

	task read_proc( input [6:0] address, input [7:0] data_read );
    begin
        addr    = address;
        write   = 0;
        read    = 1;
        SDA_en  = 1'b0;
        repeat(3) @(posedge SCL);
        repeat(8) @(posedge SCL);
        SDA_en  = 1'b1;
        SDA_reg = 1'b0;
        read    = 0;
        @(posedge SCL);
            SDA_en  = 1'b1;
            SDA_reg = data_read[7];
            @(posedge SCL);
            SDA_reg = data_read[6];
            @(posedge SCL);
            SDA_reg = data_read[5];
            @(posedge SCL);
            SDA_reg = data_read[4];
            @(posedge SCL);
            SDA_reg = data_read[3];       
            @(posedge SCL);
            SDA_reg = data_read[2];
            @(posedge SCL);
            SDA_reg = data_read[1];
            @(posedge SCL);
            SDA_reg = data_read[0];           
        @(posedge SCL);
        SDA_en  = 1'b0;
        @(posedge SCL);
        @(posedge SCL);
    end
	endtask
endmodule