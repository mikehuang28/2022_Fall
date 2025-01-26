module CHIP(    
	// Input signals
    clk,
    rst_n,
	in_valid,
    source,
    destination,
	
    // Output signals
	out_valid,
    cost
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input               clk, rst_n, in_valid;
input       [3:0]   source;
input       [3:0]   destination;

output				out_valid;
output		[3:0]	cost;

wire				C_clk;
wire				C_rst_n;
wire				C_in_valid;
wire		[3:0]	C_source;
wire		[3:0]	C_destination;

wire				C_out_valid;
wire		[3:0]	C_cost;


wire				BUF_clk;
CLKBUFX20 buf0(.A(C_clk),.Y(BUF_clk));


TT u_TT(
    .clk(BUF_clk),
    .rst_n(C_rst_n),
    .in_valid(C_in_valid),
    .source(C_source),
    .destination(C_destination),
    
    .out_valid(C_out_valid),
    .cost(C_cost)
);




//I/O power 3.3V pads x? (DVDD + DGND)


//Core poweri 1.8V pads x? (VDD + GND)


endmodule