`timescale 1ns/1ps

`ifdef PIPE
	`include "PATTERN_bonus.v"
`else
	`include "PATTERN.v"
`endif

`ifdef RTL
  `ifdef PIPE
    `include "RCL_bonus.v"
  `else
    `include "RCL.v"
  `endif
`endif
`ifdef GATE
  `ifdef PIPE
    `include "RCL_bonus_SYN.v"
  `else
    `include "RCL_SYN.v"
  `endif
`endif
	  		  	
module TESTBED;

wire            clk, rst_n, in_valid;
wire    [4:0]  	coef_Q, coef_L;

wire            out_valid;
wire    [1:0]   out;


initial begin
  `ifdef RTL
    `ifdef PIPE
	  $fsdbDumpfile("RCL_bonus.fsdb");
	  $fsdbDumpvars(0,"+mda");
	`else
	  $fsdbDumpfile("RCL.fsdb");
	  $fsdbDumpvars(0,"+mda");
	`endif
  `endif
  `ifdef GATE
    `ifdef PIPE
	  $sdf_annotate("RCL_bonus_SYN.sdf", u_RCL);
      //$fsdbDumpfile("RCL_bonus_SYN.fsdb");
      //$fsdbDumpvars(0,"+mda");
	`else
	  $sdf_annotate("RCL_SYN.sdf", u_RCL);
      //$fsdbDumpfile("RCL_SYN.fsdb");
      //$fsdbDumpvars(0,"+mda");  
	`endif   
  `endif
end

RCL u_RCL(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .coef_Q(coef_Q),
    .coef_L(coef_L),
    .out_valid(out_valid),
    .out(out)
);

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .coef_Q(coef_Q),
    .coef_L(coef_L),
    .out_valid(out_valid),
    .out(out)
);
  
 
endmodule
