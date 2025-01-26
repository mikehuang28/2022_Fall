`define CYCLE_TIME_IO 20.0
`define CYCLE_TIME_CALU 3.6
`define PATNUM 1000

`define max(v1, v2) ((v1) > (v2) ? (v1) : (v2))
`define min(v1, v2) ((v1) < (v2) ? (v1) : (v2))

module PATTERN (
    clk,
    clk2,
    rst_n,
    in_valid,
    op_valid,
    pic_data,
    se_data,
    op,

    out_valid,
    out_data
);

output reg clk, clk2, rst_n;
output reg in_valid, op_valid;
output reg [31:0] pic_data;
output reg [7:0] se_data;
output reg [2:0] op;

input out_valid;
input [31:0] out_data;

real CYCLE1 = `CYCLE_TIME_IO;
real CYCLE2 = `CYCLE_TIME_CALU;
parameter PAT_NUM = `PATNUM;
integer i_pat, i, j, i1, i2, j1, j2, k;
integer latency, total_latency = 0;
integer op_delay;
reg wrong;

reg [7:0] orig_pic[0:31][0:31];
reg [7:0] pic[0:31][0:31];
reg [7:0] out_pic[0:31][0:31];
reg [7:0] se[0:3][0:3];
reg [2:0] opcode;
reg [7:0] temp;

integer cdf [0:255];
integer cdf_min_idx, cdf_max_idx;
integer out_cnt;

parameter HISTOGRAM = 3'b000;
parameter EROSION = 3'b010;
parameter DILATION = 3'b011;
parameter OPENING = 3'b110;
parameter CLOSING = 3'b111;

initial begin
    clk = 0;
    clk2 = 0;
end
always #(CYCLE1/2.0) clk = ~clk;
always #(CYCLE2/2.0) clk2 = ~clk2;

initial begin
    reset_task;
    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat+1) begin
        input_task;
        calulate_ans;
        wait_out_valid_task;
        check_ans_task;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d,\033[m \033[0;36mOperation: %s\033[m"
            ,i_pat ,latency, print_op(opcode));
        total_latency = total_latency + latency;
    end
    YOU_PASS_task;
end

task reset_task; begin
	rst_n = 'b1;
	in_valid = 'b0;
    op_valid = 'b0;
	op = 'bx;
	pic_data = 'bx;
	se_data = 'bx;

    force clk = 0;
    force clk2 = 0;

    #CYCLE1; rst_n = 0;
    #CYCLE1; rst_n = 1;

    for (i = 0; i < 100; i = i+1) begin
        if(out_valid !== 'b0 || out_data !== 'b0) begin
            $display("************************************************************");
            $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
            $display("************************************************************");
            $finish;
        end
        #CYCLE1;
    end

    #CYCLE1;
    release clk;
    release clk2;
end endtask

task calulate_ans; begin
    case (opcode)
    HISTOGRAM: histogram;
    EROSION: erosion;
    DILATION: dilation;
    OPENING: begin
        erosion;
        dilation;
    end
    CLOSING:  begin
        dilation;
        erosion;
    end
    endcase
end endtask

task input_task; begin
    repeat($urandom_range(1, 3)) @(negedge clk);
    in_valid = 'b1;
    for (i = 0; i < 32; i = i+1)
        for (j = 0; j < 32; j = j+1) begin
            pic[i][j] = $urandom();
            orig_pic[i][j] = pic[i][j];
        end
    for (i = 0; i < 4; i = i+1)
        for (j = 0; j < 4; j = j+1)
            se[i][j] = $urandom_range(0, 20);
    opcode = $urandom_range(1, 4);
    case (opcode)
    0: opcode = HISTOGRAM;
    1: opcode = EROSION;
    2: opcode = DILATION;
    3: opcode = OPENING;
    4: opcode = CLOSING;
    endcase
    op_delay = $urandom_range(0, 15);

    fork
        begin
        for (i1 = 0; i1 < 32; i1 = i1+1) begin
            for (i2 = 0; i2 < 8; i2 = i2+1) begin
                pic_data = {pic[i1][4*i2+3], pic[i1][4*i2+2], pic[i1][4*i2+1], pic[i1][4*i2+0]};
                @(negedge clk);
            end
        end
        end

        begin
        for (j1 = 0; j1 < 4; j1 = j1+1) begin
            for (j2 = 0; j2 < 4; j2 = j2+1) begin
                se_data = se[j1][j2];
                @(negedge clk);
            end
        end
        se_data = 'dx;
        end

        begin
        for (k = 0; k < 16; k = k+1) begin
            if (op_delay == k) begin
                op_valid = 'b1;
                op = opcode;
            end
            else begin
                op_valid = 'd0;
                op = 'dx;
            end
            @(negedge clk);
        end
        op_valid = 'b0;
        op = 'dx;
        end
    join

    in_valid = 'b0;
    op_valid = 'b0;
	op = 'bx;
	pic_data = 'bx;
	se_data = 'bx;
    @(negedge clk);
end endtask

task erosion; begin
    for (i1 = 0; i1 < 32; i1 = i1+1) begin
        for (i2 = 0; i2 < 32; i2 = i2+1) begin
            temp = 255;
            for (j1 = 0; j1 < 4; j1 = j1+1) begin
                for (j2 = 0; j2 < 4; j2 = j2+1) begin
                    if (i1+j1 > 31 || i2+j2 > 31) begin
                        temp = `min(temp, `max(0, 0 - $signed({1'b0, se[j1][j2]})));
                    end
                    else begin
                        temp = `min(temp, `max(0, $signed({1'b0, pic[i1+j1][i2+j2]}) - $signed({1'b0, se[j1][j2]})));
                    end

                end
            end
            pic[i1][i2] = temp;
        end
    end
end endtask

task dilation; begin
    for (i1 = 0; i1 < 32; i1 = i1+1) begin
        for (i2 = 0; i2 < 32; i2 = i2+1) begin
            temp = 0;
            for (j1 = 0; j1 < 4; j1 = j1+1) begin
                for (j2 = 0; j2 < 4; j2 = j2+1) begin
                    if (i1+j1 > 31 || i2+j2 > 31) begin
                        temp = `max(temp, `min(255, 0 + $signed({1'b0, se[~j1[1:0]][~j2[1:0]]})));
                    end
                    else begin
                        temp = `max(temp, `min(255, $signed({1'b0, pic[i1+j1][i2+j2]}) + $signed({1'b0, se[~j1[1:0]][~j2[1:0]]})));
                    end
                end
            end
            pic[i1][i2] = temp;
        end
    end
end endtask

task histogram; begin
    for (k = 0; k < 256; k = k+1) begin
        cdf[k] = 0;
    end
    cdf_min_idx = 255;

    for (i1 = 0; i1 < 32; i1 = i1+1) begin
        for (i2 = 0; i2 < 32; i2 = i2+1) begin
            for (k = 0; k < 256; k = k+1) begin
                if (pic[i1][i2] == k) begin
                    cdf_min_idx = `min(cdf_min_idx, k);
                    cdf[k] = cdf[k]+1;
                end
            end
        end
    end
    for (k = 1; k < 256; k = k+1) begin
        cdf[k] = cdf[k] + cdf[k-1];
    end
    for (i1 = 0; i1 < 32; i1 = i1+1) begin
        for (i2 = 0; i2 < 32; i2 = i2+1) begin
            pic[i1][i2] = (cdf[pic[i1][i2]] - cdf[cdf_min_idx]) * 255 / (1024 - cdf[cdf_min_idx]);
        end
    end
end endtask

task wait_out_valid_task; begin
    latency = 1;
    while(out_valid === 1'b0) begin
        if(latency == 100000) begin
            $display("********************************************************");
            $display("*  The execution latency are over 100000 cycles  at %8t   *",$time);//over max
            $display("********************************************************");
            $finish;
        end
        latency = latency + 1;
        @(negedge clk);
    end
end endtask

task check_ans_task; begin
    wrong = 0;
    out_cnt = 0;
    while (out_valid === 1'b1) begin
        {out_pic[out_cnt/8][4*(out_cnt%8)+3], out_pic[out_cnt/8][4*(out_cnt%8)+2], out_pic[out_cnt/8][4*(out_cnt%8)+1], out_pic[out_cnt/8][4*(out_cnt%8)+0]} = out_data;
        out_cnt = out_cnt +1;
        if (out_cnt > 256) begin
			$display("********************************************************");
            $display("*     out_valid and out_data must be 256 cycles  at %8t   *", $time);//over max
            $display("*          Your out_valid cycle count: %3d          *",out_cnt);//over max
            $display("********************************************************");
            $finish;
        end
        @(negedge clk);
    end
    if (out_cnt < 256) begin
        $display("********************************************************");
        $display("*     out_valid and out_data must be 256 cycles  at %8t   *", $time);//over max
        $display("*          Your out_valid cycle count: %3d          *",out_cnt);//over max
        $display("********************************************************");
        $finish;
    end

    for (i1 = 0; i1 < 32; i1 = i1+1) begin
        for (i2 = 0; i2 < 32; i2 = i2+1) begin
            if (pic[i1][i2] !== out_pic[i1][i2])
                wrong = 1;
        end
    end

    if (wrong) begin
        $display("********************************************************");
        $display("*                    Wrong answer    at %8t    *",$time);
        $display("*  Your answer: ");
        for (i1 = 0; i1 < 32; i1 = i1+1) begin
            for (i2 = 0; i2 < 32; i2 = i2+1) begin
                if (out_pic[i1][i2] !== pic[i1][i2])
                    $write("\033[0;31m%2h\033[m ", out_pic[i1][i2]);
                else
                    $write("%2h ", out_pic[i1][i2]);
                if (i2%4 == 3) $write("|| ");
            end
            $write("\n");
        end
        $display("*  Golden answer: ");
        for (i1 = 0; i1 < 32; i1 = i1+1) begin
            for (i2 = 0; i2 < 32; i2 = i2+1) begin
                if (out_pic[i1][i2] !== pic[i1][i2])
                    $write("\033[0;31m%2h\033[m ", pic[i1][i2]);
                else
                    $write("%2h ", pic[i1][i2]);
                if (i2%4 == 3) $write("|| ");
            end
            $write("\n");
        end
        $display("********************************************************");
        $display("*                    Some Information                  *");
        $display("* \033[0;36mOperation: %s\033[m", print_op(opcode));
        $display("*  Original pic: ");
        for (i1 = 0; i1 < 32; i1 = i1+1) begin
            for (i2 = 0; i2 < 32; i2 = i2+1) begin
                $write("%2h ", orig_pic[i1][i2]);
                if (i2%4 == 3) $write("|| ");
            end
            $write("\n");
        end
        if (opcode == HISTOGRAM) begin
            $display("*  CDF Table  *");
            for (i1 = 0; i1 < 255; i1 = i1+1) begin
                $display("* %3d  %4d  *", i1, cdf[i1]);
            end
            $display("*  CDF_min: %4d *", cdf[cdf_min_idx]);
        end
        else begin
            $display("  SE: ");
            for (j1 = 0; j1 < 4; j1 = j1+1) begin
                for (j2 = 0; j2 < 4; j2 = j2+1) begin
                    $write("%2h ", se[j1][j2]);
                end
                $write("\n");
            end
        end
        $display("********************************************************");
        @(negedge clk);
        @(negedge clk);
        $finish;
    end

    @(negedge clk);
end endtask

task YOU_PASS_task; begin
    $display ("--------------------------------------------------------------------");
    $display ("                         Congratulations!                           ");
    $display ("                  You have passed all patterns!                     ");
    $display ("                  Your execution cycles = %d cycles              ", total_latency + 512*(PAT_NUM-1));
	$display ("                  Your clock period = %.1f ns                     ", CYCLE1);
	$display ("                  Your total latency = %.1f ns                    ", (total_latency + 512*(PAT_NUM-1)) * CYCLE1);
    $display ("--------------------------------------------------------------------");
    $finish;
end endtask

function automatic [71:0] print_op;
input [2:0] opcode;
begin
    case (opcode)
    HISTOGRAM: print_op = "Histogram";
    EROSION: print_op = "Erosion";
    DILATION: print_op = "Dilation";
    OPENING: print_op = "Opening";
    CLOSING: print_op = "Closing";
    endcase
end
endfunction

endmodule