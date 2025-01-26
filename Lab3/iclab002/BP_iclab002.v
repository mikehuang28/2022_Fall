module BP(
  //input
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

  //output
  out_valid,
  out
);

input             clk, rst_n;
input             in_valid;
input       [2:0] guy;
input       [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg        out_valid;
output reg  [1:0] out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE = 0;
parameter INPUT = 1;
parameter CAL = 2;

integer i;

//==============================================//
//            Register Declaration              //
//==============================================//
reg [1:0] next_state, current_state;
reg [2:0] guy_reg;
reg [2:0] start_pos;
reg [5:0] y_diff [31:0]; //maximum 32 obstacles
reg [2:0] x_diff [31:0];
reg left_or_right [31:0]; //0: right, 1: left
reg obs_type [31:0]; //0: low obstacle, 1: high obstacle

reg [2:0] cur_obs_x;
reg [5:0] cur_obs_y;
reg [2:0] pre_obs_x;
reg [5:0] pre_obs_y;

reg [5:0] row_count;
reg [5:0] out_valid_count;
reg [5:0] obs_count;
reg [5:0] diff_count;
reg [5:0] step_count;

//==============================================//
//              Wire Declaration                //
//==============================================//
wire [5:0] row_diff; //difference of y between two obstacles
wire [3:0] obs_diff; //difference of x (may be (-))
wire [2:0] obs_diff_abs; // after absolute value

//==============================================//
//             Current State Block              //
//==============================================//

always@ (posedge clk or negedge rst_n) begin
  if(!rst_n)
    current_state <= IDLE; /* initial state */
  else
    current_state <= next_state;
end

//==============================================//
//              Next State Block                //
//==============================================//

always@ (*) begin
  case(current_state)
  IDLE: begin
    if(in_valid)
      next_state = INPUT;
    else
      next_state = IDLE;
  end
  INPUT: begin
    if(!in_valid)
      next_state = CAL;
    else
      next_state = INPUT;
  end
  CAL: begin
    if(out_valid_count == 63)
      next_state = IDLE;
    else
      next_state = CAL;
  end
  default: next_state = current_state;
  endcase
end

//==============================================//
//                 Input Block                  //
//==============================================//

//y diff
always@ (posedge clk) begin
    if(current_state == IDLE) begin
      for(i = 0; i < 32; i = i + 1) begin
        y_diff[i] <= 0;
      end
    end
    else if(in_valid || obs_count > 0) begin
      y_diff[obs_count - 1] <= row_diff;
    end
    else begin
      for(i = 0; i < 32; i = i + 1) begin
        y_diff[i] <= y_diff[i];
      end
    end
end

//x diff
always@ (posedge clk) begin
    if(current_state == IDLE) begin
      for(i = 0; i < 32; i = i + 1) begin
        x_diff[i] <= 0;
      end
    end
    else if(in_valid || obs_count > 0) begin
      x_diff[obs_count - 1] <= obs_diff_abs;
    end
    else begin
      for(i = 0; i < 32; i = i + 1) begin
        x_diff[i] <= x_diff[i];
      end
    end
end

//left or right
always@ (posedge clk) begin
    if(current_state == IDLE) begin
      for(i = 0; i < 32; i = i + 1) begin
        left_or_right[i] <= 0;
      end
    end
    else if(in_valid || obs_count > 0) begin
      if(obs_diff[3]) begin //left
        left_or_right[obs_count - 1] <= 1;
      end
      else begin //right
        left_or_right[obs_count - 1] <= 0;
      end
    end
    else begin
      for(i = 0; i < 32; i = i + 1) begin
        left_or_right[i] <= left_or_right[i];
      end
    end
end

//obstacle type
always@ (posedge clk) begin
    if(current_state == IDLE) begin
      for(i = 0; i < 32; i = i + 1) begin
        obs_type[i] <= 0;
      end
    end
    else if(in_valid || obs_count > 0) begin
      if(in0 == 2 || in1 == 2 || in2 == 2 || in3 == 2 || in4 == 2 || in5 == 2 || in6 == 2 || in7 == 2) begin //high
        obs_type[obs_count ] <= 1;
      end
      else if(in0 == 1 || in1 == 1 || in2 == 1 || in3 == 1 || in4 == 1 || in5 == 1 || in6 == 1 || in7 == 1) begin //low
        obs_type[obs_count ] <= 0;
      end
    end
end

//==============================================//
//                    Counter                   //
//==============================================//

//row_count
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    row_count <= 0;
  end
  else begin
    if(in_valid) begin
      row_count <= row_count + 1;
    end
    else if(current_state == CAL) begin
      row_count <= row_count;
    end
    else begin
      row_count <= row_count;
    end
  end
end

//out_valid_count
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    out_valid_count <= 0;
  end
  else begin
    if(current_state == IDLE) begin
      out_valid_count <= 0;
    end
    if(current_state == CAL) begin
      out_valid_count <= out_valid_count + 1;
    end
    else begin
      out_valid_count <= out_valid_count;
    end
  end
end

//obstacle count
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    obs_count <= 0;
  end
  else begin
    if(current_state == IDLE) begin
      obs_count <= 0;
    end
    else if(current_state == INPUT && in_valid && in0 != 0) begin
      obs_count <= obs_count + 1;
    end
    else begin
      obs_count <= obs_count;
    end
  end
end

//step count
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    step_count <= 0;
  end
  else begin
    if(current_state == CAL) begin
      if(step_count == y_diff[diff_count] - 1) begin
        step_count <= 0;
      end
      else begin
        step_count <= step_count + 1;
      end
    end
    else begin
      step_count <= 0;
    end
  end
end

//diff count
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    diff_count <= 0;
  end
  else begin
    if(current_state == CAL) begin
      if(step_count == y_diff[diff_count] - 1) begin
        diff_count <= diff_count + 1;
      end
      else begin
        diff_count <= diff_count;
      end
    end
    else begin
      diff_count <= 0;
    end
  end
end

//==============================================//
//              Obstacle location               //
//==============================================//

//current obstacle_x
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    cur_obs_x <= 0;
  end
  else begin
    if(current_state == IDLE) begin
      cur_obs_x <= guy;
    end
    else if(current_state == INPUT && in_valid && in0 != 0) begin
        if(in0 != 3) cur_obs_x <= 0;
        else if(in1 != 3) cur_obs_x <= 1;
        else if(in2 != 3) cur_obs_x <= 2;
        else if(in3 != 3) cur_obs_x <= 3;
        else if(in4 != 3) cur_obs_x <= 4;
        else if(in5 != 3) cur_obs_x <= 5;
        else if(in6 != 3) cur_obs_x <= 6;
        else cur_obs_x <= 7;
    end
    else begin
      cur_obs_x <= cur_obs_x;
    end
  end
end

//current obstacle_y
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    cur_obs_y <= 0;
  end
  else begin
    if(current_state == IDLE) begin
      cur_obs_y <= 0;
    end
    else if(current_state == INPUT && in_valid && in0 != 0) begin
      if(row_count == 0) begin
        cur_obs_y <= 0;
      end
      else begin
        cur_obs_y <= row_count;
      end
    end
    else begin
      cur_obs_y <= cur_obs_y;
    end
  end
end

//previous obstacle_x
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    pre_obs_x <= 0;
  end
  else begin
    if(current_state == IDLE) begin
      pre_obs_x <= 0;
    end
    else if(current_state == INPUT && in_valid && in0 != 0 /*&& (row_count > cur_obs_y)*/) begin
      pre_obs_x <= cur_obs_x;
    end
    else begin
      pre_obs_x <= pre_obs_x;
    end
  end
end

//previous obstacle_y
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    pre_obs_y <= 0;
  end
  else begin
    if(current_state == IDLE) begin
      pre_obs_y <= 0;
    end
    else if(current_state == INPUT && in_valid && in0 != 0  /*&& (row_count > cur_obs_y)*/) begin
      pre_obs_y <= cur_obs_y;
    end
    else begin
      pre_obs_y <= pre_obs_y;
    end
  end
end

//==============================================//
//                  Navigation                  //
//==============================================//

assign row_diff = cur_obs_y - pre_obs_y;
assign obs_diff = cur_obs_x - pre_obs_x;
assign obs_diff_abs = (obs_diff[2:0] ^ {3{obs_diff[3]}}) + obs_diff[3];

//==============================================//
//                 Output Block                 //
//==============================================//

//output logic
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    out <= 0;
  end
  else begin
    if(current_state == CAL) begin
      if(x_diff[diff_count] != 0) begin //not go straight
        if(left_or_right[diff_count] == 0) begin //right
          if(step_count >= x_diff[diff_count]) begin //go straight from then on
            if(step_count == y_diff[diff_count] - 1 && obs_type[diff_count] == 0) begin
              //$display("3");
              out <= 3;
            end
            else if(step_count == y_diff[diff_count] - 1 && obs_type[diff_count] == 1) begin //a step before obstacle && high obstacle
              //$display("0");
              out <= 0;
            end
            else begin
              //$display("0");
              out <= 0;
            end
          end
          else begin
            //$display("1");
            out <= 1;
          end
        end
        else begin //left
          if(step_count >= x_diff[diff_count]) begin //go straight from then on
            if(step_count == y_diff[diff_count] - 1 && obs_type[diff_count] == 0) begin
              //$display("3");
              out <= 3;
            end
            else if(step_count == y_diff[diff_count] - 1 && obs_type[diff_count] == 1) begin //a step before obstacle && high obstacle
              //$display("0");
              out <= 0;
            end
            else begin
              //$display("0");
              out <= 0;
            end
          end
          else begin
            //$display("2");
            out <= 2;
          end
        end
      end
      else begin //x diff is 0 between obstacles-> go straight
        if(step_count == y_diff[diff_count] - 1 && obs_type[diff_count] == 0) begin //a step before obstacle && low obstacle
          //$display("3");
          out <= 3;
        end
        else if(step_count == y_diff[diff_count] - 1 && obs_type[diff_count] == 1) begin //a step before obstacle && high obstacle
          //$display("0");
          out <= 0;
        end
        else begin
          //$display("0");
          out <= 0;
        end
      end
    end
    else begin
      out <= 0;
    end
  end
end

//out_valid
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    out_valid <= 0;
  end
  else begin
    if(current_state == CAL) begin
      if(out_valid_count == 63) begin
        out_valid <= 0;
      end
      else begin
        out_valid <= 1;
      end
    end
    else begin
      out_valid <= 0;
    end
  end
end


endmodule

