//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_prod_sum_pipe.v"
`include "/usr/synthesis/dw/sim_ver/DW02_prod_sum.v"
//synopsys translate_on

module MMSA(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    i_mat_idx,
    w_mat_idx,

// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [15:0] matrix;
input [1:0]  matrix_size;
input [3:0]  i_mat_idx, w_mat_idx;

output reg       	     out_valid;
output reg signed [39:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
//fsm
parameter IDLE = 0;
parameter INPUT = 1;
parameter CAL = 2; //multiplication
parameter OUTPUT = 3;

//designware parameter
parameter a_width = 16;
parameter b_width = 16;
parameter num_inputs = 16;
parameter num_stages = 2; //default = 2
parameter stall_mode = 1; //default = 1
parameter rst_mode = 1; //default = 1
parameter sum_width = 40;
parameter op_iso_mode = 0; //default = 0

//matrix size
parameter two = 2'b00;
parameter four = 2'b01;
parameter eight = 2'b10;
parameter sixteen = 2'b11;

integer j;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [1:0] next_state, current_state;
reg [8:0] step; //mul counter
reg [3:0] sram_num_count; //write
reg [7:0] addr_count;
reg [7:0] addr_weight_count;
reg [7:0] addr_offset;
reg [4:0] in_valid2_count; //count to 16
reg [8:0] add_count;
reg finish_input_x;
reg [1:0] size_reg;
reg [3:0] i_mat_idx_reg, w_mat_idx_reg;

//sram
wire [15:0] q_i_0, q_i_1, q_i_2, q_i_3, q_i_4, q_i_5, q_i_6, q_i_7, q_i_8, q_i_9, q_i_10, q_i_11, q_i_12, q_i_13, q_i_14, q_i_15;
wire [15:0] q_w_0, q_w_1, q_w_2, q_w_3, q_w_4, q_w_5, q_w_6, q_w_7, q_w_8, q_w_9, q_w_10, q_w_11, q_w_12, q_w_13, q_w_14, q_w_15;
reg [7:0] addr_i;
reg [7:0] addr_w;
reg [15:0] data_i;
reg [15:0] data_w;
reg wen_i_0, wen_i_1, wen_i_2, wen_i_3, wen_i_4, wen_i_5, wen_i_6, wen_i_7, wen_i_8, wen_i_9, wen_i_10, wen_i_11, wen_i_12, wen_i_13, wen_i_14, wen_i_15;
reg wen_w_0, wen_w_1, wen_w_2, wen_w_3, wen_w_4, wen_w_5, wen_w_6, wen_w_7, wen_w_8, wen_w_9, wen_w_10, wen_w_11, wen_w_12, wen_w_13, wen_w_14, wen_w_15;

//output reg
reg [15:0] q_i_reg [0:15];
reg [15:0] q_w_reg [0:15];
reg signed [39:0] result [0:30];
wire signed [39:0] sum_reg;

//---------------------------------------------------------------------
//   SRAM
//---------------------------------------------------------------------
//input
RA1SH_256_16 mem_i_0(.Q(q_i_0), .CLK(clk), .CEN(1'b0), .WEN(wen_i_0), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_1(.Q(q_i_1), .CLK(clk), .CEN(1'b0), .WEN(wen_i_1), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_2(.Q(q_i_2), .CLK(clk), .CEN(1'b0), .WEN(wen_i_2), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_3(.Q(q_i_3), .CLK(clk), .CEN(1'b0), .WEN(wen_i_3), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_4(.Q(q_i_4), .CLK(clk), .CEN(1'b0), .WEN(wen_i_4), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_5(.Q(q_i_5), .CLK(clk), .CEN(1'b0), .WEN(wen_i_5), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_6(.Q(q_i_6), .CLK(clk), .CEN(1'b0), .WEN(wen_i_6), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_7(.Q(q_i_7), .CLK(clk), .CEN(1'b0), .WEN(wen_i_7), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_8(.Q(q_i_8), .CLK(clk), .CEN(1'b0), .WEN(wen_i_8), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_9(.Q(q_i_9), .CLK(clk), .CEN(1'b0), .WEN(wen_i_9), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_10(.Q(q_i_10), .CLK(clk), .CEN(1'b0), .WEN(wen_i_10), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_11(.Q(q_i_11), .CLK(clk), .CEN(1'b0), .WEN(wen_i_11), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_12(.Q(q_i_12), .CLK(clk), .CEN(1'b0), .WEN(wen_i_12), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_13(.Q(q_i_13), .CLK(clk), .CEN(1'b0), .WEN(wen_i_13), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_14(.Q(q_i_14), .CLK(clk), .CEN(1'b0), .WEN(wen_i_14), .A(addr_i), .D(data_i), .OEN(1'b0));
RA1SH_256_16 mem_i_15(.Q(q_i_15), .CLK(clk), .CEN(1'b0), .WEN(wen_i_15), .A(addr_i), .D(data_i), .OEN(1'b0));

//weight
RA1SH_256_16 mem_w_0(.Q(q_w_0), .CLK(clk), .CEN(1'b0), .WEN(wen_w_0), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_1(.Q(q_w_1), .CLK(clk), .CEN(1'b0), .WEN(wen_w_1), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_2(.Q(q_w_2), .CLK(clk), .CEN(1'b0), .WEN(wen_w_2), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_3(.Q(q_w_3), .CLK(clk), .CEN(1'b0), .WEN(wen_w_3), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_4(.Q(q_w_4), .CLK(clk), .CEN(1'b0), .WEN(wen_w_4), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_5(.Q(q_w_5), .CLK(clk), .CEN(1'b0), .WEN(wen_w_5), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_6(.Q(q_w_6), .CLK(clk), .CEN(1'b0), .WEN(wen_w_6), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_7(.Q(q_w_7), .CLK(clk), .CEN(1'b0), .WEN(wen_w_7), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_8(.Q(q_w_8), .CLK(clk), .CEN(1'b0), .WEN(wen_w_8), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_9(.Q(q_w_9), .CLK(clk), .CEN(1'b0), .WEN(wen_w_9), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_10(.Q(q_w_10), .CLK(clk), .CEN(1'b0), .WEN(wen_w_10), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_11(.Q(q_w_11), .CLK(clk), .CEN(1'b0), .WEN(wen_w_11), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_12(.Q(q_w_12), .CLK(clk), .CEN(1'b0), .WEN(wen_w_12), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_13(.Q(q_w_13), .CLK(clk), .CEN(1'b0), .WEN(wen_w_13), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_14(.Q(q_w_14), .CLK(clk), .CEN(1'b0), .WEN(wen_w_14), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_15(.Q(q_w_15), .CLK(clk), .CEN(1'b0), .WEN(wen_w_15), .A(addr_w), .D(data_w), .OEN(1'b0));

//---------------------------------------------------------------------
//   DESIGNWARE
//---------------------------------------------------------------------
//stallable pipelined generalized sum of products
DW_prod_sum_pipe #(a_width, b_width, num_inputs, sum_width, num_stages, stall_mode, rst_mode,  op_iso_mode) M0(
.clk(clk),
.rst_n(rst_n),
.en(1'b1),
.tc(1'b1),
.a({q_i_reg[0], q_i_reg[1], q_i_reg[2], q_i_reg[3], q_i_reg[4], q_i_reg[5], q_i_reg[6], q_i_reg[7], q_i_reg[8], q_i_reg[9], q_i_reg[10], q_i_reg[11], q_i_reg[12], q_i_reg[13], q_i_reg[14], q_i_reg[15]}),
.b({q_w_reg[0], q_w_reg[1], q_w_reg[2], q_w_reg[3], q_w_reg[4], q_w_reg[5], q_w_reg[6], q_w_reg[7], q_w_reg[8], q_w_reg[9], q_w_reg[10], q_w_reg[11], q_w_reg[12], q_w_reg[13], q_w_reg[14], q_w_reg[15]}),
.sum(sum_reg)
);

//---------------------------------------------------------------------
//   FINITE STATE MACHINE
//---------------------------------------------------------------------
//current state
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n)
    current_state <= IDLE;
  else
    current_state <= next_state;
end

//next state combinational logic
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
        if(size_reg == two && step == 7)
            next_state = OUTPUT;
        else if(size_reg == four && step == 19)
            next_state = OUTPUT;
        else if(size_reg == eight && step == 67)
            next_state = OUTPUT;
        else if(size_reg == sixteen && step == 259)
            next_state = OUTPUT;
        else
            next_state = CAL;
    end
    OUTPUT: begin
        case(size_reg)
        two: begin
            if(step == 3 && in_valid2_count == 16)
                next_state = IDLE;
            else if(step == 3 && in_valid2_count != 16) //not done yet
                next_state = CAL;
            else
                next_state = OUTPUT;
        end
        four: begin
            if(step == 7 && in_valid2_count == 16)
                next_state = IDLE;
            else if(step == 7 && in_valid2_count != 16) //not done yet
                next_state = CAL;
            else
                next_state = OUTPUT;
        end
        eight: begin
            if(step == 15 && in_valid2_count == 16)
                next_state = IDLE;
            else if(step == 15 && in_valid2_count != 16) //not done yet
                next_state = CAL;
            else
                next_state = OUTPUT;
        end
        sixteen: begin
            if(step == 31 && in_valid2_count == 16)
                next_state = IDLE;
            else if(step == 31 && in_valid2_count != 16) //not done yet
                next_state = CAL;
            else
                next_state = OUTPUT;
        end
        default: next_state = OUTPUT;
        endcase
    end
    default: next_state = current_state;
    endcase
end

//---------------------------------------------------------------------
//   INPUT BLOCK
//---------------------------------------------------------------------
//matrix_size
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        size_reg <= 0;
    end
    else begin
        if(in_valid && current_state == IDLE) begin
            size_reg <= matrix_size;
        end
        else begin
            size_reg <= size_reg;
        end
    end
end

//i_mat_idx_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        i_mat_idx_reg <= 0;
    end
    else begin
        if(in_valid2) begin
            i_mat_idx_reg <= i_mat_idx;
        end
        else if(current_state == OUTPUT) begin
            i_mat_idx_reg <= 0;
        end
        else begin
            i_mat_idx_reg <= i_mat_idx_reg;
        end
    end
end

//w_mat_idx_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        w_mat_idx_reg <= 0;
    end
    else begin
        if(in_valid2) begin
            w_mat_idx_reg <= w_mat_idx;
        end
        else if(current_state == OUTPUT) begin
            w_mat_idx_reg <= 0;
        end
        else begin
            w_mat_idx_reg <= w_mat_idx_reg;
        end
    end
end

//---------------------------------------------------------------------
//   COUNTER
//---------------------------------------------------------------------
//step
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        step <= 0;
    end
    else begin
        case(current_state)
        IDLE: begin
            step <= 0;
        end
        CAL: begin
            if(size_reg == two && step == 7)
                step <= 0;
            else if(size_reg == four && step == 19)
                step <= 0;
            else if(size_reg == eight && step == 67)
                step <= 0;
            else if(size_reg == sixteen && step ==259)
                step <= 0;
            else
                step <= step + 1;
        end
        OUTPUT: begin
            if(size_reg == two && step == 3)
                step <= 0;
            else if(size_reg == four && step == 7)
                step <= 0;
            else if(size_reg == eight && step == 15)
                step <= 0;
            else if(size_reg == sixteen && step == 31)
                step <= 0;
            else
                step <= step + 1;
        end
        default: step <= 0;
        endcase
    end
end

//in_valid2_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid2_count <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            in_valid2_count <= 0;
        end
        else if(current_state == CAL && in_valid2) begin
            in_valid2_count <= in_valid2_count + 1;
        end
        else if(current_state == OUTPUT) begin
            in_valid2_count <= in_valid2_count;
        end
    end
end

//---------------------------------------------------------------------
//   FLAG
//---------------------------------------------------------------------
//finish input x
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        finish_input_x <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            finish_input_x <= 0;
        end
        else if(in_valid && !finish_input_x) begin //write input
            if(size_reg == two && addr_count == 31 && sram_num_count == 1)
                finish_input_x <= 1;
            else if(size_reg == four && addr_count == 63 && sram_num_count == 3)
                finish_input_x <= 1;
            else if(size_reg == eight && addr_count == 127 && sram_num_count == 7)
                finish_input_x <= 1;
            else if(size_reg == sixteen && addr_count == 255 && sram_num_count == 15)
                finish_input_x <= 1;
            else begin
                finish_input_x <= 0;
            end
        end
        else if(current_state == INPUT && in_valid && finish_input_x) begin //write weight
            finish_input_x <= finish_input_x;
        end
        else begin
            finish_input_x <= 0;
        end
    end
end

//---------------------------------------------------------------------
//   SRAM CONTROL
//---------------------------------------------------------------------
//sram_num_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sram_num_count <= 0;
    end
    else begin
        if(in_valid && !finish_input_x) begin //write input
            case(size_reg)
            two: begin
                if(sram_num_count == 1)
                    sram_num_count <= 0;
                else
                    sram_num_count <= sram_num_count + 1;
            end
            four: begin
                if(sram_num_count == 3)
                    sram_num_count <= 0;
                else
                    sram_num_count <= sram_num_count + 1;
            end
            eight: begin
                if(sram_num_count == 7)
                    sram_num_count <= 0;
                else
                    sram_num_count <= sram_num_count + 1;
            end
            sixteen: begin
                if(sram_num_count == 15)
                    sram_num_count <= 0;
                else
                    sram_num_count <= sram_num_count + 1;
            end
            endcase
        end
        else if(in_valid && finish_input_x) begin //write weight
            case(size_reg)
            two: begin
                if(addr_weight_count == addr_offset + 1 && sram_num_count == 1)
                    sram_num_count <= 0;
                else if(addr_weight_count == addr_offset + 1 )
                    sram_num_count <= sram_num_count + 1;
                else
                    sram_num_count <= sram_num_count;
            end
            four: begin
                if(addr_weight_count == addr_offset + 3 && sram_num_count == 3)
                    sram_num_count <= 0;
                else if(addr_weight_count == addr_offset + 3 && sram_num_count != 3)
                    sram_num_count <= sram_num_count + 1;
                else
                    sram_num_count <= sram_num_count;
            end
            eight: begin
                if(addr_weight_count == addr_offset + 7 && sram_num_count == 7)
                    sram_num_count <= 0;
                else if(addr_weight_count == addr_offset + 7 && sram_num_count != 7)
                    sram_num_count <= sram_num_count + 1;
                else
                    sram_num_count <= sram_num_count;
            end
            sixteen: begin
                if(addr_weight_count == addr_offset + 15 && sram_num_count == 15)
                    sram_num_count <= 0;
                else if(addr_weight_count == addr_offset + 15 && sram_num_count != 15)
                    sram_num_count <= sram_num_count + 1;
                else
                    sram_num_count <= sram_num_count;
            end
            default: begin
                sram_num_count <= sram_num_count;
            end
            endcase
        end
        else begin
            sram_num_count <= 0;
        end
    end
end

//address count for input x
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_count <= 0;
    end
    else begin
        if(in_valid && !finish_input_x) begin //write input
            //reset to 0
            if(size_reg == two && addr_count == 31 && sram_num_count == 1)
                addr_count <= 0;
            else if(size_reg == four && addr_count == 63 && sram_num_count == 3)
                addr_count <= 0;
            else if(size_reg == eight && addr_count == 127 && sram_num_count == 7)
                addr_count <= 0;
            else if(size_reg == sixteen && addr_count == 255 && sram_num_count == 15)
                addr_count <= 0;
            else if(size_reg == two && sram_num_count == 1)
                addr_count <= addr_count + 1;
            else if(size_reg == four && sram_num_count == 3)
                addr_count <= addr_count + 1;
            else if(size_reg == eight && sram_num_count == 7)
                addr_count <= addr_count + 1;
            else if(size_reg == sixteen && sram_num_count == 15)
                addr_count <= addr_count + 1;
            else
                addr_count <= addr_count;
        end
        else if(current_state == CAL) begin
            case(size_reg)
            two: begin
                if(in_valid2)
                    addr_count <= i_mat_idx * 2;
                else if(addr_weight_count == (w_mat_idx_reg * 2) + 1)
                    addr_count <= addr_count + 1;
                else begin
                    addr_count <= addr_count;
                end
            end
            four: begin
                if(in_valid2)
                    addr_count <= i_mat_idx * 4;
                else if(addr_weight_count == (w_mat_idx_reg * 4) + 3)
                    addr_count <= addr_count + 1;
                else
                    addr_count <= addr_count;
            end
            eight: begin
                if(in_valid2)
                    addr_count <= i_mat_idx * 8;
                else if(addr_weight_count == (w_mat_idx_reg * 8) + 7)
                    addr_count <= addr_count + 1;
                else
                    addr_count <= addr_count;
            end
            sixteen: begin
                if(in_valid2)
                    addr_count <= i_mat_idx * 16;
                else if(addr_weight_count == (w_mat_idx_reg * 16) + 15)
                    addr_count <= addr_count + 1;
                else
                    addr_count <= addr_count;
            end
            default: addr_count <= addr_count;
            endcase
        end
        else begin
            addr_count <= 0;
        end
    end
end

//address count for weight
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_weight_count <= 0;
    end
    else begin
        if(in_valid && finish_input_x) begin
            case(size_reg)
            two: begin
                if(sram_num_count == 1 && addr_weight_count == addr_offset + 1)
                    addr_weight_count <= addr_offset + 2;
                else if(addr_weight_count == addr_offset + 1 && sram_num_count != 1)
                    addr_weight_count <= addr_offset;
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            four: begin
                if(sram_num_count == 3 && addr_weight_count == addr_offset + 3)
                    addr_weight_count <= addr_offset + 4;
                else if(addr_weight_count == addr_offset + 3 && sram_num_count != 3)
                    addr_weight_count <= addr_offset;
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            eight: begin
                if(sram_num_count == 7 && addr_weight_count == addr_offset + 7)
                    addr_weight_count <= addr_offset + 8;
                else if(addr_weight_count == addr_offset + 7 && sram_num_count != 7)
                    addr_weight_count <= addr_offset;
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            sixteen: begin
                if(sram_num_count == 15 && addr_weight_count == addr_offset + 15)
                    addr_weight_count <= addr_offset + 16;
                else if(addr_weight_count == addr_offset + 15 && sram_num_count != 15)
                    addr_weight_count <= addr_offset;
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            default: addr_weight_count <= addr_weight_count;
            endcase
        end
        else if(current_state == CAL) begin
            case(size_reg)
            two: begin
                if(in_valid2)
                    addr_weight_count <= w_mat_idx * 2;
                else if(addr_weight_count == (w_mat_idx_reg * 2) + 1)
                    addr_weight_count <= w_mat_idx_reg * 2; //return to initial address
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            four: begin
                if(in_valid2)
                    addr_weight_count <= w_mat_idx * 4;
                else if(addr_weight_count == (w_mat_idx_reg * 4) + 3)
                    addr_weight_count <= w_mat_idx_reg * 4; //return to initial address
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            eight: begin
                if(in_valid2)
                    addr_weight_count <= w_mat_idx * 8;
                else if(addr_weight_count == (w_mat_idx_reg * 8) + 7)
                    addr_weight_count <= w_mat_idx_reg * 8; //return to initial address
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            sixteen: begin
                if(in_valid2)
                    addr_weight_count <= w_mat_idx * 16;
                else if(addr_weight_count == (w_mat_idx_reg * 16) + 15)
                    addr_weight_count <= w_mat_idx_reg * 16; //return to initial address
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            default: addr_weight_count <= addr_weight_count;
            endcase
        end
        else begin
            addr_weight_count <= 0;
        end
    end
end

//addr_offset for weight storing
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_offset <= 0;
    end
    else begin
        if(in_valid && finish_input_x) begin //write weight
            case(size_reg)
            two: begin
                if(addr_weight_count == addr_offset + 1 && sram_num_count == 1)
                    addr_offset <= addr_offset + 2;
                else
                    addr_offset <= addr_offset;
            end
            four: begin
                if(addr_weight_count == addr_offset + 3 && sram_num_count == 3)
                    addr_offset <= addr_offset + 4;
                else
                    addr_offset <= addr_offset;
            end
            eight: begin
                if(addr_weight_count == addr_offset + 7 && sram_num_count == 7)
                    addr_offset <= addr_offset + 8;
                else
                    addr_offset <= addr_offset;
            end
            sixteen: begin
                if(addr_weight_count == addr_offset + 15 && sram_num_count == 15)
                    addr_offset <= addr_offset + 16;
                else
                    addr_offset <= addr_offset;
            end
            default: addr_offset <= addr_offset;
            endcase
        end
        else begin
            addr_offset <= 0;
        end
    end
end

//addr_i
always@ (*) begin
    if(current_state == IDLE)
        addr_i = 0;
    else if(in_valid && !finish_input_x)
        addr_i = addr_count;
    else if(in_valid && finish_input_x)
        addr_i = 0;
    else if(current_state == CAL)
        addr_i = addr_count;
    else
        addr_i = 0;
end

//addr_w
always@ (*) begin
    if(current_state == IDLE)
        addr_w = 0;
    else if(in_valid && !finish_input_x)
        addr_w = 0;
    else if( in_valid && finish_input_x)
        addr_w = addr_weight_count;
    else if(current_state == CAL)
        addr_w = addr_weight_count;
    else
        addr_w = 0;
end

//data_i
always@ (*) begin
    if(current_state == IDLE)
        data_i = matrix;
    else if( in_valid && !finish_input_x)
        data_i = matrix;
    else if( in_valid && finish_input_x)
        data_i = 0;
    else begin
        data_i = 0;
    end
end

//data_w
always@ (*) begin
    if(in_valid && finish_input_x)
        data_w = matrix;
    else begin
        data_w = 0;
    end
end

//wen_i
always@ (*) begin
    if(in_valid && !finish_input_x) begin //write input
        case(sram_num_count)
        0: begin
            wen_i_0 = 0; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        1: begin
            wen_i_0 = 1; wen_i_1 = 0; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        2: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 0; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        3: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 0; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        4: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 0; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        5: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 0; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        6: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 0; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        7: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 0;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        8: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 0; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        9: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 0; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        10: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 0; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        11: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 0; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        12: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 0; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        13: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 0; wen_i_14 = 1; wen_i_15 = 1;
        end
        14: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 0; wen_i_15 = 1;
        end
        default: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 0;
        end
        endcase
    end
    else if(in_valid && finish_input_x) begin
        wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
        wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
    end
    else if(current_state == CAL) begin
        wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
        wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
    end
    else begin
        wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
        wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
    end
end

//wen_w
always@ (*) begin
    if( in_valid && !finish_input_x) begin
        wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
        wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
    end
    if(in_valid && finish_input_x) begin
        case(sram_num_count)
        0: begin
            wen_w_0 = 0; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        1: begin
            wen_w_0 = 1; wen_w_1 = 0; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        2: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 0; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        3: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 0; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        4: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 0; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        5: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 0; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        6: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 0; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        7: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 0;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        8: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 0; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        9: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 0; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        10: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 0; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        11: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 0; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        12: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 0; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        13: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 0; wen_w_14 = 1; wen_w_15 = 1;
        end
        14: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 0; wen_w_15 = 1;
        end
        default: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 0;
        end
        endcase
    end
    else if(current_state == CAL) begin
        wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
        wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
    end
    else begin
        wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
        wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
    end
end

//---------------------------------------------------------------------
//   CALCULATION
//---------------------------------------------------------------------
//q_i_reg: dff block sram output
always@ (posedge clk  /*or negedge rst_n*/) begin
    if(current_state == CAL) begin
        case(size_reg)
        two: begin
            q_i_reg[0] <= q_i_0; q_i_reg[1] <= q_i_1;
            for(j = 2; j < 16; j = j + 1) begin
                q_i_reg[j] <= 0;
            end
        end
        four: begin
            q_i_reg[0] <= q_i_0; q_i_reg[1] <= q_i_1; q_i_reg[2] <= q_i_2; q_i_reg[3] <= q_i_3;
            for(j = 4; j < 16; j = j + 1) begin
                q_i_reg[j] <= 0;
            end
        end
        eight: begin
            q_i_reg[0] <= q_i_0; q_i_reg[1] <= q_i_1; q_i_reg[2] <= q_i_2; q_i_reg[3] <= q_i_3; q_i_reg[4] <= q_i_4; q_i_reg[5] <= q_i_5; q_i_reg[6] <= q_i_6; q_i_reg[7] <= q_i_7;
            for(j = 8; j < 16; j = j + 1) begin
                q_i_reg[j] <= 0;
            end
        end
        sixteen: begin
            q_i_reg[0] <= q_i_0; q_i_reg[1] <= q_i_1; q_i_reg[2] <= q_i_2; q_i_reg[3] <= q_i_3; q_i_reg[4] <= q_i_4; q_i_reg[5] <= q_i_5; q_i_reg[6] <= q_i_6; q_i_reg[7] <= q_i_7;
            q_i_reg[8] <= q_i_8; q_i_reg[9] <= q_i_9; q_i_reg[10] <= q_i_10; q_i_reg[11] <= q_i_11; q_i_reg[12] <= q_i_12; q_i_reg[13] <= q_i_13; q_i_reg[14] <= q_i_14; q_i_reg[15] <= q_i_15;
        end
        endcase
    end
end

//q_w_reg: dff block sram output
always@ (posedge clk /*or negedge rst_n*/) begin
    // if(!rst_n) begin
    //     for(j = 0; j < 16; j = j + 1) begin
    //         q_w_reg[j] <= 0;
    //     end
    // end
    // else begin
        if(current_state == CAL) begin
            case(size_reg)
            two: begin
                q_w_reg[0] <= q_w_0; q_w_reg[1] <= q_w_1;
                for(j = 2; j < 16; j = j + 1) begin
                    q_w_reg[j] <= 0;
                end
            end
            four: begin
                q_w_reg[0] <= q_w_0; q_w_reg[1] <= q_w_1; q_w_reg[2] <= q_w_2; q_w_reg[3] <= q_w_3;
                for(j = 4; j < 16; j = j + 1) begin
                    q_w_reg[j] <= 0;
                end
            end
            eight: begin
                q_w_reg[0] <= q_w_0; q_w_reg[1] <= q_w_1; q_w_reg[2] <= q_w_2; q_w_reg[3] <= q_w_3; q_w_reg[4] <= q_w_4; q_w_reg[5] <= q_w_5; q_w_reg[6] <= q_w_6; q_w_reg[7] <= q_w_7;
                for(j = 8; j < 16; j = j + 1) begin
                    q_w_reg[j] <= 0;
                end
            end
            sixteen: begin
                q_w_reg[0] <= q_w_0; q_w_reg[1] <= q_w_1; q_w_reg[2] <= q_w_2; q_w_reg[3] <= q_w_3; q_w_reg[4] <= q_w_4; q_w_reg[5] <= q_w_5; q_w_reg[6] <= q_w_6; q_w_reg[7] <= q_w_7;
                q_w_reg[8] <= q_w_8; q_w_reg[9] <= q_w_9; q_w_reg[10] <= q_w_10; q_w_reg[11] <= q_w_11; q_w_reg[12] <= q_w_12; q_w_reg[13] <= q_w_13; q_w_reg[14] <= q_w_14; q_w_reg[15] <= q_w_15;
            end
            endcase
        end
    //end
end

//---------------------------------------------------------------------
//   OUTPUT BLOCK
//---------------------------------------------------------------------
//result
always@ (posedge clk /*or negedge rst_n*/) begin
    // if(!rst_n) begin
    //     for(j = 0; j < 31; j = j + 1) begin
    //         result[j] <= 0;
    //     end
    // end
    //else begin
        if(in_valid2) begin
            for(j = 0; j < 31; j = j + 1) begin
                result[j] <= 0;
            end
        end
        else if(current_state == CAL) begin
            if(size_reg == two) begin
                case(step)
                4:    result[0] <= sum_reg;
                5, 6: result[1] <= result[1] + sum_reg;
                7:    result[2] <= sum_reg;
                endcase
            end
            else if(size_reg == four) begin
                case(step)
                4:             result[0] <= sum_reg;
                5, 8:          result[1] <= result[1] + sum_reg;
                6, 9, 12:      result[2] <= result[2] + sum_reg;
                7, 10, 13, 16: result[3] <= result[3] + sum_reg;
                11, 14, 17:    result[4] <= result[4] + sum_reg;
                15, 18:        result[5] <= result[5] + sum_reg;
                19:            result[6] <= sum_reg;
                endcase
            end
            else if(size_reg == eight) begin
                case(step)
                4:                              result[0] <= sum_reg;
                5, 12:                          result[1] <= result[1] + sum_reg;
                6, 13, 20:                      result[2] <= result[2] + sum_reg;
                7, 14, 21, 28:                  result[3] <= result[3] + sum_reg;
                8, 15, 22, 29, 36:              result[4] <= result[4] + sum_reg;
                9, 16, 23, 30, 37, 44:          result[5] <= result[5] + sum_reg;
                10, 17, 24, 31, 38, 45, 52:     result[6] <= result[6] + sum_reg;
                11, 18, 25, 32, 39, 46, 53, 60: result[7] <= result[7] + sum_reg;
                19, 26, 33, 40, 47, 54, 61:     result[8] <= result[8] + sum_reg;
                27, 34, 41, 48, 55, 62:         result[9] <= result[9] + sum_reg;
                35, 42, 49, 56, 63:             result[10] <= result[10] + sum_reg;
                43, 50, 57, 64:                 result[11] <= result[11] + sum_reg;
                51, 58, 65:                     result[12] <= result[12] + sum_reg;
                59, 66:                         result[13] <= result[13] + sum_reg;
                67:                             result[14] <= sum_reg;
                endcase
            end
            else if(size_reg == sixteen) begin
                case(step)
                4:                                                                        result[0] <= sum_reg;
                5, 20:                                                                    result[1] <= result[1] + sum_reg;
                6, 21, 36:                                                                result[2] <= result[2] + sum_reg;
                7, 22, 37, 52:                                                            result[3] <= result[3] + sum_reg;
                8, 23, 38, 53, 68:                                                        result[4] <= result[4] + sum_reg;
                9, 24, 39, 54, 69, 84:                                                    result[5] <= result[5] + sum_reg;
                10, 25, 40, 55, 70, 85, 100:                                              result[6] <= result[6] + sum_reg;
                11, 26, 41, 56, 71, 86, 101, 116:                                         result[7] <= result[7] + sum_reg;
                12, 27, 42, 57, 72, 87, 102, 117, 132:                                    result[8] <= result[8] + sum_reg;
                13, 28, 43, 58, 73, 88, 103, 118, 133, 148:                               result[9] <= result[9] + sum_reg;
                14, 29, 44, 59, 74, 89, 104, 119, 134, 149, 164:                          result[10] <= result[10] + sum_reg;
                15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180:                     result[11] <= result[11] + sum_reg;
                16, 31, 46, 61, 76, 91, 106, 121, 136, 151, 166, 181, 196:                result[12] <= result[12] + sum_reg;
                17, 32, 47, 62, 77, 92, 107, 122, 137, 152, 167, 182, 197, 212:           result[13] <= result[13] + sum_reg;
                18, 33, 48, 63, 78, 93, 108, 123, 138, 153, 168, 183, 198, 213, 228:      result[14] <= result[14] + sum_reg;
                19, 34, 49, 64, 79, 94, 109, 124, 139, 154, 169, 184, 199, 214, 229, 244: result[15] <= result[15] + sum_reg;
                35, 50, 65, 80, 95, 110, 125, 140, 155, 170, 185, 200, 215, 230, 245:     result[16] <= result[16] + sum_reg;
                51, 66, 81, 96, 111, 126, 141, 156, 171, 186, 201, 216, 231, 246:         result[17] <= result[17] + sum_reg;
                67, 82, 97, 112, 127, 142, 157, 172, 187, 202, 217, 232, 247:             result[18] <= result[18] + sum_reg;
                83, 98, 113, 128, 143, 158, 173, 188, 203, 218, 233, 248:                 result[19] <= result[19] + sum_reg;
                99, 114, 129, 144, 159, 174, 189, 204, 219, 234, 249:                     result[20] <= result[20] + sum_reg;
                115, 130, 145, 160, 175, 190, 205, 220, 235, 250:                         result[21] <= result[21] + sum_reg;
                131, 146, 161, 176, 191, 206, 221, 236, 251:                              result[22] <= result[22] + sum_reg;
                147, 162, 177, 192, 207, 222, 237, 252:                                   result[23] <= result[23] + sum_reg;
                163, 178, 193, 208, 223, 238, 253:                                        result[24] <= result[24] + sum_reg;
                179, 194, 209, 224, 239, 254:                                             result[25] <= result[25] + sum_reg;
                195, 210, 225, 240, 255:                                                  result[26] <= result[26] + sum_reg;
                211, 226, 241, 256:                                                       result[27] <= result[27] + sum_reg;
                227, 242, 257:                                                            result[28] <= result[28] + sum_reg;
                243, 258:                                                                 result[29] <= result[29] + sum_reg;
                259:                                                                      result[30] <= sum_reg;
                endcase
            end
        end
    //end
end

//out_valid
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if(current_state == OUTPUT) begin
            case(size_reg)
            two: begin
                if(step == 3)
                    out_valid <= 0;
                else
                    out_valid <= 1;
            end
            four: begin
                if(step == 7)
                    out_valid <= 0;
                else
                    out_valid <= 1;
            end
            eight: begin
                if(step == 15)
                    out_valid <= 0;
                else
                    out_valid <= 1;
            end
            sixteen: begin
                if(step == 31)
                    out_valid <= 0;
                else
                    out_valid <= 1;
            end
            default: out_valid <= 0;
            endcase
        end
        else begin
            out_valid <= 0;
        end
    end
end

//out_value
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_value <= 0;
    end
    else begin
        if(current_state == OUTPUT) begin
            out_value <= result[step];
        end
        else begin
            out_value <= 0;
        end
    end
end

endmodule

