module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_u,
	in_valid_w,
	in_valid_v,
	in_valid_x,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER && INTEGER DECLARATION
//---------------------------------------------------------------------
// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
parameter inst_faithful_round = 1;

//FSM
parameter IDLE = 0;
parameter INPUT = 1;
parameter CAL = 2;

integer i,j;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_u, in_valid_w, in_valid_v, in_valid_x;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [1:0] next_state, current_state;
//reg [3:0] out_valid_count;
reg [4:0] count;

reg [inst_sig_width+inst_exp_width:0] x_reg [8:0];
reg [inst_sig_width+inst_exp_width:0] u_reg [8:0];
reg [inst_sig_width+inst_exp_width:0] w_reg [8:0];
reg [inst_sig_width+inst_exp_width:0] v_reg [8:0];
reg [inst_sig_width+inst_exp_width:0] dp_reg [5:0];
reg [inst_sig_width+inst_exp_width:0] add_reg [2:0];
reg [inst_sig_width+inst_exp_width:0] exp_reg [2:0];
reg [inst_sig_width+inst_exp_width:0] h [2:0];
reg [inst_sig_width+inst_exp_width:0] y [8:0];

reg [inst_sig_width+inst_exp_width:0] dp_0a, dp_0b, dp_0c, dp_0d, dp_0e, dp_0f;
reg [inst_sig_width+inst_exp_width:0] dp_1a, dp_1b, dp_1c, dp_1d, dp_1e, dp_1f;
reg [inst_sig_width+inst_exp_width:0] dp_2a, dp_2b, dp_2c, dp_2d, dp_2e, dp_2f;
reg [inst_sig_width+inst_exp_width:0] add_0a, add_0b, add_1a, add_1b, add_2a, add_2b;
reg [inst_sig_width+inst_exp_width:0] exp_0a, exp_1a, exp_2a, recip_0a, recip_1a, recip_2a;
wire [inst_sig_width+inst_exp_width:0] dp_0z, dp_1z, dp_2z, add_0z, add_1z, add_2z, exp_0z, exp_1z, exp_2z, recip_0z, recip_1z, recip_2z;


//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------

//current_state
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= IDLE;
	end
	else begin
		current_state <= next_state;
	end
end

//next state combinational logic
always@ (*) begin
	case(current_state)
	IDLE: begin
		if(in_valid_u || in_valid_w || in_valid_v || in_valid_x) begin
			next_state = INPUT;
		end
		else begin
			next_state = IDLE;
		end
	end
	INPUT: begin
		if(!in_valid_u || !in_valid_w || !in_valid_v || !in_valid_x) begin
			next_state = CAL;
		end
		else begin
			next_state = INPUT;
		end
	end
	CAL: begin
		//if(out_valid_count == 9) begin
		if(count == 19) begin
			next_state = IDLE;
		end
		else begin
			next_state = CAL;
		end
	end
	default: next_state = current_state;
	endcase
end

//---------------------------------------------------------------------
//   INPUT BLOCK
//---------------------------------------------------------------------

//x_reg
always@ (posedge clk /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 9; i = i + 1) begin
	// 		x_reg[i] <= 0;
	// 	end
	// end
	// else begin
		if(in_valid_x) begin
			x_reg[8] <= data_x;
			x_reg[7] <= x_reg[8];
			x_reg[6] <= x_reg[7];
			x_reg[5] <= x_reg[6];
			x_reg[4] <= x_reg[5];
			x_reg[3] <= x_reg[4];
			x_reg[2] <= x_reg[3];
			x_reg[1] <= x_reg[2];
			x_reg[0] <= x_reg[1];
		end
		else if(current_state == CAL) begin
			for(i = 0; i < 9; i = i + 1) begin
				x_reg[i] <= x_reg[i];
			end
		end
	//end
end

//u_reg
always@ (posedge clk /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 9; i = i + 1) begin
	// 		u_reg[i] <= 0;
	// 	end
	// end
	// else begin
		if(in_valid_u) begin
			u_reg[8] <= weight_u;
			u_reg[7] <= u_reg[8];
			u_reg[6] <= u_reg[7];
			u_reg[5] <= u_reg[6];
			u_reg[4] <= u_reg[5];
			u_reg[3] <= u_reg[4];
			u_reg[2] <= u_reg[3];
			u_reg[1] <= u_reg[2];
			u_reg[0] <= u_reg[1];
		end
		else if(current_state == CAL) begin
			for(i = 0; i < 9; i = i + 1) begin
				u_reg[i] <= u_reg[i];
			end
		end
	//end
end

//w_reg
always@ (posedge clk /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 9; i = i + 1) begin
	// 		w_reg[i] <= 0;
	// 	end
	// end
	// else begin
		if(in_valid_w) begin
			w_reg[8] <= weight_w;
			w_reg[7] <= w_reg[8];
			w_reg[6] <= w_reg[7];
			w_reg[5] <= w_reg[6];
			w_reg[4] <= w_reg[5];
			w_reg[3] <= w_reg[4];
			w_reg[2] <= w_reg[3];
			w_reg[1] <= w_reg[2];
			w_reg[0] <= w_reg[1];
		end
		else if(current_state == CAL) begin
			for(i = 0; i < 9; i = i + 1) begin
				w_reg[i] <= w_reg[i];
			end
		end
	//end
end

//v_reg
always@ (posedge clk /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 9; i = i + 1) begin
	// 		v_reg[i] <= 0;
	// 	end
	// end
	// else begin
		if(in_valid_v) begin
			v_reg[8] <= weight_v;
			v_reg[7] <= v_reg[8];
			v_reg[6] <= v_reg[7];
			v_reg[5] <= v_reg[6];
			v_reg[4] <= v_reg[5];
			v_reg[3] <= v_reg[4];
			v_reg[2] <= v_reg[3];
			v_reg[1] <= v_reg[2];
			v_reg[0] <= v_reg[1];
		end
		else if(current_state == CAL) begin
			for(i = 0; i < 9; i = i + 1) begin
				v_reg[i] <= v_reg[i];
			end
		end
	//end
end

//---------------------------------------------------------------------
//   COUNTER
//---------------------------------------------------------------------

//count
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 0;
	end
	else begin
		if(current_state == IDLE) begin
			count <= 0;
		end
		else if(current_state == CAL) begin
			count <= count + 1;
		end
		else begin
			count <= 0;
		end
	end
end

//---------------------------------------------------------------------
//   DESIGNWARE
//---------------------------------------------------------------------

//dp3
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) D0(.a(dp_0a), .b(dp_0b), .c(dp_0c), .d(dp_0d), .e(dp_0e), .f(dp_0f), .rnd(3'b000), .z(dp_0z));
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) D1(.a(dp_1a), .b(dp_1b), .c(dp_1c), .d(dp_1d), .e(dp_1e), .f(dp_1f), .rnd(3'b000), .z(dp_1z));
DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) D2(.a(dp_2a), .b(dp_2b), .c(dp_2c), .d(dp_2d), .e(dp_2e), .f(dp_2f), .rnd(3'b000), .z(dp_2z));

//add
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A0(.a(add_0a), .b(add_0b), .z(add_0z), .rnd(3'b000));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1(.a(add_1a), .b(add_1b), .z(add_1z), .rnd(3'b000));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2(.a(add_2a), .b(add_2b), .z(add_2z), .rnd(3'b000));

//sigmoid (exp + add + recip)
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E0(.a(exp_0a), .z(exp_0z));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E1(.a(exp_1a), .z(exp_1z));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E2(.a(exp_2a), .z(exp_2z));
//addition in sigmoid
/*
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A3(.a(), .b(), .z(), .rnd(3'b000));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A4(.a(), .b(), .z(), .rnd(3'b000));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A5(.a(), .b(), .z(), .rnd(3'b000));
*/
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) R0(.a(recip_0a), .z(recip_0z), .rnd(3'b000));
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) R1(.a(recip_1a), .z(recip_1z), .rnd(3'b000));
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) R2(.a(recip_2a), .z(recip_2z), .rnd(3'b000));

//---------------------------------------------------------------------
//   IP INPUT CONTROL
//---------------------------------------------------------------------
/*
a = U * x1 (+ W * h0)
b = U * x2 + W * h1
c = U * x3 + W * h2
*/

//dp
always@ (*) begin
	if(current_state == CAL) begin
		case(count)
		0: begin //U * x1
			dp_0a = u_reg[0]; dp_0b = x_reg[0]; dp_0c = u_reg[1]; dp_0d = x_reg[1]; dp_0e = u_reg[2]; dp_0f = x_reg[2];
			dp_1a = u_reg[3]; dp_1b = x_reg[0]; dp_1c = u_reg[4]; dp_1d = x_reg[1]; dp_1e = u_reg[5]; dp_1f = x_reg[2];
			dp_2a = u_reg[6]; dp_2b = x_reg[0]; dp_2c = u_reg[7]; dp_2d = x_reg[1]; dp_2e = u_reg[8]; dp_2f = x_reg[2];
		end
		3: begin //U * x2
			dp_0a = u_reg[0]; dp_0b = x_reg[3]; dp_0c = u_reg[1]; dp_0d = x_reg[4]; dp_0e = u_reg[2]; dp_0f = x_reg[5];
			dp_1a = u_reg[3]; dp_1b = x_reg[3]; dp_1c = u_reg[4]; dp_1d = x_reg[4]; dp_1e = u_reg[5]; dp_1f = x_reg[5];
			dp_2a = u_reg[6]; dp_2b = x_reg[3]; dp_2c = u_reg[7]; dp_2d = x_reg[4]; dp_2e = u_reg[8]; dp_2f = x_reg[5];
		end
		4: begin //V * h1
			dp_0a = v_reg[0]; dp_0b = h[0]; dp_0c = v_reg[1]; dp_0d = h[1]; dp_0e = v_reg[2]; dp_0f = h[2];
			dp_1a = v_reg[3]; dp_1b = h[0]; dp_1c = v_reg[4]; dp_1d = h[1]; dp_1e = v_reg[5]; dp_1f = h[2];
			dp_2a = v_reg[6]; dp_2b = h[0]; dp_2c = v_reg[7]; dp_2d = h[1]; dp_2e = v_reg[8]; dp_2f = h[2];
		end
		5: begin //W * h1
			dp_0a = w_reg[0]; dp_0b = h[0]; dp_0c = w_reg[1]; dp_0d = h[1]; dp_0e = w_reg[2]; dp_0f = h[2];
			dp_1a = w_reg[3]; dp_1b = h[0]; dp_1c = w_reg[4]; dp_1d = h[1]; dp_1e = w_reg[5]; dp_1f = h[2];
			dp_2a = w_reg[6]; dp_2b = h[0]; dp_2c = w_reg[7]; dp_2d = h[1]; dp_2e = w_reg[8]; dp_2f = h[2];
		end
		9: begin //U * x3
			dp_0a = u_reg[0]; dp_0b = x_reg[6]; dp_0c = u_reg[1]; dp_0d = x_reg[7]; dp_0e = u_reg[2]; dp_0f = x_reg[8];
			dp_1a = u_reg[3]; dp_1b = x_reg[6]; dp_1c = u_reg[4]; dp_1d = x_reg[7]; dp_1e = u_reg[5]; dp_1f = x_reg[8];
			dp_2a = u_reg[6]; dp_2b = x_reg[6]; dp_2c = u_reg[7]; dp_2d = x_reg[7]; dp_2e = u_reg[8]; dp_2f = x_reg[8];
		end
		10: begin //V * h2
			dp_0a = v_reg[0]; dp_0b = h[0]; dp_0c = v_reg[1]; dp_0d = h[1]; dp_0e = v_reg[2]; dp_0f = h[2];
			dp_1a = v_reg[3]; dp_1b = h[0]; dp_1c = v_reg[4]; dp_1d = h[1]; dp_1e = v_reg[5]; dp_1f = h[2];
			dp_2a = v_reg[6]; dp_2b = h[0]; dp_2c = v_reg[7]; dp_2d = h[1]; dp_2e = v_reg[8]; dp_2f = h[2];
		end
		11: begin //W * h2
			dp_0a = w_reg[0]; dp_0b = h[0]; dp_0c = w_reg[1]; dp_0d = h[1]; dp_0e = w_reg[2]; dp_0f = h[2];
			dp_1a = w_reg[3]; dp_1b = h[0]; dp_1c = w_reg[4]; dp_1d = h[1]; dp_1e = w_reg[5]; dp_1f = h[2];
			dp_2a = w_reg[6]; dp_2b = h[0]; dp_2c = w_reg[7]; dp_2d = h[1]; dp_2e = w_reg[8]; dp_2f = h[2];
		end
		16: begin //V * h3
			dp_0a = v_reg[0]; dp_0b = h[0]; dp_0c = v_reg[1]; dp_0d = h[1]; dp_0e = v_reg[2]; dp_0f = h[2];
			dp_1a = v_reg[3]; dp_1b = h[0]; dp_1c = v_reg[4]; dp_1d = h[1]; dp_1e = v_reg[5]; dp_1f = h[2];
			dp_2a = v_reg[6]; dp_2b = h[0]; dp_2c = v_reg[7]; dp_2d = h[1]; dp_2e = v_reg[8]; dp_2f = h[2];
		end
		default: begin
			dp_0a = 0; dp_0b = 0; dp_0c = 0; dp_0d = 0; dp_0e = 0; dp_0f = 0;
			dp_1a = 0; dp_1b = 0; dp_1c = 0; dp_1d = 0; dp_1e = 0; dp_1f = 0;
			dp_2a = 0; dp_2b = 0; dp_2c = 0; dp_2d = 0; dp_2e = 0; dp_2f = 0;
		end
	endcase
	end
	else begin
		dp_0a = 0; dp_0b = 0; dp_0c = 0; dp_0d = 0; dp_0e = 0; dp_0f = 0;
		dp_1a = 0; dp_1b = 0; dp_1c = 0; dp_1d = 0; dp_1e = 0; dp_1f = 0;
		dp_2a = 0; dp_2b = 0; dp_2c = 0; dp_2d = 0; dp_2e = 0; dp_2f = 0;
	end
end

//add + sigmoid add
always@ (*) begin
	if(current_state == CAL) begin
		case(count)
		2: begin //1 + exp(-a)
			add_0a = exp_reg[0]; add_0b = 32'b00111111100000000000000000000000;
			add_1a = exp_reg[1]; add_1b = 32'b00111111100000000000000000000000;
			add_2a = exp_reg[2]; add_2b = 32'b00111111100000000000000000000000;
		end
		6: begin //b = U * x2 + W * h1
			add_0a = dp_reg[0]; add_0b = dp_reg[3];
			add_1a = dp_reg[1]; add_1b = dp_reg[4];
			add_2a = dp_reg[2]; add_2b = dp_reg[5];
		end
		8: begin //1 + exp(-b)
			add_0a = exp_reg[0]; add_0b = 32'b00111111100000000000000000000000;
			add_1a = exp_reg[1]; add_1b = 32'b00111111100000000000000000000000;
			add_2a = exp_reg[2]; add_2b = 32'b00111111100000000000000000000000;
		end
		12: begin //c = U * x3 + W * h2
			add_0a = dp_reg[0]; add_0b = dp_reg[3];
			add_1a = dp_reg[1]; add_1b = dp_reg[4];
			add_2a = dp_reg[2]; add_2b = dp_reg[5];
		end
		14: begin //1 + exp(-c)
			add_0a = exp_reg[0]; add_0b = 32'b00111111100000000000000000000000;
			add_1a = exp_reg[1]; add_1b = 32'b00111111100000000000000000000000;
			add_2a = exp_reg[2]; add_2b = 32'b00111111100000000000000000000000;
		end
		default: begin
			add_0a = 0; add_0b = 0;
			add_1a = 0; add_1b = 0;
			add_2a = 0; add_2b = 0;
		end
		endcase
	end
	else begin
		add_0a = 0; add_0b = 0;
		add_1a = 0; add_1b = 0;
		add_2a = 0; add_2b = 0;
	end
end

//sigmoid exp
always@ (*) begin
	if(current_state == CAL) begin
		case(count)
		1: begin //exp(-a)
			exp_0a = {~(dp_reg[0][31]), dp_reg[0][30:0]};
			exp_1a = {~(dp_reg[1][31]), dp_reg[1][30:0]};
			exp_2a = {~(dp_reg[2][31]), dp_reg[2][30:0]};
		end
		7: begin //exp(-b)
			exp_0a = {~(add_reg[0][31]), add_reg[0][30:0]};
			exp_1a = {~(add_reg[1][31]), add_reg[1][30:0]};
			exp_2a = {~(add_reg[2][31]), add_reg[2][30:0]};
		end
		13: begin //exp(-c)
			exp_0a = {~(add_reg[0][31]), add_reg[0][30:0]};
			exp_1a = {~(add_reg[1][31]), add_reg[1][30:0]};
			exp_2a = {~(add_reg[2][31]), add_reg[2][30:0]};
		end
		default: begin
			exp_0a = 0;
			exp_1a = 0;
			exp_2a = 0;
		end
		endcase
	end
	else begin
		exp_0a = 0;
		exp_1a = 0;
		exp_2a = 0;
	end
end

//sigmoid recip
always@ (*) begin
	if(current_state == CAL) begin
		case(count)
		3: begin // h1 = 1 / (1 + exp(-a))
			recip_0a = add_reg[0];
			recip_1a = add_reg[1];
			recip_2a = add_reg[2];
		end
		9: begin // h2 = 1 / (1 + exp(-b))
			recip_0a = add_reg[0];
			recip_1a = add_reg[1];
			recip_2a = add_reg[2];
		end
		15: begin // h3 = 1 / (1 + exp(-c))
			recip_0a = add_reg[0];
			recip_1a = add_reg[1];
			recip_2a = add_reg[2];
		end
		default: begin
			recip_0a = 0;
			recip_1a = 0;
			recip_2a = 0;
		end
		endcase
	end
	else begin
		recip_0a = 0;
		recip_1a = 0;
		recip_2a = 0;
	end
end



//---------------------------------------------------------------------
//   IP OUTPUT CONTROL
//---------------------------------------------------------------------

//dp_reg
//0-2 for U * x, 3-5 for W * h, 6-8 for V * h
always@ (posedge clk /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 9; i = i + 1) begin
	// 		dp_reg[i] <= 0;
	// 	end
	// end
	// else begin
		if(current_state == CAL) begin
			case(count)
			0: begin
				dp_reg[0] <= dp_0z;
				dp_reg[1] <= dp_1z;
				dp_reg[2] <= dp_2z;
			end
			3: begin
				dp_reg[0] <= dp_0z;
				dp_reg[1] <= dp_1z;
				dp_reg[2] <= dp_2z;
			end
			// 4: begin
			// 	dp_reg[6] <= dp_0z;
			// 	dp_reg[7] <= dp_1z;
			// 	dp_reg[8] <= dp_2z;
			// end
			5: begin
				dp_reg[3] <= dp_0z;
				dp_reg[4] <= dp_1z;
				dp_reg[5] <= dp_2z;
			end
			9: begin
				dp_reg[0] <= dp_0z;
				dp_reg[1] <= dp_1z;
				dp_reg[2] <= dp_2z;
			end
			// 10: begin
			// 	dp_reg[6] <= dp_0z;
			// 	dp_reg[7] <= dp_1z;
			// 	dp_reg[8] <= dp_2z;
			// end
			11: begin
				dp_reg[3] <= dp_0z;
				dp_reg[4] <= dp_1z;
				dp_reg[5] <= dp_2z;
			end
			// 16: begin
			// 	dp_reg[6] <= dp_0z;
			// 	dp_reg[7] <= dp_1z;
			// 	dp_reg[8] <= dp_2z;
			// end
			// default: begin
			// 	for(i = 0; i < 9; i = i + 1) begin
			// 		dp_reg[i] <= 0;
			// 	end
			// end
			endcase
		end
	//end
end

//exp_reg
always@ (posedge clk /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 3; i = i + 1) begin
	// 		exp_reg[i] <= 0;
	// 	end
	// end
	// else begin
		if(current_state == CAL) begin
			exp_reg[0] <= exp_0z;
			exp_reg[1] <= exp_1z;
			exp_reg[2] <= exp_2z;
		end
	//end
end

//add_reg
always@ (posedge clk  /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 3; i = i + 1) begin
	// 		add_reg[i] <= 0;
	// 	end
	// end
	// else begin
		if(current_state == CAL) begin
			add_reg[0] <= add_0z;
			add_reg[1] <= add_1z;
			add_reg[2] <= add_2z;
		end
	//end
end

//recip_reg = h
always@ (posedge clk  /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 3; i = i + 1) begin
	// 		h[i] <= 0;
	// 	end
	// end
	// else begin
		if(current_state == CAL) begin
			case(count)
			3: begin //h1
				h[0] <= recip_0z;
				h[1] <= recip_1z;
				h[2] <= recip_2z;
			end
			9: begin //h2
				h[0] <= recip_0z;
				h[1] <= recip_1z;
				h[2] <= recip_2z;
			end
			15: begin //h3
				h[0] <= recip_0z;
				h[1] <= recip_1z;
				h[2] <= recip_2z;
			end
			endcase
			// h[0] <= recip_0z;
			// h[1] <= recip_1z;
			// h[2] <= recip_2z;
		end
	//end
end

//---------------------------------------------------------------------
//   OUTPUT LOGIC
//---------------------------------------------------------------------

//relu & y
always@ (posedge clk /*or negedge rst_n*/) begin
	// if(!rst_n) begin
	// 	for(i = 0; i < 9; i = i + 1) begin
	// 		y[i] <= 0;
	// 	end
	// end
	//else begin
		if(current_state == IDLE) begin
			for(i = 0; i < 9; i = i + 1) begin
				y[i] <= 0;
			end
		end
		else if(current_state == CAL) begin
			case(count)
			4: begin
				y[0] <= (dp_0z[31] == 0) ? dp_0z : 32'b00000000000000000000000000000000; //y10
				y[1] <= (dp_1z[31] == 0) ? dp_1z : 32'b00000000000000000000000000000000; //y11
				y[2] <= (dp_2z[31] == 0) ? dp_2z : 32'b00000000000000000000000000000000; //y12
			end
			10: begin
				y[3] <= (dp_0z[31] == 0) ? dp_0z : 32'b00000000000000000000000000000000; //y20
				y[4] <= (dp_1z[31] == 0) ? dp_1z : 32'b00000000000000000000000000000000; //y21
				y[5] <= (dp_2z[31] == 0) ? dp_2z : 32'b00000000000000000000000000000000; //y22
			end
			16: begin
				y[6] <= (dp_0z[31] == 0) ? dp_0z : 32'b00000000000000000000000000000000; //y30
				y[7] <= (dp_1z[31] == 0) ? dp_1z : 32'b00000000000000000000000000000000; //y31
				y[8] <= (dp_2z[31] == 0) ? dp_2z : 32'b00000000000000000000000000000000; //y32
			end
			default: begin
				for(i = 0; i < 9; i = i + 1) begin
					y[i] <= y[i];
				end
			end
			endcase
		end
	//end
end

//out_valid
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
		if(current_state == CAL) begin
			if(count >= 11 && count <= 19) begin
				out_valid <= 1;
			end
			else begin
				out_valid <= 0;
			end
		end
		else begin
			out_valid <= 0;
		end
	end
end

//out
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out <= 0;
	end
	else begin
		if(current_state == CAL) begin
			case(count)
			11: out <= y[0];
			12: out <= y[1];
			13: out <= y[2];
			14: out <= y[3];
			15: out <= y[4];
			16: out <= y[5];
			17: out <= y[6];
			18: out <= y[7];
			19: out <= y[8];
			default: out <= 0;
			endcase
		end
		else begin
			out <= 0;
		end
	end
end

endmodule