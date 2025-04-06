`timescale 1ns / 1ps


module i2c_test_tb();
	parameter SYS_CLK    = 100_000_000;   // 100 MHz
	parameter DATA_RATE0 = 100_000,       // 100 kbps
  			  DATA_RATE1 = 400_000,   	  // 400 kbps
  			  DATA_RATE2 = 1_000_000,     // 1 MHz
  			  DATA_RATE3 = 3_400_000;  	  // 3.4 Mbps	
    
    // MASTER Signals:
    reg clk   = 0;
    reg rst   = 0;
    reg write = 0;
    reg read  = 0;
    reg  [1:0] speed_mode = 2'b10;
	reg  [6:0] addr       = 0;         
	reg  [7:0] data_wr    = 0;    
	wire [7:0] data_rd;  
	wire done;           
	wire ack_error;      

    // SLAVE Signals:
    wire [7:0] data_wr_slv1;
    reg  [7:0] data_rd_slv1;
    reg  [6:0] addr_slv1;
    wire done_slv1;
    wire [7:0] data_wr_slv2;
    reg  [7:0] data_rd_slv2;
    reg  [6:0] addr_slv2;
    wire done_slv2;

    // Clk & Speed:
    reg [13:0] SCL_PERIOD = speed_mode[1] ? (speed_mode[0] ? 10*SYS_CLK/DATA_RATE3 : 10*SYS_CLK/DATA_RATE2) : (speed_mode[0] ? 10*SYS_CLK/DATA_RATE1 : 10*SYS_CLK/DATA_RATE0);
    always #5 clk <= ~clk;

    i2c_test DUT(
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
		.data_wr_slv1(data_wr_slv1),
		.data_rd_slv1(data_rd_slv1),
		.addr_slv1(addr_slv1),
		.done_slv1(done_slv1),
		.data_wr_slv2(data_wr_slv2),
		.data_rd_slv2(data_rd_slv2),
		.addr_slv2(addr_slv2),
		.done_slv2(done_slv2)
    );


    initial
    begin
       #(100*SCL_PERIOD);
       rst = 1;
       #(10*SCL_PERIOD);
       rst = 0;
       #(1000*SCL_PERIOD);
       
       
       write_proc( 7'b001_1001, 7'b001_1101, 1'b0, 8'b0101_1001 );
       read_proc( 7'b001_1001, 7'b001_1101, 1'b0, 8'b0101_1001 );

    end
    
	task write_proc( input [6:0] address_slv1, input [6:0] address_slv2, input sel_slv, input [7:0] data_write );
    begin
        data_wr   = data_write;
        addr      = sel_slv ? address_slv2 : address_slv1;
        addr_slv1 = address_slv1;
        addr_slv2 = address_slv2;

        #(SCL_PERIOD);
        write   = 1;
        read    = 0;
        #(SCL_PERIOD);
        write   = 0;   
              
        #(21*SCL_PERIOD);
        $display("%b =? %b | %s", data_wr, sel_slv ? data_wr_slv2 : data_wr_slv1, data_wr == (sel_slv ? data_wr_slv2 : data_wr_slv1 ) ? "True" : "False");
        #(SCL_PERIOD);
    end
	endtask    

	task read_proc( input [6:0] address_slv1, input [6:0] address_slv2, input sel_slv, input [7:0] data_read );
    begin
        data_rd_slv1 = data_read & ~sel_slv;
        data_rd_slv2 = data_read & sel_slv;

        addr      = sel_slv ? address_slv2 : address_slv1;
        addr_slv1 = address_slv1;
        addr_slv2 = address_slv2;

        #(SCL_PERIOD);
        write   = 0;
        read    = 1;
        #(SCL_PERIOD);
        read    = 0;       
        #(21*SCL_PERIOD);
        $display("%b =? %b | %s", data_rd, sel_slv ? data_rd_slv2 : data_rd_slv1, data_rd == (sel_slv ? data_rd_slv2 : data_rd_slv1 ) ? "True" : "False");
        #(SCL_PERIOD);
    end
	endtask    
    
endmodule
