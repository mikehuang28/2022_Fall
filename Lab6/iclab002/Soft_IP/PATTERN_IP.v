//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN_IP.v
//   Module Name : PATTERN_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
    `define CYCLE_TIME 6.0
`endif

`ifdef GATE
    `define CYCLE_TIME 6.0
`endif

module PATTERN_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg [WIDTH-1:0]   Binary_code;
input      [DIGIT*4-1:0] BCD_code;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
real CYCLE = `CYCLE_TIME;

integer PATNUM;
integer patcount, i, j, a, in_read;
//================================================================
// Wire & Reg Declaration
//================================================================
reg clk;
reg [DIGIT*4-1:0] golden_out;
//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// Initial
//================================================================
initial begin
    Binary_code = 'bx;
    @(negedge clk);

    in_read = $fopen("../00_TESTBED/input_20.txt", "r");
    // check WIDTH = 8, 12, 16, 20, should change the parameter in TESTBED.v !
    // WIDTH = 4 ; DIGIT = 2;
    // WIDTH = 8 ; DIGIT = 3;
    // WIDTH = 12; DIGIT = 4;
    // WIDTH = 16; DIGIT = 5;
    // WIDTH = 20; DIGIT = 7;
    a = $fscanf(in_read, "%d\n", PATNUM);

    for(patcount = 0; patcount < PATNUM; patcount = patcount + 1)begin
        gen_data;
        @(negedge clk);
        check_ans;
        repeat(3) @(negedge clk);
    end

    YOU_PASS_TASK;
end

//================================================================
// TASK
//================================================================

task gen_data; begin
    a = $fscanf (in_read, "%d", Binary_code);
    a = $fscanf (in_read, "%b", golden_out);
end endtask

task check_ans; begin
    if(BCD_code !== golden_out)begin
        fail_task;
        $display ("-------------------------------------------------------------------");
		$display ("*                            PATTERN NO.%4d 	                      ", patcount);
        $display ("             answer should be : %b , your answer is : %b           ", golden_out, BCD_code);
        $display ("-------------------------------------------------------------------");
        #(100);
        $finish ;
    end
    else
        $display ("             Pass Pattern NO. %d          ", patcount);
end endtask

task fail_task; begin
    $display("\n");
    $display("        ----------------------------");
    $display("        --          FAIL          --");
    $display("        ----------------------------");
    $display("\n");
end endtask

task YOU_PASS_TASK; begin
    $display("\n");
    $display("        ----------------------------");
    $display("        --          PASS          --");
    $display("        ----------------------------");
    $display("\n");
    $finish;
end endtask


endmodule