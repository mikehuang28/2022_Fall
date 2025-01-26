`define DEBUG_MODE 1
`define PATNUMBER  5000
`define CYCLE_TIME 15


//##############################################################
//--------------------------------------------------------------
// PATTERN.v without clk gating
//--------------------------------------------------------------
//##############################################################

module PATTERN(
	// Output signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Input signals
	out_valid,
	out_data
);

output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [8:0] in_data;
output reg [2:0] in_mode;

input out_valid;
input signed [9:0] out_data;

//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
parameter PAT_NUM = `PATNUMBER;
integer pat_i;
integer total_latency;
integer latency;
integer debug = `DEBUG_MODE;

//================================================================
// wire & registers
//================================================================
reg [2:0] mode;
reg signed [8:0] data [0:8];
reg signed [9:0] answer [0:2]; // max -> mid -> min

always #(CYCLE/2.0) clk = ~clk;

initial begin
	total_latency = 0;
	clk = 0;
	in_valid = 0;
	rst_n = 1;
	cg_en = 0;
	reset_task;

	@(negedge clk);
	for(pat_i=0; pat_i<PAT_NUM; pat_i=pat_i+1) begin
		gen_input_data;
		input_task;
		cal_golden_answer;
		weight_out_valid;
		check_ans_task;
	end
	U_PASS_TASK;
	$finish;
end

always@(negedge clk) begin
	if(out_valid!==0 && in_valid===1) begin
		$display("\033[0;31m=====================================================================\033[m");
		$display("\033[0;31m             out_valid shold not overlap with in_valid               \033[m");
		$display("\033[0;31m=====================================================================\033[m");
		$finish;
	end
end

task gen_input_data;
	integer i, j;
	begin
		mode = $urandom_range(0, 7);
		//mode = 7;
		for(i=0;i<9;i=i+1) begin
			data[i] = $random();
		end
	end
endtask

task cal_golden_answer;
	integer i ,j;
	integer max, min;
	integer diff, mid;
	integer temp_2;
	reg signed [8:0] temp;
	reg signed [9:0] data_10bit [0:8];
	reg signed [9:0] data_10bit_2 [0:8];

	begin
		if(debug) begin
			$display("\033[0;35m\n>>> PATTERN %0d - DEBUG MODE\033[m", pat_i);
			$display("\033[0;35m===========================================================================\033[m");
			$display("");
			$display("\033[0;33mOriginal input :\033[m");
			for(i=0;i<9;i=i+1) begin
				$write("%4d  ", data[i]);
			end
			$display("");
			$display("");
		end
		// ----------------------------- Convert gray code to binary
		if(mode[0] == 1) begin
			for(i=0;i<9;i=i+1) begin
				for(j=7;j>=0;j=j-1) begin
					if(j==7) begin
						temp[8] = 0;
						temp[7] = data[i][j];
					end
					else begin
						temp[j] = temp[j+1] ^ data[i][j];
					end
				end
				if(data[i][8] == 1) begin
					data[i] = temp * (-1);
				end
				else begin
					data[i]= temp;
				end
			end
		end
		if(debug) begin
			$display("\033[0;33mAfter mode[0] :\033[m");
			for(i=0;i<9;i=i+1) begin
				$write("%4d  ", data[i]);
			end
			$display(", min = %0d, max = %0d", min, max);
			$display("");
		end
		// ------------------------------- Find MAX and min and do +/- half of difference
		if(mode[1]) begin
			max = -256;
			min = 255;
			for(i=0;i<9;i=i+1) begin
				if(min > data[i]) min = data[i];
				if(max < data[i]) max = data[i];
			end
			diff = (max-min)/2;
			mid  = (max+min)/2;
			for(i=0;i<9;i=i+1) begin
				if(data[i] > mid) data_10bit[i] = data[i] - diff;
				else if(data[i] < mid) data_10bit[i] = data[i] + diff;
				else data_10bit[i] = data[i];
			end
		end
		else begin
			for(i=0;i<9;i=i+1) begin
				data_10bit[i] = data[i];
			end
		end
		if(debug) begin
			$display("\033[0;33mAfter mode[1] :\033[m");
			for(i=0;i<9;i=i+1) begin
				$write("%4d  ", data_10bit[i]);
			end
			$display("");
			$display("");
		end

		// ------------------------------- Do SMA
		if(mode[2]) begin
			for(i=0;i<9;i=i+1) begin
				if(i==0) begin
					temp_2 = data_10bit[8] + data_10bit[i] + data_10bit[i+1];
				end
				else if(i==8) begin
					temp_2 = data_10bit[i-1] + data_10bit[i] + data_10bit[0];
				end
				else begin
					temp_2 = data_10bit[i-1] + data_10bit[i] + data_10bit[i+1];
				end
				data_10bit_2[i] = temp_2 / 3;
			end
		end
		else begin
			for(i=0;i<9;i=i+1) begin
				data_10bit_2[i] = data_10bit[i];
			end
		end
		if(debug) begin
			$display("\033[0;33mAfter mode[2] :\033[m");
			for(i=0;i<9;i=i+1) begin
				$write("%4d  ", data_10bit_2[i]);
			end
			$display("");
			$display("");
		end

		// ------------------------------- Do sort
		for(i=0;i<9;i=i+1) begin
			for(j=0;j<8-i;j=j+1) begin
				if(data_10bit_2[j] > data_10bit_2[j+1]) begin
					temp = data_10bit_2[j];
					data_10bit_2[j] = data_10bit_2[j+1];
					data_10bit_2[j+1] = temp;
				end
			end
		end
		if(debug) begin
			$display("\033[0;33mAfter sorting :\033[m");
			for(i=0;i<9;i=i+1) begin
				$write("%4d  ", data_10bit_2[i]);
			end
			$display("");
			$display("");
			$display("\033[0;35m===========================================================================\033[m");
		end

		answer[0] = data_10bit_2[8];
		answer[1] = data_10bit_2[4];
		answer[2] = data_10bit_2[0];
 	end
endtask

task reset_task;
    begin
        force clk = 0;
        #CYCLE; rst_n = 0;
        #CYCLE; rst_n = 1;
        if(out_valid!==0 || out_data!==10'b0) begin
            $display("=====================");
            $display("     RESET FAIL!     ");
            $display("=====================");
            $finish;
        end
        #CYCLE; release clk;
    end
endtask

task input_task;
	integer i;
	begin
		in_valid = 1;
		for(i=0;i<9;i=i+1) begin
			if(i==0) in_mode = mode;
			else in_mode = 'bx;
			in_data = data[i];
			@(negedge clk);
		end
		in_valid = 0;
		in_data = 'bx;
		in_mode = 'bx;
	end
endtask

task weight_out_valid;
    begin
        latency = 0;
        while(out_valid!==1) begin
            latency = latency + 1;
            if(latency > 1000) begin
                $display("==========================================");
                $display("                   FAIL!                  ");
                $display("         Latency OVER 1000 cycles         ");
                $display("==========================================");
                $finish;
            end
            @(negedge clk);
        end
    end
endtask

task check_ans_task;
	integer output_cycle_cnt;
    begin
        output_cycle_cnt = 0;
        while(out_valid === 1) begin
            if(output_cycle_cnt > 3) begin
                $display("\033[0;31m===================================================\033[m");
                $display("\033[0;31m             out_valid over 3 cycles               \033[m");
                $display("\033[0;31m===================================================\033[m");
                $finish;
            end
            if(out_data !== answer[output_cycle_cnt]) begin
                $display("");
                $display("\033[0;31m=========================================\033[m");
                $display("\033[0;31m             WRONG ANSWER !              \033[m");
                $display("\033[0;31m=========================================\033[m");
                $display("");
                $display("\033[0;33m>>>> PATTERN %d\033[m , mode = %3b", pat_i, mode);
                $display("-----------------------------------------------------------------\n");
                $display("     GOLDEN ANSWER :              ");
                $display("        MAXimum =  %0d     ", answer[0]);
                $display("        medium  =  %0d     ", answer[1]);
                $display("        minimum =  %0d     ", answer[2]);
                $display("");
                $finish;
            end

            output_cycle_cnt = output_cycle_cnt + 1;
            @(negedge clk);
        end
        if(output_cycle_cnt < 3) begin
            $display("\033[0;31m=============================================================================\033[m");
            $display("\033[0;31m             out_valid shold be high in 3 cycles continuously               \033[m");
            $display("\033[0;31m=============================================================================\033[m");
            $finish;
        end
        $display("\033[0;36m PATTERN - %d\033[m \033[0;32mIS CORRECT !\033[m , \033[0;33mLatency = %2d\033[m , in_mode = %2d (%b%b%b)", pat_i, latency, mode, mode[2], mode[1], mode[0]);
        total_latency = latency + total_latency;

    end
endtask

task U_PASS_TASK;
    begin
        $display("");
        $display("");
        $display("\033[1;32m======================================================\033[m");
        $display("\033[0;32m                                                      \033[m");
        $display("\033[1;32m                  Simulation SUCCESS                  \033[m");
        $display("\033[0;32m                                                      \033[m");
        $display("\033[1;32m                YOU PASS ALL PATTERNS !               \033[m");
        $display("\033[0;32m                                                      \033[m");
        $display("\033[0;33m           Total Latency =  %d cycles                 \033[m", total_latency);
        $display("\033[0;32m                                                      \033[m");
        $display("\033[1;32m======================================================\033[m");
        $finish;
    end
endtask

endmodule
