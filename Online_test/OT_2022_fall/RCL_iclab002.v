module RCL(
    clk,
    rst_n,
    in_valid,
    coef_Q,
    coef_L,
    out_valid,
    out
);

//input and output declaration
input clk, rst_n, in_valid;
input signed [4:0] coef_Q;
input signed [4:0] coef_L;
output reg out_valid;
output reg [1:0] out;

//wire and register declaration
reg [4:0] count;
reg signed [4:0] a, b, c, m, n;
reg [4:0] k;
wire signed [11:0] a_m; //a*m
wire signed [11:0] b_n; //b*n
wire [11:0] a_a; //a^2
wire [11:0] b_b; //b^2
wire [23:0] rhs; //a*m+b*n+c
wire [23:0] lhs; //a^2+b^2

//counter
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 0;
	end
	else begin
		if(in_valid) begin
			count <= count + 1;
		end
		else if(count == 3) begin
			count <= 0;
		end

	end
end

//input block
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		a <= 0;
		b <= 0;
		c <= 0;
		m <= 0;
		n <= 0;
		k <= 0;
	end
	else begin
		if(count == 0) begin
			a <= coef_L;
			m <= coef_Q;
		end
		else if(count == 1) begin
			b <= coef_L;
			n <= coef_Q;
		end
		else if(count == 2) begin
			c <= coef_L;
			k <= $unsigned(coef_Q);
		end
		else begin
			a <= a;
			b <= b;
			c <= c;
			m <= m;
			n <= n;
			k <= k;
		end
	end
end

//output logic
//out_valid
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
		if(count == 3) begin
			out_valid <= 1;
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
		if(count == 3) begin
			if(lhs > rhs) begin // 2 intersections
				out <= 2;
			end
			else if(lhs == rhs) begin // 1 intersection
				out <= 1;
			end
			else begin //no intersection
				out <= 0;
			end
		end
		else begin
			out <= 0;
		end
	end

end

//calculation
assign a_a = a * a;
assign a_m = a * m;
assign b_b = b * b;
assign b_n = b * n;
assign rhs = (count == 3) ? ((a_m + b_n + c) * (a_m + b_n + c)) : 0;
assign lhs = (count == 3) ? ((a_a + b_b) * k) : 0;

endmodule
