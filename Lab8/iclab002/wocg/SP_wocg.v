module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

//========================================================
// Input and Output Declaration
//========================================================
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output reg 		  out_valid;
output reg signed [9:0] out_data;

//========================================================
// Parameter Declaration
//========================================================
parameter IDLE = 0;
parameter INPUT = 1;
parameter ADD = 2;
parameter SMA = 3;
parameter OUTPUT = 4;
parameter EXE = 6;
parameter DONE = 7;

integer i;
//========================================================
// Register and Wire Declaration
//========================================================
reg [2:0] current_state, next_state;
reg [2:0] in_mode_reg;
wire [2:0] in_mode_temp;
wire [8:0] temp;
reg [7:0] gray_code;
reg signed [8:0] in_data_temp;
reg signed [8:0] in_data_reg [8:0];
reg signed [8:0] add_sub_reg [8:0];
reg signed [8:0] sma_reg [8:0];
reg signed [8:0] max;
reg signed [8:0] min;
wire [9:0] half_of_difference;
wire signed [9:0] midpoint;
reg [3:0] count;
// reg [79:0] extra_count;
// reg [79:0] alter_count;

reg signed [8:0] sort_row_0 [0:2];
reg signed [8:0] sort_row_1 [0:2];
reg signed [8:0] sort_row_2 [0:2];
reg signed [8:0] sort_col_0 [0:2];
reg signed [8:0] sort_col_1 [0:2];
reg signed [8:0] sort_col_2 [0:2];
reg signed [8:0] sort_dia [0:2];
reg signed [9:0] out_data_median;
reg signed [9:0] out_data_min;
reg signed [9:0] out_data_min_1;

//========================================================
// Finite State Machine
//========================================================
//current_state
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n)
    	current_state <= IDLE;
 	else
    	current_state <= next_state;
end

//next state comb logic
always@ (*) begin
	case(current_state)
	IDLE: begin
		if(in_valid)
			next_state = INPUT;
		else
			next_state = IDLE;
	end
	INPUT: begin
		if(in_valid)
			next_state = INPUT;
		else if(!in_mode_reg[2]) //no add sub && no sma
			next_state = OUTPUT;
		else
			next_state = SMA;
	end
	SMA: begin
		next_state = OUTPUT;
	end
	OUTPUT: begin
		if(count == 2)
			next_state = IDLE;
		else
			next_state = OUTPUT;
	end
	default: next_state = current_state;
	endcase
end

//========================================================
// Input Block && Counter
//========================================================
assign in_mode_temp = (current_state == IDLE && in_valid) ? in_mode : in_mode_reg;
assign temp = (in_valid) ? in_data : 0;

//in_mode_reg
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_mode_reg <= 0;
	end
	else begin
		if(in_valid && current_state == IDLE) begin
			in_mode_reg <= in_mode;
		end
		else if(current_state == OUTPUT && next_state == IDLE)begin
			in_mode_reg <= 0;
		end
	end
end

//gray_code
always@ (*) begin
	if(in_mode_temp[0]) begin //gray code
		gray_code[7] = temp[7];
		gray_code[6] = temp[6] ^ gray_code[7];
		gray_code[5] = temp[5] ^ gray_code[6];
		gray_code[4] = temp[4] ^ gray_code[5];
		gray_code[3] = temp[3] ^ gray_code[4];
		gray_code[2] = temp[2] ^ gray_code[3];
		gray_code[1] = temp[1] ^ gray_code[2];
		gray_code[0] = temp[0] ^ gray_code[1];
	end
	else begin
		gray_code = 0;
	end
end

//in_data_temp
always@ (*) begin
	if(in_mode_temp[0]) begin //gray code
		if(temp == 9'b100000000) begin //special case
			in_data_temp = 0;
		end
		else if(temp[8]) begin //<0
			in_data_temp = ~gray_code + 1;
		end
		else begin
			in_data_temp = gray_code;
		end
	end
	else begin //normal signed
		in_data_temp = temp;
	end

end

//in_data_reg
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 9; i = i + 1) begin
			in_data_reg[i] <= 0;
		end
	end
	else begin
		if(in_valid) begin
			in_data_reg[count] <= in_data_temp;
		end
	end
end

//add_sub_reg
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 9; i = i + 1) begin
			add_sub_reg[i] <= 0;
		end
	end
	else begin
		if(current_state == INPUT && in_mode_reg[1]) begin
			for(i = 0; i < 9; i = i + 1) begin
				if(in_data_reg[i] > midpoint) begin //substract
					add_sub_reg[i] <= in_data_reg[i] - half_of_difference;
				end
				else if(in_data_reg[i] < midpoint) begin //add
					add_sub_reg[i] <= in_data_reg[i] + half_of_difference;
				end
				else begin //do nothing
					add_sub_reg[i] <= in_data_reg[i];
				end
			end
		end
	end
end

//sma_reg
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 9; i = i + 1) begin
			sma_reg[i] <= 0;
		end
	end
	else begin
		if(current_state == SMA) begin
			if(in_mode_reg[1]) begin //from add sub
				sma_reg[0] <= (add_sub_reg[8] + add_sub_reg[0] + add_sub_reg[1]) / 3;
				sma_reg[1] <= (add_sub_reg[0] + add_sub_reg[1] + add_sub_reg[2]) / 3;
				sma_reg[2] <= (add_sub_reg[1] + add_sub_reg[2] + add_sub_reg[3]) / 3;
				sma_reg[3] <= (add_sub_reg[2] + add_sub_reg[3] + add_sub_reg[4]) / 3;
				sma_reg[4] <= (add_sub_reg[3] + add_sub_reg[4] + add_sub_reg[5]) / 3;
				sma_reg[5] <= (add_sub_reg[4] + add_sub_reg[5] + add_sub_reg[6]) / 3;
				sma_reg[6] <= (add_sub_reg[5] + add_sub_reg[6] + add_sub_reg[7]) / 3;
				sma_reg[7] <= (add_sub_reg[6] + add_sub_reg[7] + add_sub_reg[8]) / 3;
				sma_reg[8] <= (add_sub_reg[7] + add_sub_reg[8] + add_sub_reg[0]) / 3;
			end
			else begin //from no add sub
				sma_reg[0] <= (in_data_reg[8] + in_data_reg[0] + in_data_reg[1]) / 3;
				sma_reg[1] <= (in_data_reg[0] + in_data_reg[1] + in_data_reg[2]) / 3;
				sma_reg[2] <= (in_data_reg[1] + in_data_reg[2] + in_data_reg[3]) / 3;
				sma_reg[3] <= (in_data_reg[2] + in_data_reg[3] + in_data_reg[4]) / 3;
				sma_reg[4] <= (in_data_reg[3] + in_data_reg[4] + in_data_reg[5]) / 3;
				sma_reg[5] <= (in_data_reg[4] + in_data_reg[5] + in_data_reg[6]) / 3;
				sma_reg[6] <= (in_data_reg[5] + in_data_reg[6] + in_data_reg[7]) / 3;
				sma_reg[7] <= (in_data_reg[6] + in_data_reg[7] + in_data_reg[8]) / 3;
				sma_reg[8] <= (in_data_reg[7] + in_data_reg[8] + in_data_reg[0]) / 3;
			end
		end
	end
end

//count
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 0;
	end
	else begin
		if(in_valid) begin
			count <= count + 1;
		end
		else if(current_state == IDLE) begin
			count <= 0;
		end
		else if(current_state == INPUT && next_state == OUTPUT) begin
			count <= 0;
		end
		else if(current_state == INPUT && next_state == ADD) begin
			count <= 0;
		end
		else if(current_state == INPUT && next_state == SMA) begin
			count <= 0;
		end
		else if(current_state == ADD && next_state == OUTPUT) begin
			count <= 0;
		end
		else if(current_state == SMA && next_state == OUTPUT) begin
			count <= 0;
		end
		else if(current_state == OUTPUT) begin
			count <= count + 1;
		end
	end
end

//========================================================
// Find Min && Max
//========================================================
assign half_of_difference = (max - min) / 2;
assign midpoint = (max + min) / 2;

//find max
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		max <= -256;
	end
	else begin
		//if(next_state == INPUT) begin
			if(max < in_data_temp) begin
				max <= in_data_temp;
			end
		//end
		else if(current_state == IDLE) begin //reset
			max <= -256;
		end

	end
end

//find min
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		min <= 255;
	end
	else begin
		//if(next_state == INPUT) begin
			if(min > in_data_temp) begin
				min <= in_data_temp;
			end
		//end
		else if(current_state == IDLE) begin //reset
			min <= 255;
		end
	end
end

//========================================================
// Find Median
//========================================================
//row0
always@ (*) begin
	if(!in_mode_reg[2] && !in_mode_reg[1]) begin //000 001
		if(in_data_reg[0] >= in_data_reg[1] && in_data_reg[1] >= in_data_reg[2]) begin //012
			sort_row_0[0] = in_data_reg[0];
			sort_row_0[1] = in_data_reg[1];
			sort_row_0[2] = in_data_reg[2];
		end
		else if(in_data_reg[0] >= in_data_reg[2] && in_data_reg[2] >= in_data_reg[1]) begin //021
			sort_row_0[0] = in_data_reg[0];
			sort_row_0[1] = in_data_reg[2];
			sort_row_0[2] = in_data_reg[1];
		end
		else if(in_data_reg[1] >= in_data_reg[0] && in_data_reg[0] >= in_data_reg[2]) begin //102
			sort_row_0[0] = in_data_reg[1];
			sort_row_0[1] = in_data_reg[0];
			sort_row_0[2] = in_data_reg[2];
		end
		else if(in_data_reg[1] >= in_data_reg[2] && in_data_reg[2] >= in_data_reg[0]) begin //120
			sort_row_0[0] = in_data_reg[1];
			sort_row_0[1] = in_data_reg[2];
			sort_row_0[2] = in_data_reg[0];
		end
		else if(in_data_reg[2] >= in_data_reg[0] && in_data_reg[0] >= in_data_reg[1]) begin //201
			sort_row_0[0] = in_data_reg[2];
			sort_row_0[1] = in_data_reg[0];
			sort_row_0[2] = in_data_reg[1];
		end
		else begin //210
			sort_row_0[0] = in_data_reg[2];
			sort_row_0[1] = in_data_reg[1];
			sort_row_0[2] = in_data_reg[0];
		end
	end
	else if(in_mode_reg[1] && !in_mode_reg[2]) begin //010 011
		if(add_sub_reg[0] >= add_sub_reg[1] && add_sub_reg[1] >= add_sub_reg[2]) begin //012
			sort_row_0[0] = add_sub_reg[0];
			sort_row_0[1] = add_sub_reg[1];
			sort_row_0[2] = add_sub_reg[2];
		end
		else if(add_sub_reg[0] >= add_sub_reg[2] && add_sub_reg[2] >= add_sub_reg[1]) begin //021
			sort_row_0[0] = add_sub_reg[0];
			sort_row_0[1] = add_sub_reg[2];
			sort_row_0[2] = add_sub_reg[1];
		end
		else if(add_sub_reg[1] >= add_sub_reg[0] && add_sub_reg[0] >= add_sub_reg[2]) begin //102
			sort_row_0[0] = add_sub_reg[1];
			sort_row_0[1] = add_sub_reg[0];
			sort_row_0[2] = add_sub_reg[2];
		end
		else if(add_sub_reg[1] >= add_sub_reg[2] && add_sub_reg[2] >= add_sub_reg[0]) begin //120
			sort_row_0[0] = add_sub_reg[1];
			sort_row_0[1] = add_sub_reg[2];
			sort_row_0[2] = add_sub_reg[0];
		end
		else if(add_sub_reg[2] >= add_sub_reg[0] && add_sub_reg[0] >= add_sub_reg[1]) begin //201
			sort_row_0[0] = add_sub_reg[2];
			sort_row_0[1] = add_sub_reg[0];
			sort_row_0[2] = add_sub_reg[1];
		end
		else begin //210
			sort_row_0[0] = add_sub_reg[2];
			sort_row_0[1] = add_sub_reg[1];
			sort_row_0[2] = add_sub_reg[0];
		end
	end
	else begin //100 101 110 111
		if(sma_reg[0] >= sma_reg[1] && sma_reg[1] >= sma_reg[2]) begin //012
			sort_row_0[0] = sma_reg[0];
			sort_row_0[1] = sma_reg[1];
			sort_row_0[2] = sma_reg[2];
		end
		else if(sma_reg[0] >= sma_reg[2] && sma_reg[2] >= sma_reg[1]) begin //021
			sort_row_0[0] = sma_reg[0];
			sort_row_0[1] = sma_reg[2];
			sort_row_0[2] = sma_reg[1];
		end
		else if(sma_reg[1] >= sma_reg[0] && sma_reg[0] >= sma_reg[2]) begin //102
			sort_row_0[0] = sma_reg[1];
			sort_row_0[1] = sma_reg[0];
			sort_row_0[2] = sma_reg[2];
		end
		else if(sma_reg[1] >= sma_reg[2] && sma_reg[2] >= sma_reg[0]) begin //120
			sort_row_0[0] = sma_reg[1];
			sort_row_0[1] = sma_reg[2];
			sort_row_0[2] = sma_reg[0];
		end
		else if(sma_reg[2] >= sma_reg[0] && sma_reg[0] >= sma_reg[1]) begin //201
			sort_row_0[0] = sma_reg[2];
			sort_row_0[1] = sma_reg[0];
			sort_row_0[2] = sma_reg[1];
		end
		else begin //210
			sort_row_0[0] = sma_reg[2];
			sort_row_0[1] = sma_reg[1];
			sort_row_0[2] = sma_reg[0];
		end
	end

end

//row1
always@ (*) begin
	if(!in_mode_reg[2] && !in_mode_reg[1]) begin
		if(in_data_reg[3] >= in_data_reg[4] && in_data_reg[4] >= in_data_reg[5]) begin //345
			sort_row_1[0] = in_data_reg[3];
			sort_row_1[1] = in_data_reg[4];
			sort_row_1[2] = in_data_reg[5];
		end
		else if(in_data_reg[3] >= in_data_reg[5] && in_data_reg[5] >= in_data_reg[4]) begin //354
			sort_row_1[0] = in_data_reg[3];
			sort_row_1[1] = in_data_reg[5];
			sort_row_1[2] = in_data_reg[4];
		end
		else if(in_data_reg[4] >= in_data_reg[3] && in_data_reg[3] >= in_data_reg[5]) begin //435
			sort_row_1[0] = in_data_reg[4];
			sort_row_1[1] = in_data_reg[3];
			sort_row_1[2] = in_data_reg[5];
		end
		else if(in_data_reg[4] >= in_data_reg[5] && in_data_reg[5] >= in_data_reg[3]) begin //453
			sort_row_1[0] = in_data_reg[4];
			sort_row_1[1] = in_data_reg[5];
			sort_row_1[2] = in_data_reg[3];
		end
		else if(in_data_reg[5] >= in_data_reg[3] && in_data_reg[3] >= in_data_reg[4]) begin //534
			sort_row_1[0] = in_data_reg[5];
			sort_row_1[1] = in_data_reg[3];
			sort_row_1[2] = in_data_reg[4];
		end
		else begin //543
			sort_row_1[0] = in_data_reg[5];
			sort_row_1[1] = in_data_reg[4];
			sort_row_1[2] = in_data_reg[3];
		end
	end
	else if(in_mode_reg[1] && !in_mode_reg[2]) begin
		if(add_sub_reg[3] >= add_sub_reg[4] && add_sub_reg[4] >= add_sub_reg[5]) begin //345
			sort_row_1[0] = add_sub_reg[3];
			sort_row_1[1] = add_sub_reg[4];
			sort_row_1[2] = add_sub_reg[5];
		end
		else if(add_sub_reg[3] >= add_sub_reg[5] && add_sub_reg[5] >= add_sub_reg[4]) begin //354
			sort_row_1[0] = add_sub_reg[3];
			sort_row_1[1] = add_sub_reg[5];
			sort_row_1[2] = add_sub_reg[4];
		end
		else if(add_sub_reg[4] >= add_sub_reg[3] && add_sub_reg[3] >= add_sub_reg[5]) begin //435
			sort_row_1[0] = add_sub_reg[4];
			sort_row_1[1] = add_sub_reg[3];
			sort_row_1[2] = add_sub_reg[5];
		end
		else if(add_sub_reg[4] >= add_sub_reg[5] && add_sub_reg[5] >= add_sub_reg[3]) begin //453
			sort_row_1[0] = add_sub_reg[4];
			sort_row_1[1] = add_sub_reg[5];
			sort_row_1[2] = add_sub_reg[3];
		end
		else if(add_sub_reg[5] >= add_sub_reg[3] && add_sub_reg[3] >= add_sub_reg[4]) begin //534
			sort_row_1[0] = add_sub_reg[5];
			sort_row_1[1] = add_sub_reg[3];
			sort_row_1[2] = add_sub_reg[4];
		end
		else begin //543
			sort_row_1[0] = add_sub_reg[5];
			sort_row_1[1] = add_sub_reg[4];
			sort_row_1[2] = add_sub_reg[3];
		end
	end
	else begin
		if(sma_reg[3] >= sma_reg[4] && sma_reg[4] >= sma_reg[5]) begin //345
			sort_row_1[0] = sma_reg[3];
			sort_row_1[1] = sma_reg[4];
			sort_row_1[2] = sma_reg[5];
		end
		else if(sma_reg[3] >= sma_reg[5] && sma_reg[5] >= sma_reg[4]) begin //354
			sort_row_1[0] = sma_reg[3];
			sort_row_1[1] = sma_reg[5];
			sort_row_1[2] = sma_reg[4];
		end
		else if(sma_reg[4] >= sma_reg[3] && sma_reg[3] >= sma_reg[5]) begin //435
			sort_row_1[0] = sma_reg[4];
			sort_row_1[1] = sma_reg[3];
			sort_row_1[2] = sma_reg[5];
		end
		else if(sma_reg[4] >= sma_reg[5] && sma_reg[5] >= sma_reg[3]) begin //453
			sort_row_1[0] = sma_reg[4];
			sort_row_1[1] = sma_reg[5];
			sort_row_1[2] = sma_reg[3];
		end
		else if(sma_reg[5] >= sma_reg[3] && sma_reg[3] >= sma_reg[4]) begin //534
			sort_row_1[0] = sma_reg[5];
			sort_row_1[1] = sma_reg[3];
			sort_row_1[2] = sma_reg[4];
		end
		else begin //543
			sort_row_1[0] = sma_reg[5];
			sort_row_1[1] = sma_reg[4];
			sort_row_1[2] = sma_reg[3];
		end
	end
end

//row2
always@ (*) begin
	if(!in_mode_reg[2] && !in_mode_reg[1]) begin
		if(in_data_reg[6] >= in_data_reg[7] && in_data_reg[7] >= in_data_reg[8]) begin //678
			sort_row_2[0] = in_data_reg[6];
			sort_row_2[1] = in_data_reg[7];
			sort_row_2[2] = in_data_reg[8];
		end
		else if(in_data_reg[6] >= in_data_reg[8] && in_data_reg[8] >= in_data_reg[7]) begin //687
			sort_row_2[0] = in_data_reg[6];
			sort_row_2[1] = in_data_reg[8];
			sort_row_2[2] = in_data_reg[7];
		end
		else if(in_data_reg[7] >= in_data_reg[6] && in_data_reg[6] >= in_data_reg[8]) begin //768
			sort_row_2[0] = in_data_reg[7];
			sort_row_2[1] = in_data_reg[6];
			sort_row_2[2] = in_data_reg[8];
		end
		else if(in_data_reg[7] >= in_data_reg[8] && in_data_reg[8] >= in_data_reg[6]) begin //786
			sort_row_2[0] = in_data_reg[7];
			sort_row_2[1] = in_data_reg[8];
			sort_row_2[2] = in_data_reg[6];
		end
		else if(in_data_reg[8] >= in_data_reg[6] && in_data_reg[6] >= in_data_reg[7]) begin //867
			sort_row_2[0] = in_data_reg[8];
			sort_row_2[1] = in_data_reg[6];
			sort_row_2[2] = in_data_reg[7];
		end
		else begin //876
			sort_row_2[0] = in_data_reg[8];
			sort_row_2[1] = in_data_reg[7];
			sort_row_2[2] = in_data_reg[6];
		end
	end
	else if(in_mode_reg[1] && !in_mode_reg[2]) begin
		if(add_sub_reg[6] >= add_sub_reg[7] && add_sub_reg[7] >= add_sub_reg[8]) begin //678
			sort_row_2[0] = add_sub_reg[6];
			sort_row_2[1] = add_sub_reg[7];
			sort_row_2[2] = add_sub_reg[8];
		end
		else if(add_sub_reg[6] >= add_sub_reg[8] && add_sub_reg[8] >= add_sub_reg[7]) begin //687
			sort_row_2[0] = add_sub_reg[6];
			sort_row_2[1] = add_sub_reg[8];
			sort_row_2[2] = add_sub_reg[7];
		end
		else if(add_sub_reg[7] >= add_sub_reg[6] && add_sub_reg[6] >= add_sub_reg[8]) begin //768
			sort_row_2[0] = add_sub_reg[7];
			sort_row_2[1] = add_sub_reg[6];
			sort_row_2[2] = add_sub_reg[8];
		end
		else if(add_sub_reg[7] >= add_sub_reg[8] && add_sub_reg[8] >= add_sub_reg[6]) begin //786
			sort_row_2[0] = add_sub_reg[7];
			sort_row_2[1] = add_sub_reg[8];
			sort_row_2[2] = add_sub_reg[6];
		end
		else if(add_sub_reg[8] >= add_sub_reg[6] && add_sub_reg[6] >= add_sub_reg[7]) begin //867
			sort_row_2[0] = add_sub_reg[8];
			sort_row_2[1] = add_sub_reg[6];
			sort_row_2[2] = add_sub_reg[7];
		end
		else begin //876
			sort_row_2[0] = add_sub_reg[8];
			sort_row_2[1] = add_sub_reg[7];
			sort_row_2[2] = add_sub_reg[6];
		end
	end
	else begin
		if(sma_reg[6] >= sma_reg[7] && sma_reg[7] >= sma_reg[8]) begin //678
			sort_row_2[0] = sma_reg[6];
			sort_row_2[1] = sma_reg[7];
			sort_row_2[2] = sma_reg[8];
		end
		else if(sma_reg[6] >= sma_reg[8] && sma_reg[8] >= sma_reg[7]) begin //687
			sort_row_2[0] = sma_reg[6];
			sort_row_2[1] = sma_reg[8];
			sort_row_2[2] = sma_reg[7];
		end
		else if(sma_reg[7] >= sma_reg[6] && sma_reg[6] >= sma_reg[8]) begin //768
			sort_row_2[0] = sma_reg[7];
			sort_row_2[1] = sma_reg[6];
			sort_row_2[2] = sma_reg[8];
		end
		else if(sma_reg[7] >= sma_reg[8] && sma_reg[8] >= sma_reg[6]) begin //786
			sort_row_2[0] = sma_reg[7];
			sort_row_2[1] = sma_reg[8];
			sort_row_2[2] = sma_reg[6];
		end
		else if(sma_reg[8] >= sma_reg[6] && sma_reg[6] >= sma_reg[7]) begin //867
			sort_row_2[0] = sma_reg[8];
			sort_row_2[1] = sma_reg[6];
			sort_row_2[2] = sma_reg[7];
		end
		else begin //876
			sort_row_2[0] = sma_reg[8];
			sort_row_2[1] = sma_reg[7];
			sort_row_2[2] = sma_reg[6];
		end
	end
end

//col0
always@ (*) begin
	if(sort_row_0[0] >= sort_row_1[0] && sort_row_1[0] >= sort_row_2[0]) begin //012
		sort_col_0[0] = sort_row_0[0];
		sort_col_0[1] = sort_row_1[0];
		sort_col_0[2] = sort_row_2[0];
	end
	else if(sort_row_0[0] >= sort_row_2[0] && sort_row_2[0] >= sort_row_1[0]) begin //021
		sort_col_0[0] = sort_row_0[0];
		sort_col_0[1] = sort_row_2[0];
		sort_col_0[2] = sort_row_1[0];
	end
	else if(sort_row_1[0] >= sort_row_0[0] && sort_row_0[0] >= sort_row_2[0]) begin //102
		sort_col_0[0] = sort_row_1[0];
		sort_col_0[1] = sort_row_0[0];
		sort_col_0[2] = sort_row_2[0];
	end
	else if(sort_row_1[0] >= sort_row_2[0] && sort_row_2[0] >= sort_row_0[0]) begin //120
		sort_col_0[0] = sort_row_1[0];
		sort_col_0[1] = sort_row_2[0];
		sort_col_0[2] = sort_row_0[0];
	end
	else if(sort_row_2[0] >= sort_row_0[0] && sort_row_0[0] >= sort_row_1[0]) begin //201
		sort_col_0[0] = sort_row_2[0];
		sort_col_0[1] = sort_row_0[0];
		sort_col_0[2] = sort_row_1[0];
	end
	else begin //210
		sort_col_0[0] = sort_row_2[0];
		sort_col_0[1] = sort_row_1[0];
		sort_col_0[2] = sort_row_0[0];
	end
end

//col1
always@ (*) begin
	if(sort_row_0[1] >= sort_row_1[1] && sort_row_1[1] >= sort_row_2[1]) begin //012
		sort_col_1[0] = sort_row_0[1];
		sort_col_1[1] = sort_row_1[1];
		sort_col_1[2] = sort_row_2[1];
	end
	else if(sort_row_0[1] >= sort_row_2[1] && sort_row_2[1] >= sort_row_1[1]) begin //021
		sort_col_1[0] = sort_row_0[1];
		sort_col_1[1] = sort_row_2[1];
		sort_col_1[2] = sort_row_1[1];
	end
	else if(sort_row_1[1] >= sort_row_0[1] && sort_row_0[1] >= sort_row_2[1]) begin //102
		sort_col_1[0] = sort_row_1[1];
		sort_col_1[1] = sort_row_0[1];
		sort_col_1[2] = sort_row_2[1];
	end
	else if(sort_row_1[1] >= sort_row_2[1] && sort_row_2[1] >= sort_row_0[1]) begin //120
		sort_col_1[0] = sort_row_1[1];
		sort_col_1[1] = sort_row_2[1];
		sort_col_1[2] = sort_row_0[1];
	end
	else if(sort_row_2[1] >= sort_row_0[1] && sort_row_0[1] >= sort_row_1[1]) begin //201
		sort_col_1[0] = sort_row_2[1];
		sort_col_1[1] = sort_row_0[1];
		sort_col_1[2] = sort_row_1[1];
	end
	else begin //210
		sort_col_1[0] = sort_row_2[1];
		sort_col_1[1] = sort_row_1[1];
		sort_col_1[2] = sort_row_0[1];
	end
end

//col2
always@ (*) begin
	if(sort_row_0[2] >= sort_row_1[2] && sort_row_1[2] >= sort_row_2[2]) begin //012
		sort_col_2[0] = sort_row_0[2];
		sort_col_2[1] = sort_row_1[2];
		sort_col_2[2] = sort_row_2[2];
	end
	else if(sort_row_0[2] >= sort_row_2[2] && sort_row_2[2] >= sort_row_1[2]) begin //021
		sort_col_2[0] = sort_row_0[2];
		sort_col_2[1] = sort_row_2[2];
		sort_col_2[2] = sort_row_1[2];
	end
	else if(sort_row_1[2] >= sort_row_0[2] && sort_row_0[2] >= sort_row_2[2]) begin //102
		sort_col_2[0] = sort_row_1[2];
		sort_col_2[1] = sort_row_0[2];
		sort_col_2[2] = sort_row_2[2];
	end
	else if(sort_row_1[2] >= sort_row_2[2] && sort_row_2[2] >= sort_row_0[2]) begin //120
		sort_col_2[0] = sort_row_1[2];
		sort_col_2[1] = sort_row_2[2];
		sort_col_2[2] = sort_row_0[2];
	end
	else if(sort_row_2[2] >= sort_row_0[2] && sort_row_0[2] >= sort_row_1[2]) begin //201
		sort_col_2[0] = sort_row_2[2];
		sort_col_2[1] = sort_row_0[2];
		sort_col_2[2] = sort_row_1[2];
	end
	else begin //210
		sort_col_2[0] = sort_row_2[2];
		sort_col_2[1] = sort_row_1[2];
		sort_col_2[2] = sort_row_0[2];
	end
end

//diagonal
always@ (*) begin
	if(sort_col_0[2] >= sort_col_1[1] && sort_col_1[1] >= sort_col_2[0]) begin
		sort_dia[0] = sort_col_0[2];
		sort_dia[1] = sort_col_1[1];
		sort_dia[2] = sort_col_2[0];
	end
	else if(sort_col_0[2] >= sort_col_2[0] && sort_col_2[0] >= sort_col_1[1]) begin
		sort_dia[0] = sort_col_0[2];
		sort_dia[1] = sort_col_2[0];
		sort_dia[2] = sort_col_1[1];
	end
	else if(sort_col_1[1] >= sort_col_0[2] && sort_col_0[2] >= sort_col_2[0]) begin
		sort_dia[0] = sort_col_1[1];
		sort_dia[1] = sort_col_0[2];
		sort_dia[2] = sort_col_2[0];
	end
	else if(sort_col_1[1] >= sort_col_2[0] && sort_col_2[0] >= sort_col_0[2]) begin
		sort_dia[0] = sort_col_1[1];
		sort_dia[1] = sort_col_2[0];
		sort_dia[2] = sort_col_0[2];
	end
	else if(sort_col_2[0] >= sort_col_0[2] && sort_col_0[2] >= sort_col_1[1]) begin
		sort_dia[0] = sort_col_2[0];
		sort_dia[1] = sort_col_0[2];
		sort_dia[2] = sort_col_1[1];
	end
	else begin
		sort_dia[0] = sort_col_2[0];
		sort_dia[1] = sort_col_1[1];
		sort_dia[2] = sort_col_0[2];
	end
end

always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_data_min <= 0;
		out_data_min_1 <= 0;
	end
	else begin
		if(current_state == OUTPUT) begin
			out_data_min <= sort_col_2[2];
			out_data_min_1 <= out_data_min;
		end
		else if(current_state == IDLE) begin
			out_data_min <= 0;
			out_data_min_1 <= 0;
		end
	end
end

always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_data_median <= 0;
	end
	else begin
		if(current_state == OUTPUT) begin
			out_data_median <= sort_dia[1];

		end
		else if(current_state == IDLE) begin
			out_data_median <= 0;
		end
	end
end

//========================================================
// Output Block
//========================================================
//out_valid
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
		if(current_state == OUTPUT) begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end
end

//out_data
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_data <= 0;
	end
	else begin
		if(current_state == OUTPUT) begin
			case(count)
			0: out_data <= sort_col_0[0];
			// 1: out_data <= sort_dia[1];
			// 2: out_data <= sort_col_2[2];
			1: out_data <= out_data_median;
			2: out_data <= out_data_min_1;
			default: out_data <= 0;
			endcase
		end
		else begin
			out_data <= 0;
		end
	end
end


// always@ (*) begin
// 	if(current_state == OUTPUT) begin
// 		out_valid = 1;
// 	end
// 	else begin
// 		out_valid = 0;
// 	end
// end

// always@ (*) begin
// 	if(current_state == OUTPUT) begin
// 		case(count)
// 		0: out_data = sort_col_0[0];
// 		1: out_data = sort_dia[1];
// 		2: out_data = sort_col_2[2];
// 		default: out_data = 0;
// 		endcase
// 	end
// 	else begin
// 		out_data = 0;
// 	end
// end


endmodule

// always@ (posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		extra_count <= {40{2'b10}};
// 	end
// 	else begin
// 		extra_count <= {~extra_count[0], extra_count[79:1]};
// 	end
// end

// always@ (posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		alter_count <= {40{2'b01}};
// 	end
// 	else begin
// 		alter_count <= {~alter_count[0], alter_count[79:1]};
// 	end
// end