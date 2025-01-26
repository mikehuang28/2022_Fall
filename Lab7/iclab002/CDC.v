`include "synchronizer.v"
`include "syn_XOR.v"
module CDC(
	//Input Port
	clk1,
    clk2,
    clk3,
	rst_n,
	in_valid1,
	in_valid2,
	user1,
	user2,

    //Output Port
    out_valid1,
    out_valid2,
	equal,
	exceed,
	winner
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input 		clk1, clk2, clk3, rst_n;
input 		in_valid1, in_valid2;
input [3:0]	user1, user2;

output reg	out_valid1, out_valid2;
output reg	equal, exceed, winner;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
//----clk1----
reg [3:0] user_reg;
reg [3:0] clk1_user_count;
//reg [2:0] clk1_user2_count;
reg [5:0] epoch_count;
reg switch_user;
wire clk1_flag_user1;
wire clk1_flag_user2;
reg [6:0] p_exceed;
reg [6:0] p_equal;
reg [6:0] equal_temp;
reg [6:0] exceed_temp;
reg [1:0] winner_reg;
//----clk2----
wire clk2_out_valid1_flag; //out_valid1
wire clk2_out_valid2_flag; //out_valid2
reg equal_exceed_flag; //equal && exceed
reg winner_flag; //winner
reg [3:0] clk2_user_reg;
reg [5:0] point_user1;
reg [5:0] point_user2;
reg [5:0] total_point_user1;
reg [3:0] clk2_count;
reg [2:0] card_left [12:0];
wire [5:0] card_denominator;
//----clk3----
reg [3:0] clk3_equal_exceed_count;
reg [3:0] clk3_winner_count;
reg clk3_equal_exceed_flag_hold;
reg clk3_winner_flag_hold;
wire clk3_equal_exceed_flag;
wire clk3_winner_flag;

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
//----clk1----

//----clk2----
integer i;
//----clk3----

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
//============================================
//   clk1 domain
//============================================
//--------------------------------------------
//   input user
//--------------------------------------------
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		user_reg <= 0;
	end
	else begin
		if(in_valid1) begin
			user_reg <= user1;
		end
		else if(in_valid2) begin
			user_reg <= user2;
		end

	end
end

//--------------------------------------------
//   counter && flag
//--------------------------------------------
// counter in clk1
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		clk1_user_count <= 0;
	end
	else begin
		if(clk1_user_count == 9) begin
			clk1_user_count <= 0;
		end
		else if(in_valid1 || in_valid2) begin
			clk1_user_count <= clk1_user_count + 1;
		end
	end
end

//epoch_count
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		epoch_count <= 0;
	end
	else begin
		if(epoch_count == 50) begin
			epoch_count <= 1;
		end
		else if(in_valid1) begin
			epoch_count <= epoch_count + 1;
		end
		else if(in_valid2) begin
			epoch_count <= epoch_count + 1;
		end
	end
end

//out_flag
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		equal_exceed_flag <= 0;
	end
	else begin
		if(clk1_user_count == 2 || clk1_user_count == 3 || clk1_user_count == 7 || clk1_user_count == 8) begin
			equal_exceed_flag <= 1;
		end
		else begin
			equal_exceed_flag <= 0;
		end
	end
end

//winner_flag
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		winner_flag <= 0;
	end
	else if(clk1_user_count == 9) begin
		winner_flag <= 1;
	end
	else begin
		winner_flag <= 0;
	end
end

//--------------------------------------------
//   calculation
//--------------------------------------------
//point_user1
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		point_user1 <= 0;
	end
	else begin
		if(in_valid1 && user1 > 10) begin
			point_user1 <= point_user1 + 1;
		end
		else if(in_valid1)begin
			point_user1 <= point_user1 + user1;
		end
		else if(clk1_user_count == 5) begin
			point_user1 <= 0;
		end
	end
end

always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		total_point_user1 <= 0;
	end
	else begin
		if(clk1_user_count == 5) begin
			total_point_user1 <= point_user1;
		end
	end
end

//point_user2
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		point_user2 <= 0;
	end
	else begin
		if(in_valid2 && user2 > 10) begin
			point_user2 <= point_user2 + 1;
		end
		else if(in_valid2)begin
			point_user2 <= point_user2 + user2;
		end
		else if(clk1_user_count == 3) begin
			point_user2 <= 0;
		end
	end
end

//card_left
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 13; i = i + 1) begin
			card_left[i] <= 4;
		end
	end
	else begin
		if(epoch_count == 50) begin
			for(i = 0; i < 13; i = i + 1) begin
				if(user1 - 1 == i) begin
					card_left[i] <= 3;
				end
				else begin
					card_left[i] <= 4;
				end
			end
		end
		else if(in_valid1) begin
			card_left[user1 - 1] <= card_left[user1 - 1] - 1;
		end
		else if(in_valid2) begin
			card_left[user2 - 1] <= card_left[user2 - 1] - 1;
		end
	end
end

assign card_denominator = 52 - epoch_count;

//equal probability
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		p_equal <= 0;
	end
	else begin
		case(clk1_user_count)
		3, 4: begin
			if(point_user1 >= 21 || point_user1 < 11) begin //exceed
				p_equal <= 0;
			end
			else if(point_user1 == 20) begin //1,11,12,13 = 1 point
				p_equal <= (card_left[0] + card_left[10] + card_left[11] + card_left[12]) * 100 / card_denominator;
			end
			else begin
				p_equal <= (card_left[20 - point_user1] * 100) / card_denominator;
			end
		end
		8, 9: begin
			if(point_user2 >= 21 || point_user2 < 11) begin //exceed
				p_equal <= 0;
			end
			else if(point_user2 == 20) begin //1,11,12,13 = 1 point
				p_equal <= (card_left[0] + card_left[10] + card_left[11] + card_left[12]) * 100 / card_denominator;
			end
			else begin
				p_equal <= (card_left[20 - point_user2] * 100) / card_denominator;
			end
		end
		default: p_equal <= p_equal;
		endcase
	end
end

//exceed_temp
always@ (*) begin
	if(clk1_user_count == 3 || clk1_user_count == 4) begin
		case(21 - point_user1)
		1: exceed_temp = (card_left[1] + card_left[2] + card_left[3] + card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		2: exceed_temp = (card_left[2] + card_left[3] + card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		3: exceed_temp = (card_left[3] + card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		4: exceed_temp = (card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		5: exceed_temp = (card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		6: exceed_temp = (card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		7: exceed_temp = (card_left[7] + card_left[8] + card_left[9]);
		8: exceed_temp = (card_left[8] + card_left[9]);
		9: exceed_temp = (card_left[9]);
		default: exceed_temp = 0;
		endcase
	end
	else if(clk1_user_count == 8 || clk1_user_count == 9) begin
		case(21 - point_user2)
		1: exceed_temp = (card_left[1] + card_left[2] + card_left[3] + card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		2: exceed_temp = (card_left[2] + card_left[3] + card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		3: exceed_temp = (card_left[3] + card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		4: exceed_temp = (card_left[4] + card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		5: exceed_temp = (card_left[5] + card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		6: exceed_temp = (card_left[6] + card_left[7] + card_left[8] + card_left[9]);
		7: exceed_temp = (card_left[7] + card_left[8] + card_left[9]);
		8: exceed_temp = (card_left[8] + card_left[9]);
		9: exceed_temp = (card_left[9]);
		default: exceed_temp = 0;
		endcase
	end
	else begin
		exceed_temp = 0;
	end
end

//exceed probability
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		p_exceed <= 0;
	end
	else begin
		case(clk1_user_count)
		3, 4: begin
			if(point_user1 >= 21) begin
				p_exceed <= 100;
			end
			else if(point_user1 <= 11) begin
				p_exceed <= 0;
			end
			else begin
				p_exceed <= (exceed_temp * 100) / card_denominator;
			end
		end
		8, 9: begin
			if(point_user2 >= 21) begin
				p_exceed <= 100;
			end
			else if(point_user2 <= 11) begin
				p_exceed <= 0;
			end
			else begin
				p_exceed <= (exceed_temp * 100) / card_denominator;
			end
		end
		default: p_exceed <= p_exceed;
		endcase
	end
end

//winner_reg
always@ (posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		winner_reg <= 0;
	end
	else begin
		if(clk1_user_count == 0 ) begin
			if((total_point_user1 > 21 && point_user2 > 21) || (total_point_user1 == point_user2 && total_point_user1 <= 21 && point_user2 <= 21)) begin // no winner
				winner_reg <= 0;
			end
			else if((total_point_user1 <= 21 && point_user2 > 21) || (total_point_user1 > point_user2 && total_point_user1 <= 21)) begin // user1 wins
				winner_reg <= 2;
			end
			else if((total_point_user1 > 21 && point_user2 <= 21) || (total_point_user1 < point_user2 && point_user2 <= 21)) begin // user2 wins
				winner_reg <= 3;
			end
		end
		else begin
			winner_reg <= 0;
		end
	end
end

//============================================
//   clk3 domain
//============================================
//out_valid1
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid1 <= 0;
	end
	else begin
		if(clk3_equal_exceed_count == 7)
			out_valid1 <= 0;
		else if(clk3_equal_exceed_flag_hold) begin
			out_valid1 <= 1;
		end
	end
end

//out_valid2
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid2 <= 0;
	end
	else begin
		if(clk3_winner_flag_hold) begin
			if(winner_reg != 0) begin
				if(clk3_winner_count == 2) begin
					out_valid2 <= 0;
				end
				else begin
					out_valid2 <= 1;
				end
			end
			else begin
				if(clk3_winner_count == 0) begin
					out_valid2 <= 1;
				end
				else begin
					out_valid2 <= 0;
				end
			end
		//out_valid2 <= 0;
		end
		else begin
			out_valid2 <= 0;
		end
	end
end

//equal
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		equal <= 0;
	end
	else begin
		if(clk3_equal_exceed_flag_hold) begin
			case(clk3_equal_exceed_count)
			0: equal <= p_equal[6];
			1: equal <= p_equal[5];
			2: equal <= p_equal[4];
			3: equal <= p_equal[3];
			4: equal <= p_equal[2];
			5: equal <= p_equal[1];
			6: equal <= p_equal[0];
			default: equal <= 0;
			endcase
		end
		else begin
			equal <= 0;
		end
	end
end

//exceed
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		exceed <= 0;
	end
	else begin
		if(clk3_equal_exceed_flag_hold) begin
			case(clk3_equal_exceed_count)
			0: exceed <= p_exceed[6];
			1: exceed <= p_exceed[5];
			2: exceed <= p_exceed[4];
			3: exceed <= p_exceed[3];
			4: exceed <= p_exceed[2];
			5: exceed <= p_exceed[1];
			6: exceed <= p_exceed[0];
			default: exceed <= 0;
			endcase
		end
		else begin
			exceed <= 0;
		end
	end
end

//winner
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		winner <= 0;
	end
	else begin
		if(clk3_winner_flag_hold) begin
			if(winner_reg == 0) begin
				winner <= 0;
			end
			else begin
				case(clk3_winner_count)
				0: winner <= winner_reg[1];
				1: winner <= winner_reg[0];
				default: winner <= 0;
				endcase
			end
		end
		else begin
			winner <= 0;
		end
	end
end

//clk3_equal_exceed_count
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		clk3_equal_exceed_count <= 0;
	end
	else begin
		if(clk3_equal_exceed_flag_hold) begin
			clk3_equal_exceed_count <= clk3_equal_exceed_count + 1;
		end
		else if(clk3_equal_exceed_count == 8) begin
			clk3_equal_exceed_count <= 0;
		end
		else if(clk3_equal_exceed_count) begin
			clk3_equal_exceed_count <= clk3_equal_exceed_count + 1;
		end
	end
end

//clk3_winner_count
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		clk3_winner_count <= 0;
	end
	else begin
		if(clk3_winner_flag_hold) begin
			clk3_winner_count <= clk3_winner_count + 1;
		end
		else if(clk3_winner_count == 3) begin
			clk3_winner_count <= 0;
		end
		else if(clk3_winner_count) begin
			clk3_winner_count <= clk3_winner_count + 1;
		end

	end
end

//flag extension
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		clk3_equal_exceed_flag_hold <= 0;
	end
	else begin
		if(clk3_equal_exceed_flag) begin
			clk3_equal_exceed_flag_hold <= 1;
		end
		else if(clk3_equal_exceed_count == 7) begin
			clk3_equal_exceed_flag_hold <= 0;
		end
	end
end

//flag extension
always@ (posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		clk3_winner_flag_hold <= 0;
	end
	else begin
		if(clk3_winner_flag) begin
			clk3_winner_flag_hold <= 1;
		end
		else if(clk3_winner_count == 2) begin
			clk3_winner_flag_hold <= 0;
		end
	end
end

//============================================
//   clk2 domain
//============================================


//---------------------------------------------------------------------
//   syn_XOR
//---------------------------------------------------------------------
syn_XOR syn_equal_exceed(.IN(equal_exceed_flag), .OUT(clk3_equal_exceed_flag), .TX_CLK(clk1), .RX_CLK(clk3), .RST_N(rst_n));
syn_XOR syn_winner(.IN(winner_flag), .OUT(clk3_winner_flag), .TX_CLK(clk1), .RX_CLK(clk3), .RST_N(rst_n));




endmodule