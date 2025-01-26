//=================================
//
// Lab11 MMSA.v
//
//=================================

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
input clk, rst_n, in_valid, in_valid2;
input matrix;
input [1:0] matrix_size;
input i_mat_idx, w_mat_idx;

output reg out_valid;
output reg out_value;
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
parameter num_inputs = 8;
parameter num_stages = 2; //default = 2
parameter stall_mode = 1; //default = 1
parameter rst_mode = 1; //default = 1
parameter sum_width = 40;
parameter op_iso_mode = 0; //default = 0

//matrix size
parameter two = 2'b00;
parameter four = 2'b01;
parameter eight = 2'b10;
//parameter sixteen = 2'b11;

integer i;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [1:0] next_state, current_state;
reg [8:0] step;
reg [3:0] sram_num_count; //write
reg [7:0] addr_count;
reg [7:0] addr_weight_count;
reg [7:0] addr_offset;
reg [7:0] count;
reg [6:0] flag_count;
reg [6:0] in_valid2_count;
reg [3:0] group_count; //max to 15
reg [5:0] out_valid_count; //max to 40
reg finish_input_x;
reg sram_flag;
reg length_flag;
reg [1:0] size_reg;
reg i_mat_idx_reg [3:0];
reg w_mat_idx_reg [3:0];
reg [3:0] i_mat_idx_actual;
reg [3:0] w_mat_idx_actual;
reg matrix_reg [15:0];
reg [14:0] matrix_actual;
reg [5:0] length_temp;

//sram
wire [15:0] q_i_0, q_i_1, q_i_2, q_i_3, q_i_4, q_i_5, q_i_6, q_i_7/*, q_i_8, q_i_9, q_i_10, q_i_11, q_i_12, q_i_13, q_i_14, q_i_15*/;
wire [15:0] q_w_0, q_w_1, q_w_2, q_w_3, q_w_4, q_w_5, q_w_6, q_w_7/*, q_w_8, q_w_9, q_w_10, q_w_11, q_w_12, q_w_13, q_w_14, q_w_15*/;
reg [7:0] addr_i;
reg [7:0] addr_w;
reg [15:0] data_i;
reg [15:0] data_w;
reg wen_i_0, wen_i_1, wen_i_2, wen_i_3, wen_i_4, wen_i_5, wen_i_6, wen_i_7/*, wen_i_8, wen_i_9, wen_i_10, wen_i_11, wen_i_12, wen_i_13, wen_i_14, wen_i_15*/;
reg wen_w_0, wen_w_1, wen_w_2, wen_w_3, wen_w_4, wen_w_5, wen_w_6, wen_w_7/*, wen_w_8, wen_w_9, wen_w_10, wen_w_11, wen_w_12, wen_w_13, wen_w_14, wen_w_15*/;

//output reg
reg [15:0] q_i_reg [0:7];
reg [15:0] q_w_reg [0:7];
reg signed [39:0] result [0:14];
wire signed [39:0] sum_reg;


//---------------------------------------------------------------------
//   DESIGNWARE
//---------------------------------------------------------------------
//stallable pipelined generalized sum of products
DW_prod_sum_pipe #(a_width, b_width, num_inputs, sum_width, num_stages, stall_mode, rst_mode, op_iso_mode) M0(
.clk(clk),
.rst_n(rst_n),
.en(1'b1),
.tc(1'b1),
.a({q_i_reg[0], q_i_reg[1], q_i_reg[2], q_i_reg[3], q_i_reg[4], q_i_reg[5], q_i_reg[6], q_i_reg[7]/*, q_i_reg[8], q_i_reg[9], q_i_reg[10], q_i_reg[11], q_i_reg[12], q_i_reg[13], q_i_reg[14], q_i_reg[15]*/}),
.b({q_w_reg[0], q_w_reg[1], q_w_reg[2], q_w_reg[3], q_w_reg[4], q_w_reg[5], q_w_reg[6], q_w_reg[7]/*, q_w_reg[8], q_w_reg[9], q_w_reg[10], q_w_reg[11], q_w_reg[12], q_w_reg[13], q_w_reg[14], q_w_reg[15]*/}),
.sum(sum_reg)
);

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


//weight
RA1SH_256_16 mem_w_0(.Q(q_w_0), .CLK(clk), .CEN(1'b0), .WEN(wen_w_0), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_1(.Q(q_w_1), .CLK(clk), .CEN(1'b0), .WEN(wen_w_1), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_2(.Q(q_w_2), .CLK(clk), .CEN(1'b0), .WEN(wen_w_2), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_3(.Q(q_w_3), .CLK(clk), .CEN(1'b0), .WEN(wen_w_3), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_4(.Q(q_w_4), .CLK(clk), .CEN(1'b0), .WEN(wen_w_4), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_5(.Q(q_w_5), .CLK(clk), .CEN(1'b0), .WEN(wen_w_5), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_6(.Q(q_w_6), .CLK(clk), .CEN(1'b0), .WEN(wen_w_6), .A(addr_w), .D(data_w), .OEN(1'b0));
RA1SH_256_16 mem_w_7(.Q(q_w_7), .CLK(clk), .CEN(1'b0), .WEN(wen_w_7), .A(addr_w), .D(data_w), .OEN(1'b0));

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
        else
            next_state = CAL;
    end
    OUTPUT: begin
        case(size_reg)
        two: begin
            // if(step == 3 && in_valid2_count == 16)
            //     next_state = IDLE;
            // else if(step == 3 && in_valid2_count != 16)
            //     next_state = CAL;
            if(in_valid2_count == 16 && group_count == 2 && out_valid_count == length_temp && length_flag) begin
                next_state = IDLE;
            end
            else if(in_valid2_count != 16 && group_count == 2 && out_valid_count == length_temp && length_flag) begin
                next_state = CAL;
            end
            else
                next_state = OUTPUT;
        end
        four: begin
            // if(step == 7 && in_valid2_count == 16)
            //     next_state = IDLE;
            // else if(step == 7 && in_valid2_count != 16)
            //     next_state = CAL;
            if(in_valid2_count == 16 && group_count == 6 && out_valid_count == length_temp && length_flag) begin
                next_state = IDLE;
            end
            else if(in_valid2_count != 16 && group_count == 6 && out_valid_count == length_temp && length_flag) begin
                next_state = CAL;
            end
            else
                next_state = OUTPUT;
        end
        eight: begin
            // if(step == 15 && in_valid2_count == 16)
            //     next_state = IDLE;
            // else if(step == 15 && in_valid2_count != 16)
            //     next_state = CAL;
            if(in_valid2_count == 16 && group_count == 14 && out_valid_count == length_temp && length_flag) begin
                next_state = IDLE;
            end
            else if(in_valid2_count != 16 && group_count == 14 && out_valid_count == length_temp && length_flag) begin
                next_state = CAL;
            end
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
        for(i = 0; i < 4; i = i + 1) begin
            i_mat_idx_reg[i] <= 0;
        end
    end
    else begin
        if(in_valid2) begin
            i_mat_idx_reg[count] <= i_mat_idx;
        end
        else if(current_state == OUTPUT) begin
            for(i = 0; i < 4; i = i + 1) begin
                i_mat_idx_reg[i] <= 0;
            end
        end
    end
end

always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        i_mat_idx_actual <= 0;
    end
    else begin
        if(current_state == CAL && in_valid2 && count == 3) begin
            i_mat_idx_actual <= {i_mat_idx_reg[0], i_mat_idx_reg[1], i_mat_idx_reg[2], i_mat_idx};
        end
    end
end

//w_mat_idx_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            w_mat_idx_reg[i] <= 0;
        end
    end
    else begin
        if(in_valid2) begin
            w_mat_idx_reg[count] <= w_mat_idx;
        end
        else if(current_state == OUTPUT) begin
            for(i = 0; i < 4; i = i + 1) begin
                w_mat_idx_reg[i] <= 0;
            end
        end
    end
end

always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        w_mat_idx_actual <= 0;
    end
    else begin
        if(current_state == CAL && in_valid2 && count == 3) begin
            w_mat_idx_actual <= {w_mat_idx_reg[0], w_mat_idx_reg[1], w_mat_idx_reg[2], w_mat_idx};
        end
    end
end

//matrix_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_reg[i] <= 0;
        end
    end
    else begin
        if(in_valid) begin
            matrix_reg[14] <= matrix;
            matrix_reg[13] <= matrix_reg[14];
            matrix_reg[12] <= matrix_reg[13];
            matrix_reg[11] <= matrix_reg[12];
            matrix_reg[10] <= matrix_reg[11];
            matrix_reg[9] <= matrix_reg[10];
            matrix_reg[8] <= matrix_reg[9];
            matrix_reg[7] <= matrix_reg[8];
            matrix_reg[6] <= matrix_reg[7];
            matrix_reg[5] <= matrix_reg[6];
            matrix_reg[4] <= matrix_reg[5];
            matrix_reg[3] <= matrix_reg[4];
            matrix_reg[2] <= matrix_reg[3];
            matrix_reg[1] <= matrix_reg[2];
            matrix_reg[0] <= matrix_reg[1];
        end
    end
end

//assign matrix_actual = (current_state == INPUT && count == 15) ? {matrix_reg[0], matrix_reg[1], matrix_reg[2], matrix_reg[3], matrix_reg[4], matrix_reg[5], matrix_reg[6], matrix_reg[7], matrix_reg[8], matrix_reg[9], matrix_reg[10], matrix_reg[11], matrix_reg[12], matrix_reg[13], matrix_reg[14], matrix} : 'd0;
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        matrix_actual <= 0;
    end
    else begin
        if(in_valid) begin
            //matrix_actual <= {matrix_reg[14], matrix_reg[13], matrix_reg[12], matrix_reg[11], matrix_reg[10], matrix_reg[9], matrix_reg[8], matrix_reg[7], matrix_reg[6], matrix_reg[5], matrix_reg[4], matrix_reg[3], matrix_reg[2], matrix_reg[1], matrix_reg[0]/*, matrix*/};
        end
        // else begin
        //     matrix_actual <= 0;
        // end
    end
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
        if(in_valid) begin
            if(count == 15) begin
                count <= 0;
            end
            else begin
                count <= count + 1;
            end
        end
        else if(current_state == CAL && in_valid2) begin
            if(count == 3) begin
                count <= 0;
            end
            else begin
                count <= count + 1;
            end
        end
        else if(current_state == OUTPUT) begin
            count <= count;
        end
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
        else if(current_state == CAL && in_valid2 && count == 3) begin
            
            in_valid2_count <= in_valid2_count + 1;
        end
    end
end

//step
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        step <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            step <= 0;
        end
        else if(current_state == CAL) begin
            // if(size_reg == two && step == 7)
            //     step <= 0;
            // else if(size_reg == four && step == 19)
            //     step <= 0;
            // else if(size_reg == eight && step == 67)
            //     step <= 0;
            // else begin
            //     step <= step + 1;
            // end
            if(size_reg == two) begin
                if(in_valid2 && count < 3) begin
                    step <= 0;
                end
                else if(next_state == OUTPUT) begin
                    step <= 0;
                end
                else begin
                    step <= step + 1;
                end
            end
            else if(size_reg == four) begin
                if(in_valid2 && count < 3) begin
                    step <= 0;
                end
                else if(next_state == OUTPUT) begin
                    step <= 0;
                end
                else begin
                    step <= step + 1;
                end
            end
            else if(size_reg == eight) begin
                if(in_valid2 && count < 3) begin
                    step <= 0;
                end
                else if(next_state == OUTPUT) begin
                    step <= 0;
                end
                else begin
                    step <= step + 1;
                end
            end
            
                
        end
        else if(current_state == OUTPUT) begin
            if(size_reg == two && step == 3)
                step <= 0;
            else if(size_reg == four && step == 7)
                step <= 0;
            else if(size_reg == eight && step == 15)
                step <= 0;
            else
                step <= step + 1;
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
            if(size_reg == two && addr_count == 31 && sram_num_count == 1 && count == 15)
                finish_input_x <= 1;
            else if(size_reg == four && addr_count == 63 && sram_num_count == 3 && count == 15)
                finish_input_x <= 1;
            else if(size_reg == eight && addr_count == 127 && sram_num_count == 7 && count == 15)
                finish_input_x <= 1;
            else begin
                finish_input_x <= 0;
            end
        end
        else if(current_state == INPUT && in_valid && finish_input_x) begin //write weight
            finish_input_x <= finish_input_x;
        end
        // else begin
        //     finish_input_x <= 0;
        // end
    end
end

// //sram_flag
// always@ (posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         sram_flag <= 0;
//     end
//     else begin
//         if(current_state == INPUT && step == 30) begin
//             sram_flag <= 1;
//         end
//     end
// end

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
                // if(!sram_flag) begin
                //     sram_num_count <= 0;
                // end
                // else begin
                    if(sram_num_count == 1 && count == 15)
                        sram_num_count <= 0;
                    else if(count == 15)
                        sram_num_count <= sram_num_count + 1;
                //end
            end
            four: begin
                // if(!sram_flag) begin
                //     sram_num_count <= 0;
                // end
                //else begin
                    if(sram_num_count == 3 && count == 15)
                        sram_num_count <= 0;
                    else if(count == 15)
                        sram_num_count <= sram_num_count + 1;
                //end
            end
            eight: begin
                // if(!sram_flag) begin
                //     sram_num_count <= 0;
                // end
                //else begin
                    if(sram_num_count == 7 && count == 15)
                        sram_num_count <= 0;
                    else if(count == 15)
                        sram_num_count <= sram_num_count + 1;
                //end
            end
            endcase
        end
        else if(in_valid && finish_input_x) begin //write weight
            case(size_reg)
            two: begin
                if(addr_weight_count == addr_offset + 1 && sram_num_count == 1 && count == 15)
                    sram_num_count <= 0;
                else if(addr_weight_count == addr_offset + 1 && sram_num_count != 1 && count == 15)
                    sram_num_count <= sram_num_count + 1;
                else
                    sram_num_count <= sram_num_count;
            end
            four: begin
                if(addr_weight_count == addr_offset + 3 && sram_num_count == 3 && count == 15)
                    sram_num_count <= 0;
                else if(addr_weight_count == addr_offset + 3 && sram_num_count != 3 && count == 15)
                    sram_num_count <= sram_num_count + 1;
                else
                    sram_num_count <= sram_num_count;
            end
            eight: begin
                if(addr_weight_count == addr_offset + 7 && sram_num_count == 7 && count == 15)
                    sram_num_count <= 0;
                else if(addr_weight_count == addr_offset + 7 && sram_num_count != 7 && count == 15)
                    sram_num_count <= sram_num_count + 1;
                else
                    sram_num_count <= sram_num_count;
            end
            default: sram_num_count <= sram_num_count;
            endcase
        end
        else begin
            sram_num_count <= 0;
        end
    end
end

//addr_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_count <= 0;
    end
    else begin
        if(in_valid && !finish_input_x) begin //write input
            if(size_reg == two && addr_count == 31 && sram_num_count == 1 && count == 15)
                addr_count <= 0;
            else if(size_reg == four && addr_count == 63 && sram_num_count == 3 && count == 15)
                addr_count <= 0;
            else if(size_reg == eight && addr_count == 127 && sram_num_count == 7 && count == 15)
                addr_count <= 0;
            else if(size_reg == two && sram_num_count == 1 && count == 15)
                addr_count <= addr_count + 1;
            else if(size_reg == four && sram_num_count == 3 && count == 15)
                addr_count <= addr_count + 1;
            else if(size_reg == eight && sram_num_count == 7 && count == 15)
                addr_count <= addr_count + 1;
        end
        else if(current_state == CAL) begin
            case(size_reg)
            two: begin
                if(in_valid2 && count == 3)
                    addr_count <= {i_mat_idx_reg[0], i_mat_idx_reg[1], i_mat_idx_reg[2], i_mat_idx} * 2;
                
                else if(addr_weight_count == (/*w_mat_idx_actual*/{w_mat_idx_reg[0], w_mat_idx_reg[1], w_mat_idx_reg[2], w_mat_idx_reg[3]} * 2) + 1 && step < 4)
                    addr_count <= addr_count + 1;
                
                else begin
                    addr_count <= addr_count;
                end
            end
            four: begin
                if(in_valid2 && count == 3)
                    addr_count <= {i_mat_idx_reg[0], i_mat_idx_reg[1], i_mat_idx_reg[2], i_mat_idx} * 4;
                else if(addr_weight_count == (/*w_mat_idx_actual*/{w_mat_idx_reg[0], w_mat_idx_reg[1], w_mat_idx_reg[2], w_mat_idx_reg[3]} * 4) + 3 && step < 16)
                    addr_count <= addr_count + 1;
                else
                    addr_count <= addr_count;
            end
            eight: begin
                if(in_valid2 && count == 3)
                    addr_count <= {i_mat_idx_reg[0], i_mat_idx_reg[1], i_mat_idx_reg[2], i_mat_idx} * 8;
                else if(addr_weight_count == (/*w_mat_idx_actual*/{w_mat_idx_reg[0], w_mat_idx_reg[1], w_mat_idx_reg[2], w_mat_idx_reg[3]} * 8) + 7 && step < 64)
                    addr_count <= addr_count + 1;
                else
                    addr_count <= addr_count;
            end
            endcase
        end
        else begin
            addr_count <= 0;
        end
    end
end

//addr_weight_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_weight_count <= 0;
    end
    else begin
        if(in_valid && finish_input_x) begin //write weight
            case(size_reg)
            two: begin
                if(sram_num_count == 1 && addr_weight_count == addr_offset + 1 && count == 15)
                    addr_weight_count <= addr_offset + 2;
                else if(addr_weight_count == addr_offset + 1 && sram_num_count != 1 && count == 15)
                    addr_weight_count <= addr_offset;
                else if(count == 15)
                    addr_weight_count <= addr_weight_count + 1;
            end
            four: begin
                if(sram_num_count == 3 && addr_weight_count == addr_offset + 3 && count == 15)
                    addr_weight_count <= addr_offset + 4;
                else if(addr_weight_count == addr_offset + 3 && sram_num_count != 3 && count == 15)
                    addr_weight_count <= addr_offset;
                else if(count == 15)
                    addr_weight_count <= addr_weight_count + 1;
            end
            eight: begin
                if(sram_num_count == 7 && addr_weight_count == addr_offset + 7 && count == 15)
                    addr_weight_count <= addr_offset + 8;
                else if(addr_weight_count == addr_offset + 7 && sram_num_count != 7 && count == 15)
                    addr_weight_count <= addr_offset;
                else if(count == 15)
                    addr_weight_count <= addr_weight_count + 1;
            end
            endcase
        end
        else if(current_state == CAL) begin
            case(size_reg)
            two: begin
                if(in_valid2 && count == 3)
                    addr_weight_count <= {w_mat_idx_reg[0], w_mat_idx_reg[1], w_mat_idx_reg[2], w_mat_idx} * 2;
                else if(addr_weight_count == (w_mat_idx_actual * 2) + 1)
                    addr_weight_count <= w_mat_idx_actual * 2; //return to initial address
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            four: begin
                if(in_valid2 && count == 3)
                    addr_weight_count <= {w_mat_idx_reg[0], w_mat_idx_reg[1], w_mat_idx_reg[2], w_mat_idx} * 4;
                else if(addr_weight_count == (w_mat_idx_actual * 4) + 3)
                    addr_weight_count <= w_mat_idx_actual * 4; //return to initial address
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            eight: begin
                if(in_valid2 && count == 3)
                    addr_weight_count <= {w_mat_idx_reg[0], w_mat_idx_reg[1], w_mat_idx_reg[2], w_mat_idx} * 8;
                else if(addr_weight_count == (w_mat_idx_actual * 8) + 7)
                    addr_weight_count <= w_mat_idx_actual * 8; //return to initial address
                else
                    addr_weight_count <= addr_weight_count + 1;
            end
            endcase
        end
        else begin
            addr_weight_count <= 0;
        end
    end
end

//addr_offset
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_offset <= 0;
    end
    else begin
        if(in_valid && finish_input_x) begin //write weight
            case(size_reg)
            two: begin
                if(addr_weight_count == addr_offset + 1 && sram_num_count == 1 && count == 15)
                    addr_offset <= addr_offset + 2;
                else
                    addr_offset <= addr_offset;
            end
            four: begin
                if(addr_weight_count == addr_offset + 3 && sram_num_count == 3 && count == 15)
                    addr_offset <= addr_offset + 4;
                else
                    addr_offset <= addr_offset;
            end
            eight: begin
                if(addr_weight_count == addr_offset + 7 && sram_num_count == 7 && count == 15)
                    addr_offset <= addr_offset + 8;
                else
                    addr_offset <= addr_offset;
            end
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
    if(in_valid && !finish_input_x)
        //data_i = {matrix_actual[14:0], matrix};
        data_i = {matrix_reg[0], matrix_reg[1], matrix_reg[2], matrix_reg[3], matrix_reg[4], matrix_reg[5], matrix_reg[6], matrix_reg[7], matrix_reg[8], matrix_reg[9], matrix_reg[10], matrix_reg[11], matrix_reg[12], matrix_reg[13], matrix_reg[14], matrix};
    else if(in_valid && finish_input_x)
        data_i = 0;
    else begin
        data_i = 0;
    end
end

//data_w
always@ (*) begin
    if(in_valid && finish_input_x)
        data_w = {matrix_reg[0], matrix_reg[1], matrix_reg[2], matrix_reg[3], matrix_reg[4], matrix_reg[5], matrix_reg[6], matrix_reg[7], matrix_reg[8], matrix_reg[9], matrix_reg[10], matrix_reg[11], matrix_reg[12], matrix_reg[13], matrix_reg[14], matrix};
    else begin
        data_w = 0;
    end
end

//wen_i
always@ (*) begin
    if(in_valid && !finish_input_x /*&& count == 15*/) begin //write input
        case(sram_num_count)
        0: begin
            //if(step < 16 && sram_flag == 0) begin
                //wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
                //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
            //end
            //else begin
                wen_i_0 = 0; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            //end
        end
        1: begin
            wen_i_0 = 1; wen_i_1 = 0; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        2: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 0; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        3: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 0; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        4: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 0; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
            //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        5: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 0; wen_i_6 = 1; wen_i_7 = 1;
            //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        6: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 0; wen_i_7 = 1;
            //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
        end
        default: begin
            wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 0;
            //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 0;
        end
        endcase
    end
    else if(in_valid && finish_input_x) begin
        wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
        //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
    end
    else if(current_state == CAL) begin
        wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
        //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
    end
    else begin
        wen_i_0 = 1; wen_i_1 = 1; wen_i_2 = 1; wen_i_3 = 1; wen_i_4 = 1; wen_i_5 = 1; wen_i_6 = 1; wen_i_7 = 1;
        //wen_i_8 = 1; wen_i_9 = 1; wen_i_10 = 1; wen_i_11 = 1; wen_i_12 = 1; wen_i_13 = 1; wen_i_14 = 1; wen_i_15 = 1;
    end
end

//wen_w
always@ (*) begin
    // if(in_valid && !finish_input_x) begin
    //     wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
    //     wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
    // end
    if(in_valid && finish_input_x) begin //write weight
        case(sram_num_count)
        0: begin
            wen_w_0 = 0; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        1: begin
            wen_w_0 = 1; wen_w_1 = 0; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        2: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 0; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        3: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 0; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        4: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 0; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        5: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 0; wen_w_6 = 1; wen_w_7 = 1;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        6: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 0; wen_w_7 = 1;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
        end
        default: begin
            wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 0;
            //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 0;
        end
        endcase
    end
    else if(current_state == CAL) begin
        wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
        //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
    end
    else begin
        wen_w_0 = 1; wen_w_1 = 1; wen_w_2 = 1; wen_w_3 = 1; wen_w_4 = 1; wen_w_5 = 1; wen_w_6 = 1; wen_w_7 = 1;
        //wen_w_8 = 1; wen_w_9 = 1; wen_w_10 = 1; wen_w_11 = 1; wen_w_12 = 1; wen_w_13 = 1; wen_w_14 = 1; wen_w_15 = 1;
    end
end

//---------------------------------------------------------------------
//   CALCULATION
//---------------------------------------------------------------------
//q_i_reg
always@ (posedge clk) begin
    if(current_state == CAL) begin
        case(size_reg)
        two: begin
            q_i_reg[0] <= q_i_0; q_i_reg[1] <= q_i_1;
            for(i = 2; i < 8; i = i + 1) begin
                q_i_reg[i] <= 0;
            end
        end
        four: begin
            q_i_reg[0] <= q_i_0; q_i_reg[1] <= q_i_1; q_i_reg[2] <= q_i_2; q_i_reg[3] <= q_i_3;
            for(i = 4; i < 8; i = i + 1) begin
                q_i_reg[i] <= 0;
            end
        end
        eight: begin
            q_i_reg[0] <= q_i_0; q_i_reg[1] <= q_i_1; q_i_reg[2] <= q_i_2; q_i_reg[3] <= q_i_3;
            q_i_reg[4] <= q_i_4; q_i_reg[5] <= q_i_5; q_i_reg[6] <= q_i_6; q_i_reg[7] <= q_i_7;
        end
        endcase
    end
end

//q_w_reg
always@ (posedge clk) begin
    if(current_state == CAL) begin
        case(size_reg)
        two: begin
            q_w_reg[0] <= q_w_0; 
            q_w_reg[1] <= q_w_1;
            for(i = 2; i < 8; i = i + 1) begin
                q_w_reg[i] <= 0;
            end
        end
        four: begin
            q_w_reg[0] <= q_w_0; q_w_reg[1] <= q_w_1; q_w_reg[2] <= q_w_2; q_w_reg[3] <= q_w_3;
            for(i = 4; i < 8; i = i + 1) begin
                q_w_reg[i] <= 0;
            end
        end
        eight: begin
            q_w_reg[0] <= q_w_0; q_w_reg[1] <= q_w_1; q_w_reg[2] <= q_w_2; q_w_reg[3] <= q_w_3;
            q_w_reg[4] <= q_w_4; q_w_reg[5] <= q_w_5; q_w_reg[6] <= q_w_6; q_w_reg[7] <= q_w_7;

        end
        endcase
    end
end

//result
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 15; i = i + 1) begin
            result[i] <= 0;
        end
    end
    else begin
        if(in_valid2) begin
            for(i = 0; i < 15; i = i + 1) begin
                result[i] <= 0;
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
        end
    end
end

//group_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        group_count <= 0;
    end
    else begin
        if(current_state == OUTPUT) begin
            if(out_valid_count == length_temp && length_flag) begin //finish output one length+number
                group_count <= group_count + 1;
            end
        end
        else begin
            group_count <= 0;
        end
    end
end

//out_valid_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid_count <= 0;
    end
    else begin
        if(current_state == OUTPUT) begin
            if(out_valid_count == 5 && !length_flag) begin
                out_valid_count <= 1;
            end
            else if(out_valid_count == length_temp && length_flag) begin
                out_valid_count <= 0;
            end
            else begin
                out_valid_count <= out_valid_count + 1;
            end
        end
    end
end

//length_flag
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        length_flag <= 0;
    end
    else begin
        if(current_state == OUTPUT) begin
            if(length_flag == 0 && out_valid_count == 5) begin //ready to output number
                length_flag <= 1;
            end
            else if(length_flag == 1 && out_valid_count == length_temp) begin //back to length or finish output state
                length_flag <= 0;
            end
        end
        else begin
            length_flag <= 0;
        end
    end
end


//length
always@ (*) begin
    if(current_state == OUTPUT) begin
        if(result[group_count][39] == 1) begin // < 0
            length_temp = 40;
        end
        else if(result[group_count][38] == 1) begin
            length_temp = 39;
        end
        else if(result[group_count][37] == 1) begin
            length_temp = 38;
        end
        else if(result[group_count][36] == 1) begin
            length_temp = 37;
        end
        else if(result[group_count][35] == 1) begin
            length_temp = 36;
        end
        else if(result[group_count][34] == 1) begin
            length_temp = 35;
        end
        else if(result[group_count][33] == 1) begin
            length_temp = 34;
        end
        else if(result[group_count][32] == 1) begin
            length_temp = 33;
        end
        else if(result[group_count][31] == 1) begin
            length_temp = 32;
        end
        else if(result[group_count][30] == 1) begin
            length_temp = 31;
        end
        else if(result[group_count][29] == 1) begin
            length_temp = 30;
        end
        else if(result[group_count][28] == 1) begin
            length_temp = 29;
        end
        else if(result[group_count][27] == 1) begin
            length_temp = 28;
        end
        else if(result[group_count][26] == 1) begin
            length_temp = 27;
        end
        else if(result[group_count][25] == 1) begin
            length_temp = 26;
        end
        else if(result[group_count][24] == 1) begin
            length_temp = 25;
        end
        else if(result[group_count][23] == 1) begin
            length_temp = 24;
        end
        else if(result[group_count][22] == 1) begin
            length_temp = 23;
        end
        else if(result[group_count][21] == 1) begin
            length_temp = 22;
        end
        else if(result[group_count][20] == 1) begin
            length_temp = 21;
        end
        else if(result[group_count][19] == 1) begin
            length_temp = 20;
        end
        else if(result[group_count][18] == 1) begin
            length_temp = 19;
        end
        else if(result[group_count][17] == 1) begin
            length_temp = 18;
        end
        else if(result[group_count][16] == 1) begin
            length_temp = 17;
        end
        else if(result[group_count][15] == 1) begin
            length_temp = 16;
        end
        else if(result[group_count][14] == 1) begin
            length_temp = 15;
        end
        else if(result[group_count][13] == 1) begin
            length_temp = 14;
        end
        else if(result[group_count][12] == 1) begin
            length_temp = 13;
        end
        else if(result[group_count][11] == 1) begin
            length_temp = 12;
        end
        else if(result[group_count][10] == 1) begin
            length_temp = 11;
        end
        else if(result[group_count][9] == 1) begin
            length_temp = 10;
        end
        else if(result[group_count][8] == 1) begin
            length_temp = 9;
        end
        else if(result[group_count][7] == 1) begin
            length_temp = 8;
        end
        else if(result[group_count][6] == 1) begin
            length_temp = 7;
        end
        else if(result[group_count][5] == 1) begin
            length_temp = 6;
        end
        else if(result[group_count][4] == 1) begin
            length_temp = 5;
        end
        else if(result[group_count][3] == 1) begin
            length_temp = 4;
        end
        else if(result[group_count][2] == 1) begin
            length_temp = 3;
        end
        else if(result[group_count][1] == 1) begin
            length_temp = 2;
        end
        else begin
            length_temp = 1;
        end
    end
    else begin
        length_temp = 0;
    end
end


//---------------------------------------------------------------------
//   OUTPUT BLOCK
//---------------------------------------------------------------------
//out_valid
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if(current_state == OUTPUT) begin
            // case(size_reg)
            // two: begin
            //     if(step == 3)
            //         out_valid <= 0;
            //     else
            //         out_valid <= 1;
            // end
            // four: begin
            //     if(step == 7)
            //         out_valid <= 0;
            //     else
            //         out_valid <= 1;
            // end
            // eight: begin
            //     if(step == 15)
            //         out_valid <= 0;
            //     else
            //         out_valid <= 1;
            // end
            // default: out_valid <= 0;
            // endcase
            out_valid <= 1;
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
            //out_value <= result[step];
            if(!length_flag) begin //length
                out_value <= length_temp[5 - out_valid_count];
            end 
            else begin //number
                out_value <= result[group_count][length_temp - out_valid_count];
            end
        end
        else begin
            out_value <= 0;
        end
    end
end

endmodule

