// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //   File Name   : PATTERN.v
// //   Module Name : PATTERN
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################

// `ifdef RTL_TOP
//     `define CYCLE_TIME 5.4
// `endif

// `ifdef GATE_TOP
//     `define CYCLE_TIME 5.4
// `endif

// module PATTERN (
//     // Output signals
//     clk, rst_n, in_valid, in_time,
//     // Input signals
//     out_valid, out_display, out_day
// );

// // ===============================================================
// // Input & Output Declaration
// // ===============================================================
// output reg clk, rst_n, in_valid;
// output reg [30:0] in_time;
// input out_valid;
// input [3:0] out_display;
// input [2:0] out_day;

// // ===============================================================
// // Parameter & Integer Declaration
// // ===============================================================
// real CYCLE = `CYCLE_TIME;

// //================================================================
// // Wire & Reg Declaration
// //================================================================
// integer a, f;
// integer PAT_NUM, pat_i;
// integer latency, total_latency;
// integer i, output_cycle_cnt;

// reg [30:0] unix_time;

// //================================================================
// // Clock
// //================================================================
// initial clk = 0;
// always #(CYCLE/2.0) clk = ~clk;

// //================================================================
// // Initial
// //================================================================
// initial begin
//     f  = $fopen("../00_TESTBED/pattern_2.txt", "r");
//     a = $fscanf(f, "%d", PAT_NUM);
//     clk = 0;
//     in_valid = 0;
//     total_latency = 0;
//     rst_n = 1;

//     reset_task;

//     @(negedge clk);
//     for(pat_i=0; pat_i<PAT_NUM; pat_i=pat_i+1) begin
//         input_task;
//         weight_out_valid;
//         check_ans_task;
//     end
//     U_PASS_TASK;
//     $finish;
// end

// //================================================================
// // TASK
// //================================================================
// task reset_task;
//     begin
//         force clk = 0;
//         #CYCLE; rst_n = 0;
//         #CYCLE; rst_n = 1;
//         if(out_valid!==0 || out_day!==3'b000 || out_display!==4'b0000) begin
//             $display("=====================");
//             $display("     RESET FAIL!     ");
//             $display("=====================");
//             $finish;
//         end
//         #CYCLE; release clk;
//     end
// endtask

// task input_task;
//     begin
//         in_valid = 1;
//         a = $fscanf(f, "%d", unix_time);
//         in_time = unix_time;
//         @(negedge clk);
//         in_valid = 0;
//         in_time = 31'bx;
//     end
// endtask

// task weight_out_valid;
//     begin
//         latency = 0;
//         while(out_valid!==1) begin
//             latency = latency + 1;
//             if(latency > 10000) begin
//                 $display("==========================================");
//                 $display("                   FAIL!                  ");
//                 $display("         Latency OVER 2000 cycles         ");
//                 $display("==========================================");
//                 $finish;
//             end
//             @(negedge clk);
//         end
//     end
// endtask

// task check_ans_task;
//     reg [3:0] golden_ans [0:14];
//     begin
//         for(i=0; i<15; i=i+1) begin
//             a = $fscanf(f, "%1d", golden_ans[i]);
//         end
//         output_cycle_cnt = 0;
//         while(out_valid === 1) begin
//             if(output_cycle_cnt > 14) begin
//                 $display("\033[0;31m=============================================================================\033[m");
//                 $display("\033[0;31m             out_valid shold be high in 14 cycles continuously               \033[m");
//                 $display("\033[0;31m=============================================================================\033[m");
//                 $finish;
//             end
//             if(out_display !== golden_ans[output_cycle_cnt]) begin
//                 $display("");
//                 $display("\033[0;31m=========================================\033[m");
//                 $display("\033[0;31m             WRONG ANSWER !              \033[m");
//                 $display("\033[0;31m=========================================\033[m");
//                 $display("");
//                 $display("\033[0;33m>>>> PATTERN %d\033[m, WRONG DAY/TIME", pat_i);
//                 $display("-----------------------------------------------------------------\n");
//                 $display("     GOLDEN ANSWER :               ");
//                 $display("     UNIX Timestamp : %d     ", unix_time);
//                 $display("     DATE: %d%d%d%d / %d%d / %d%d", golden_ans[0], golden_ans[1], golden_ans[2], golden_ans[3], golden_ans[4], golden_ans[5], golden_ans[6], golden_ans[7]);
//                 $display("     TIME: %d%d : %d%d : %d%d", golden_ans[8], golden_ans[9], golden_ans[10], golden_ans[11], golden_ans[12], golden_ans[13]);
//                 $display("     WEEK: %d", golden_ans[14]);
//                 $display("");
//                 $finish;
//             end
//             if(output_cycle_cnt === 13) begin
//                 if(out_day !== golden_ans[14]) begin
//                     $display("");
//                     $display("\033[0;31m=========================================\033[m");
//                     $display("\033[0;31m             WRONG ANSWER !              \033[m");
//                     $display("\033[0;31m=========================================\033[m");
//                     $display("");
//                     $display("\033[0;33m>>>> PATTERN %d\033[m, WRONG WEEK !", pat_i);
//                     $display("-----------------------------------------------------------------\n");
//                     $display("     GOLDEN ANSWER :               ");
//                     $display("     DATE: %d%d%d%d / %d%d / %d%d", golden_ans[0], golden_ans[1], golden_ans[2], golden_ans[3], golden_ans[4], golden_ans[5], golden_ans[6], golden_ans[7]);
//                     $display("     TIME: %d%d : %d%d : %d%d", golden_ans[8], golden_ans[9], golden_ans[10], golden_ans[11], golden_ans[12], golden_ans[13]);
//                     $display("     WEEK: %d", golden_ans[14]);
//                     $display("");
//                     $finish;
//                 end
//             end

//             output_cycle_cnt = output_cycle_cnt + 1;
//             @(negedge clk);
//         end
//         if(output_cycle_cnt < 14) begin
//             $display("\033[0;31m=============================================================================\033[m");
//             $display("\033[0;31m             out_valid shold be high in 14 cycles continuously               \033[m");
//             $display("\033[0;31m=============================================================================\033[m");
//             $finish;
//         end
//         $display("\033[0;36m PATTERN - %d\033[m \033[0;32mIS CORRECT !\033[m , \033[0;33mLatency = %2d\033[m", pat_i, latency);
//         total_latency = latency + total_latency;

//     end
// endtask

// task U_PASS_TASK;
//     begin
//         $display("");
//         $display("");
//         $display("\033[1;32m======================================================\033[m");
//         $display("\033[0;32m                                                      \033[m");
//         $display("\033[1;32m                  Simulation SUCCESS                  \033[m");
//         $display("\033[0;32m                                                      \033[m");
//         $display("\033[1;32m                YOU PASS ALL PATTERNS !               \033[m");
//         $display("\033[0;32m                                                      \033[m");
//         $display("\033[0;33m           Total Latency =  %d cycles                 \033[m", total_latency);
//         $display("\033[0;32m                                                      \033[m");
//         $display("\033[1;32m======================================================\033[m");
//         $finish;
//     end
// endtask

// endmodule


//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL_TOP
    `define CYCLE_TIME 5.4
`endif

`ifdef GATE_TOP
    `define CYCLE_TIME 5.4
`endif

module PATTERN (
    // Output signals
    clk, rst_n, in_valid, in_time,
    // Input signals
    out_valid, out_display, out_day
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg clk, rst_n, in_valid;
output reg [30:0] in_time;
input out_valid;
input [3:0] out_display;
input [2:0] out_day;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
real CYCLE = `CYCLE_TIME;
integer input_file, output_file;
integer total_cycles, cycles;
integer PATNUM, patcount;
integer gap;
integer a, b, c, d;
integer i, j, k;
integer golden_step;
integer out_day_fail;

//================================================================
// Wire & Reg Declaration
//================================================================
reg [3:0] golden_display [0:13];
reg [2:0] golden_day;

//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// Initial
//================================================================
initial begin
    rst_n    = 1'b1;
    in_valid = 1'b0;
    in_time  = 'dx;
	total_cycles = 0;

    force clk = 0;
    reset_task;

    input_file  = $fopen("../00_TESTBED/input_top.txt","r");
	output_file = $fopen("../00_TESTBED/output_top.txt","r");
    @(negedge clk);

    a = $fscanf(input_file, "%d", PATNUM);
	for (patcount=0; patcount<PATNUM; patcount=patcount+1) begin
		input_data;
		wait_out_valid;
		check_ans;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,cycles);
	end
	#(50);
	YOU_PASS_task;
	$finish;
end

//================================================================
// TASK
//================================================================
task reset_task ; begin
	#(10); rst_n = 1'b0;
	#(10);
	if((out_valid !== 0) || (out_display !== 0) || (out_day !== 0)) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		#(100);
		$finish ;
	end
	#(10); rst_n = 1'b1;
	#(3.0); release clk;
end endtask

task input_data; begin
	gap = $urandom_range(2,4);
	repeat(gap) @(negedge clk);
	in_valid = 1'b1;
	// Given Timestamp
	b = $fscanf (input_file, "%d", in_time);
    @(negedge clk);
	in_valid = 1'b0;
    in_time = 'dx;
end endtask

task wait_out_valid; begin
	cycles = 0;
	while(out_valid === 0)begin
		cycles = cycles + 1;
        if(cycles == 10000) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                        FAIL!                                                               ");
			$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
			$display ("                                                     The execution latency are over 10000 cycles                                             ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
		end
	@(negedge clk);
	end
	total_cycles = total_cycles + cycles;
end endtask

task check_ans; begin
	// Golden Answer
	for (i=0; i<14; i=i+1) c = $fscanf(output_file, "%d", golden_display[i]);
	d = $fscanf(output_file, "%d", golden_day); // Sunday(0) ~ Saturday(6)
	// Check Answer
	out_day_fail = 0;
	golden_step = 1;
	while (out_valid === 1) begin
		if ( golden_display[ golden_step-1 ] !== out_display ) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                        FAIL!                                                               ");
			$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
			$display ("                                                 The out_display should be correct when out_valid is high                                   ");
			$display ("                                                              Your output -> result: %d                                                     ", out_display);
			$display ("                                                            Golden output -> result: %d, step: %d                                           ", golden_display[golden_step-1], golden_step);
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			@(negedge clk);
			$finish;
		end
		if ( golden_day !== out_day ) out_day_fail = 1;
		if ( (golden_step==14) && (out_day_fail) ) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                        FAIL!                                                               ");
			$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
			$display ("                                                  The out_day should be correct when out_valid is high                                      ");
			$display ("                                                            Golden output -> result: %d                                                     ", golden_day);
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			@(negedge clk);
			$finish;
		end
		@(negedge clk);
		golden_step = golden_step + 1;
	end
	if(golden_step !== 15) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
		$display ("	                                                          Output cycle should be 14 cycles                                                 ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		@(negedge clk);
		$finish;
	end
end endtask

task YOU_PASS_task; begin
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						             ");
	$display ("                                           You have passed all patterns!          						             ");
	$display ("                                           Your execution cycles = %5d cycles   						                 ", total_cycles);
	$display ("                                           Your clock period = %.1f ns        					                     ", `CYCLE_TIME);
	$display ("                                           Your total latency = %.1f ns         						                 ", total_cycles*`CYCLE_TIME);
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;
end endtask

endmodule