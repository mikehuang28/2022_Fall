//========================================//
//****************************************//
//                                        //
// lab3 pattern by iclab002               //
//                                        //
//****************************************//
//========================================//

`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif

module PATTERN(
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,

  out_valid,
  out
);

output reg       clk, rst_n;
output reg       in_valid;
output reg [2:0] guy;
output reg [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
input            out_valid;
input      [1:0] out;

//-----------------------------------------//
//                   clk                   //
//-----------------------------------------//
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

//-----------------------------------------//
//          integer and parameter          //
//-----------------------------------------//
parameter pat_num = 299; //cannot larger than 300

integer pat_count;
integer gap;
integer guy_temp;
integer step;
integer latency;
integer total_latency;
integer seed = 256;
integer current_x; //current position x
integer current_y; //current position y
integer current_height; //current height

//for input generation
integer platform [0:63][7:0];
integer i, j, k;
integer type; //0: no obstacle, 1: low place obstacle, 2: high place obstacle
integer obs_x; //obstacle x coordinate
integer obs_y; //obstacle y coordinate
integer obs_location;
integer obs_range_max; //range for deciding location of low/high obstacle
integer obs_range_min; //range for deciding location of low/high obstacle
integer row_diff; //difference between current obstacle row and previous obstacle row
integer select; //0: next row all three combo, 1: next row no obstacle only

//-----------------------------------------//
//             wire and register           //
//-----------------------------------------//
reg [1:0] high_to_low; //jump from high to low flag
reg same_height; //jump to same height flag
reg must_fail_0;
//reg [1:0] must_fail_1;

//-----------------------------------------//
//               initial                   //
//-----------------------------------------//
initial begin
  rst_n = 1;
  in_valid = 'b0;
  guy = 'bx;
  in0 = 'bx;
  in1 = 'bx;
  in2 = 'bx;
  in3 = 'bx;
  in4 = 'bx;
  in5 = 'bx;
  in6 = 'bx;
  in7 = 'bx;
  force clk = 0;
  total_latency = 0;

  reset_task; //spec3

  for(pat_count = 0; pat_count < pat_num; pat_count = pat_count + 1) begin
    input_task; //spec4 && spec5
    //compute_ans;
    wait_out_valid_task; //spec4 && spec6
    check_ans_task; //spec8 && spec7
    //check_out_valid_task; //spec7
    $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat_count, latency);
  end
  #(10);
  YOU_PASS_task;
  $finish;
end

//-----------------------------------------//
//                  task                   //
//-----------------------------------------//
//spec3
//reset task
task reset_task; begin
  #(10);
  rst_n = 0;
  #(10);
  if(out_valid !== 0 || out !== 0) begin
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                    SPEC 3 IS FAIL!                                                         ");
		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    $finish;
  end
  #(10);
  rst_n = 1;
  #(3.0);
  release clk;
end
endtask

//spec4 && spec5
//input task
task input_task; begin
  gap = $urandom_range(2,4); //next input 3~5 cycles
	repeat(gap) @(negedge clk);
  in_valid = 'b1;
  guy = $urandom_range(7, 0); //random generate starting position 0~7
  current_x = guy;

  //first cycle must be no obstacle
  in0 = 0;
  in1 = 0;
  in2 = 0;
  in3 = 0;
  in4 = 0;
  in5 = 0;
  in6 = 0;
  in7 = 0;
  for(i = 0; i < 8; i = i + 1) begin
    platform[0][i] = 0;
  end
  @(negedge clk);
  guy = 'bx;

  //initial condition
  obs_x = current_x;
  obs_y = 0;
  obs_range_max = 0;
  obs_range_min = 0;
  row_diff = 0;
  select = $urandom_range(1, 0);
  type = 0;

  //generate legal platform and input
  for(i = 1; i < 64; i = i + 1) begin
    if(select === 0) begin //0: next row all three combo
      type = $urandom_range(2, 0);
      if(type === 0) begin //no obstacle
        select = 0;
        in0 = 0; in1 = 0; in2 = 0; in3 = 0; in4 = 0; in5 = 0; in6 = 0; in7 = 0;
        for(j = 0; j < 8; j = j + 1) begin
          platform[i][j] = 0;
        end
      end

      else begin //type = 1 or 2
        row_diff = i - obs_y;
        for(j = 0; j < 8; j = j + 1) begin //all set full obstacle first and then decide where to put the only exit
          platform[i][j] = 3;
        end
        if(type === 1) begin //low obstacle
          obs_range_max = ((obs_x + row_diff - 1) > 7)? 7: (obs_x + row_diff - 1); //avoid out of boundary
          obs_range_min = ((obs_x - row_diff + 1) < 0)? 0: (obs_x - row_diff + 1); //avoid out of boundary
          obs_location = $urandom_range(obs_range_max, obs_range_min); //decide where to put obstacle
          obs_x = obs_location; //record obstacle position x
          obs_y = i; //record obstacle position y
          platform[i][obs_x] = 1; // replacement
          select = 1;
          case(obs_x) //determine input
          0: begin
            in0 = 1; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          1: begin
            in0 = 3; in1 = 1; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          2: begin
            in0 = 3; in1 = 3; in2 = 1; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          3: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 1; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          4: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 1; in5 = 3; in6 = 3; in7 = 3;
          end
          5: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 1; in6 = 3; in7 = 3;
          end
          6: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 1; in7 = 3;
          end
          7: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 1;
          end
          endcase
        end

        else if(type === 2) begin //high obstacle
          obs_range_max = ((obs_x + row_diff) > 7)? 7: (obs_x + row_diff ); //avoid out of boundary
          obs_range_min = ((obs_x - row_diff) < 0)? 0: (obs_x - row_diff ); //avoid out of boundary
          obs_location = $urandom_range(obs_range_max, obs_range_min); //decide where to put obstacle
          obs_x = obs_location; //record obstacle position x
          obs_y = i; //record obstacle position y
          platform[i][obs_x] = 2; // replacement
          select = 1;
          case(obs_x) //determine input
          0: begin
            in0 = 2; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          1: begin
            in0 = 3; in1 = 2; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          2: begin
            in0 = 3; in1 = 3; in2 = 2; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          3: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 2; in4 = 3; in5 = 3; in6 = 3; in7 = 3;
          end
          4: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 2; in5 = 3; in6 = 3; in7 = 3;
          end
          5: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 2; in6 = 3; in7 = 3;
          end
          6: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 2; in7 = 3;
          end
          7: begin
            in0 = 3; in1 = 3; in2 = 3; in3 = 3; in4 = 3; in5 = 3; in6 = 3; in7 = 2;
          end
          endcase
        end
      end
    end
    else if(select === 1) begin //1: next row no obstacle only
      in0 = 0; in1 = 0; in2 = 0; in3 = 0; in4 = 0; in5 = 0; in6 = 0; in7 = 0;
      for(j = 0; j < 8; j = j + 1) begin
        platform[i][j] = 0;
      end
      select = 0;
    end
    if(out_valid !== 0) begin
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
      $display ("                                                                   SPEC 5 IS FAIL!                                                          ");
      $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
      $display ("                                                 The out_valid should not be high when in_valid is high.                                    ");
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
      $finish;
    end
    if(out !== 0) begin
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
      $display ("                                                                   SPEC 4 IS FAIL!                                                          ");
      $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
      $display ("                                                 The out should be reset when your out_valid is low.                                        ");
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
      $finish;
    end
    @(negedge clk);
  end

  in_valid = 'b0;
  in0 = 'bx;
  in1 = 'bx;
  in2 = 'bx;
  in3 = 'bx;
  in4 = 'bx;
  in5 = 'bx;
  in6 = 'bx;
  in7 = 'bx;
end
endtask

//spec4 && spec6
//wait out_valid task
task wait_out_valid_task; begin
  latency = 0;
  while(out_valid === 0) begin
    if(latency == 3000) begin
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                   SPEC 6 IS FAIL!                                                          ");
			$display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
			$display ("                                                     The execution latency is limited to 3000 cycles.                                       ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$finish;
    end
    if(out !== 0) begin
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
      $display ("                                                                   SPEC 4 IS FAIL!                                                          ");
      $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
      $display ("                                                 The out should be reset when your out_valid is low.                                        ");
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$finish;
    end
    latency = latency + 1;
    repeat(2) @(negedge clk);
  end
  total_latency = latency + total_latency;
end
endtask

//spec7 && spec8
//check_ans_task
task check_ans_task; begin
  current_y = 0;
  current_height = 0;
  high_to_low = 0;
  same_height = 0;
  must_fail_0 = 0;
  step = 0;

    while(out_valid === 1) begin
        if(out === 0) begin //stop
        if(same_height !== 0) begin
            same_height = 0;
            current_height = current_height - 1;
            current_x = current_x;
            current_y = current_y + 1;
        end
        if(must_fail_0 !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                            The guy has to avoid all obstacles.                                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        if(high_to_low === 2) begin
            if(platform[current_y + 1][current_x] === 2 || platform[current_y + 1][current_x] === 3) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                            The guy has to avoid all obstacles.                                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
            end
            else begin
            current_x = current_x;
            current_y = current_y + 1;
            high_to_low = 1;
            current_height = 1;
            end
        end
        else if(high_to_low === 1) begin
            if(platform[current_y + 1][current_x] === 1 || platform[current_y + 1][current_x] === 3) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                            The guy has to avoid all obstacles.                                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
            end
            else begin
            current_x = current_x;
            current_y = current_y + 1;
            high_to_low = 0;
            current_height = 0;
            end
        end
        else if((platform[current_y + 1][current_x] === 1 && current_height === 0) || (platform[current_y + 1][current_x] === 1 && current_height === 1) || (platform[current_y + 1][current_x] === 3)) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                            The guy has to avoid all obstacles.                                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else begin
            current_y = current_y + 1;
            current_x = current_x;
            current_height = 0;
        end
        end

        else if(out === 1) begin //right
        if(same_height !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-3 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                           If the guy jumps to the same height, out must be 0 for 1 cycle.                                  ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if(must_fail_0 !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-3 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                           If the guy jumps to the same height, out must be 0 for 1 cycle.                                  ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if(high_to_low !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-2 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                           If the guy jumps from high to low place, out must be 0 for 2 cycles.                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if((current_x + 1) === 8) begin // out of boundary
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                           The guy cannot leave the platform.                                               ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if((platform[current_y + 1][current_x + 1] === 1 && current_height === 0) || (platform[current_y + 1][current_x + 1] === 1 && current_height === 1) || (platform[current_y + 1][current_x + 1] === 3)) begin //bump into obstacle
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                            The guy has to avoid all obstacles.                                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else begin
            current_x = current_x + 1;
            current_y = current_y + 1;
            if(current_height === 0) begin
            current_height = 0;
            end
            else begin
            current_height = current_height - 1;
            end
        end
        end

        else if(out === 2) begin //left
        if(same_height !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-3 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                           If the guy jumps to the same height, out must be 0 for 1 cycle.                                  ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if(must_fail_0 !== 0 ) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-3 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                           If the guy jumps to the same height, out must be 0 for 1 cycle.                                  ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if(high_to_low !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-2 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                           If the guy jumps from high to low place, out must be 0 for 2 cycles.                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if((current_x - 1) === -1) begin // out of boundary
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                           The guy cannot leave the platform.                                               ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if((platform[current_y + 1][current_x - 1] === 1 && current_height === 0) || (platform[current_y + 1][current_x - 1] === 1 && current_height === 1) || (platform[current_y + 1][current_x - 1] === 3)) begin //bump into obstacle
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                            The guy has to avoid all obstacles.                                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else begin
            current_x = current_x - 1;
            current_y = current_y + 1;
            if(current_height === 0) begin
            current_height = 0;
            end
            else begin
            current_height = current_height - 1;
            end
        end
        end

        else if(out === 3) begin //jump
        if(high_to_low !== 0 || same_height !== 0 || must_fail_0 !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-3 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                    This spec is failed due to spec highest priority.                                       ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else if((platform[current_y + 1][current_x] === 2 && current_height === 0) || (platform[current_y + 1][current_x] === 3 && current_height === 0)) begin //bump into obstacle
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                  SPEC 8-1 IS FAIL!                                                         ");
            $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
            $display ("                                                            The guy has to avoid all obstacles.                                             ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        else begin
            if(((platform[current_y + 2][current_x] === 0 || platform[current_y + 2][current_x] === 2) && platform[current_y + 1][current_x] === 0 && (platform[current_y][current_x] === 0 || platform[current_y][current_x] === 2) && current_height === 0) || (platform[current_y + 2][current_x] === 1 && platform[current_y][current_x] === 1 && current_height === 1)) begin //jump to same height
            //101 000 200 202
            same_height = 1;
            current_height = current_height + 1;
            current_y = current_y + 1;
            current_x = current_x;
            end
            else if(platform[current_y][current_x] === 1 && current_height === 1 && platform[current_y + 2][current_x] === 0) begin //jump from high to low
            //100
            high_to_low = 2;
            current_height = current_height + 1;
            current_y = current_y + 1;
            current_x = current_x;
            end
            else if((current_height === 0 && (platform[current_y][current_x] === 2 || platform[current_y][current_x] === 0) && platform[current_y + 1][current_x] === 0 && (platform[current_y + 2][current_x] === 1 || platform[current_y + 2][current_x] === 3)) || (current_height == 1 && platform[current_y][current_x] === 1 && (platform[current_y + 2][current_x] === 2 || platform[current_y + 2][current_x] === 3))) begin //must fail 0
            //001 003 201 203 102 103
            must_fail_0 = 1;
            current_height = current_height + 1;
            current_y = current_y + 1;
            current_x = current_x;
            end
            else begin
            same_height = 0;
            high_to_low = 0;
            must_fail_0 = 0;
            //must_fail_1 = 0;
            current_y = current_y + 1;
            current_x = current_x;
            current_height = current_height + 1;
            end
        end
        end

        step = step + 1;
        @(negedge clk);
    end
    if(step !== 63) begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                   SPEC 7 IS FAIL!                                                          ");
                $display ("                                                                   Pattern NO. %3d                                                          ", pat_count);
                $display ("                                            The out_valid and out must be asserted successively in 63 cycles.                               ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $finish;
    end
    repeat(2) @(negedge clk);
end
endtask

task YOU_PASS_task; begin
  $display ("------------------------------------------------------------------------------------------------------------------------------------------------");
	$display ("                                                                 Congratulations!                						                                   ");
	$display ("                                                           You have passed all patterns!          						                                   ");
	$display ("                                                           Your execution cycles = %5d cycles   						                                     ", total_latency);
	$display ("                                                           Your clock period = %.1f ns        					                                         ", `CYCLE_TIME);
	$display ("                                                           Your total latency = %.1f ns         						                                     ", total_latency * `CYCLE_TIME);
	$display ("------------------------------------------------------------------------------------------------------------------------------------------------");
	$finish;
end
endtask

endmodule