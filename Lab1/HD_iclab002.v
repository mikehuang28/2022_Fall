
module HD(
	code_word1,
	code_word2,
	out_n
);
input  [6:0]code_word1, code_word2;
output reg signed [5:0] out_n;

///////////////////////////////////
//       Port declaration        //
///////////////////////////////////

reg [6:0]code_word1_reg, code_word2_reg;
//reg p1, p2, p3;
reg circle1_1, circle1_2, circle1_3;//circle
reg circle2_1, circle2_2, circle2_3;
reg false_num_1, false_num_2;
reg [1:0] opt;
//reg minus_flag_a;
//reg minus_flag_b;
reg minus_flag;
reg signed [4:0] c1, c2;
reg signed [4:0] a, b;
reg signed [4:0] out_reg;
reg signed [5:0] temp_a;
reg signed [4:0] temp_b;

///////////////////////////////////
//           Design              //
///////////////////////////////////


always@(*) begin
	code_word1_reg = code_word1;
	code_word2_reg = code_word2;

	//circle
	//codeword1
	circle1_1 = code_word1_reg[6] ^ code_word1_reg[3] ^ code_word1_reg[2] ^ code_word1_reg[1];
	circle1_2 = code_word1_reg[5] ^ code_word1_reg[3] ^ code_word1_reg[2] ^ code_word1_reg[0];
	circle1_3 = code_word1_reg[4] ^ code_word1_reg[3] ^ code_word1_reg[1] ^ code_word1_reg[0];
	//codeword2
	circle2_1 = code_word2_reg[6] ^ code_word2_reg[3] ^ code_word2_reg[2] ^ code_word2_reg[1];
	circle2_2 = code_word2_reg[5] ^ code_word2_reg[3] ^ code_word2_reg[2] ^ code_word2_reg[0];
	circle2_3 = code_word2_reg[4] ^ code_word2_reg[3] ^ code_word2_reg[1] ^ code_word2_reg[0];


end

always@(*) begin
	//false_num_1
	if(circle1_1 && circle1_2 && circle1_3) begin//x1 false
		false_num_1 = code_word1_reg[3];
		c1 = {!code_word1_reg[3], !code_word1_reg[3], code_word1_reg[2], code_word1_reg[1], code_word1_reg[0]};
	end
	else if(circle1_1 && circle1_2) begin//x2 false
		false_num_1 = code_word1_reg[2];
		c1 = {code_word1_reg[3], code_word1_reg[3], !code_word1_reg[2], code_word1_reg[1], code_word1_reg[0]};
	end
	else if(circle1_1 && circle1_3) begin//x3 false
		false_num_1 = code_word1_reg[1];
		c1 = {code_word1_reg[3], code_word1_reg[3], code_word1_reg[2], !code_word1_reg[1], code_word1_reg[0]};
	end
	else if(circle1_2 && circle1_3) begin//x4 false
		false_num_1 = code_word1_reg[0];
		c1 = {code_word1_reg[3], code_word1_reg[3], code_word1_reg[2], code_word1_reg[1], !code_word1_reg[0]};
	end
	else if(circle1_1) begin
		false_num_1 = code_word1_reg[6];
		c1 = {code_word1_reg[3], code_word1_reg[3], code_word1_reg[2], code_word1_reg[1], code_word1_reg[0]};
	end
	else if(circle1_2) begin
		false_num_1 = code_word1_reg[5];
		c1 = {code_word1_reg[3], code_word1_reg[3], code_word1_reg[2], code_word1_reg[1], code_word1_reg[0]};
	end
	//else if(!circle1_1 && !circle1_2 && circle1_3) begin
	else begin
		false_num_1 = code_word1_reg[4];
		c1 = {code_word1_reg[3], code_word1_reg[3], code_word1_reg[2], code_word1_reg[1], code_word1_reg[0]};
	end

	// else begin
	// 	false_num_1 = 0;
	// 	c1 = 0;
	// end

end

always @(*) begin
	//false_num_2
	if(circle2_1 && circle2_2 && circle2_3) begin//x1 false
		false_num_2 = code_word2_reg[3];
		c2 = {!code_word2_reg[3], !code_word2_reg[3], code_word2_reg[2], code_word2_reg[1], code_word2_reg[0]};
	end
	else if(circle2_1 && circle2_2) begin//x2 false
		false_num_2 = code_word2_reg[2];
		c2 = {code_word2_reg[3], code_word2_reg[3], !code_word2_reg[2], code_word2_reg[1], code_word2_reg[0]};
	end
	else if(circle2_1 && circle2_3) begin//x3 false
		false_num_2 = code_word2_reg[1];
		c2 = { code_word2_reg[3], code_word2_reg[3], code_word2_reg[2], !code_word2_reg[1], code_word2_reg[0]};
	end
	else if(circle2_2 && circle2_3) begin//x4 false
		false_num_2 = code_word2_reg[0];
		c2 = { code_word2_reg[3], code_word2_reg[3], code_word2_reg[2], code_word2_reg[1], !code_word2_reg[0]};
	end
	else if(circle2_1) begin
		false_num_2 = code_word2_reg[6];
		c2 = { code_word2_reg[3], code_word2_reg[3], code_word2_reg[2], code_word2_reg[1], code_word2_reg[0]};
	end
	else if(circle2_2) begin
		false_num_2 = code_word2_reg[5];
		c2 = { code_word2_reg[3], code_word2_reg[3], code_word2_reg[2], code_word2_reg[1], code_word2_reg[0]};
	end
	//else if(!circle2_1 && !circle2_2 && circle2_3) begin
	else begin
		false_num_2 = code_word2_reg[4];
		c2 = { code_word2_reg[3], code_word2_reg[3], code_word2_reg[2], code_word2_reg[1], code_word2_reg[0]};
	end
	// else begin
	// 	false_num_2 = 0;
	// 	c2 = 0;
	// end

end



//output logic
always@(*) begin
	opt = {false_num_1, false_num_2};
	minus_flag = (false_num_1 ^ false_num_2) ? 1: 0;

	//output
	out_n = (a << 1) + b ;

end

//output selection
always@(*) begin
	if(opt == 2'd0) begin
		a = c1;
		b = c2;
	end
	else if(opt == 2'd1) begin
		a = c1;
		b = (c2 ^ {5{minus_flag}}) + minus_flag;
	end
	else if(opt == 2'd2) begin
		a = (c2 ^ {5{minus_flag}}) + minus_flag;
		b = c1;
	end
	else begin
		a = c2;
		b = c1;
	end
end


endmodule


