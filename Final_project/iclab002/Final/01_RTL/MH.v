//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Final Project
//   MH.v
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_minmax.v"
//synopsys translate_on

module MH(  
    //input
    clk,
    clk2,
    rst_n,
    in_valid,
    op_valid,
    pic_data,
    se_data,
    op,
    //output
    out_valid,
    out_data
);

//========================================================
// Input and Output Declaration
//========================================================
input clk, clk2, rst_n, in_valid, op_valid;
input [31:0] pic_data;
input [7:0] se_data;
input [2:0] op;
output reg out_valid;
output reg [31:0] out_data;

//========================================================
// Parameter Declaration
//========================================================
//fsm
parameter IDLE = 0;
parameter INPUT = 1;
parameter CAL = 2;
parameter OUTPUT = 3;

//op
parameter histogram = 3'b000;
parameter erosion = 3'b010;
parameter dilation = 3'b011;
parameter opening = 3'b110;
parameter closing = 3'b111;

//ip
parameter width = 8;
parameter num_inputs = 16;
parameter num_inputs_h = 4;
parameter cdf_max = 1024;
integer i;
genvar m;

//========================================================
// Register and Wire Declaration
//========================================================
reg [1:0] current_state, next_state;
reg [2:0] op_reg;
reg [7:0] se_reg [15:0];
reg [31:0] pic_reg_0 [25:0];
reg [31:0] pic_reg_1 [25:0]; //for opening and closing
reg [2:0] pad_count;
reg [2:0] pad_count_2; //for opening and closing
reg [8:0] addr_count;
reg [7:0] count;
reg count_flag;
reg opening_closing_flag;
//reg [8:0] start_op_count;
reg [8:0] out_valid_count;
reg [8:0] result_s1_0 [63:0];
reg [7:0] result_s1_1 [63:0];
reg [8:0] result_s2_0 [63:0];
reg [7:0] result_s2_1 [63:0];
reg [31:0] out_reg;
reg [10:0] h_acc [255:0]; //histogram accumulation
reg [10:0] cdf_min;
reg [7:0] cdf_min_index;
reg [18:0] h_mult [3:0];
reg [7:0] h_div [3:0];
wire [10:0] cdf_denominator;

//ip
wire ctrl_0, ctrl_1;
reg [127:0] a [3:0];
reg [127:0] b [3:0];
reg [31:0] h;
wire [7:0] value_0 [3:0];
wire [7:0] value_1 [3:0];
wire [7:0] h_value;


//sram
wire [31:0] q_0;
reg wen_0;
reg [7:0] addr_0;
reg [31:0] d_0;

//========================================================
// Finite State Machine
//========================================================
//current_state
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

//next_state comb logic
always@ (*) begin
    case(current_state)
    IDLE: begin
        if(in_valid) begin
            next_state = INPUT;
        end
        else begin
            next_state = IDLE;
        end
    end
    INPUT: begin
        // if(op_valid && op == histogram) begin
        //     next_state = CAL;
        // end
        if(count == 25) begin
            next_state = CAL;
        end
        else begin
            next_state = INPUT;
        end
    end
    CAL: begin
        // if((op_reg == erosion || op_reg == dilation) && !in_valid) begin
        //     next_state = OUTPUT;
        // end
        // else if(!in_valid && op_reg == histogram) begin
        //     next_state = OUTPUT;
        // end
        if(!in_valid && op_reg != histogram) begin
            next_state = OUTPUT;
        end
        else if(op_reg == histogram && out_valid_count == 258) begin
            next_state = IDLE;
        end
        else begin
            next_state = CAL;
        end
    end
    OUTPUT: begin
        if(out_valid_count == 257 /*&& op_reg != histogram*/) begin
            next_state = IDLE;
        end
        else begin
            next_state = OUTPUT;
        end
    end

    default: next_state = current_state;
    endcase
end

//========================================================
// Input Block
//========================================================
//se_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            se_reg[i] <= 0;
        end
    end
    else begin
        if(in_valid && count < 16) begin
            se_reg[15] <= se_data;
            se_reg[14] <= se_reg[15];
            se_reg[13] <= se_reg[14];
            se_reg[12] <= se_reg[13];
            se_reg[11] <= se_reg[12];
            se_reg[10] <= se_reg[11];
            se_reg[9] <= se_reg[10];
            se_reg[8] <= se_reg[9];
            se_reg[7] <= se_reg[8];
            se_reg[6] <= se_reg[7];
            se_reg[5] <= se_reg[6];
            se_reg[4] <= se_reg[5];
            se_reg[3] <= se_reg[4];
            se_reg[2] <= se_reg[3];
            se_reg[1] <= se_reg[2];
            se_reg[0] <= se_reg[1];
        end
    end
end

//pic_reg_0
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 26; i = i + 1) begin
            pic_reg_0[i] <= 0;
        end
    end
    else begin
        if(in_valid) begin
            pic_reg_0[25] <= pic_data;
            pic_reg_0[24] <= pic_reg_0[25];
            pic_reg_0[23] <= pic_reg_0[24];
            pic_reg_0[22] <= pic_reg_0[23];
            pic_reg_0[21] <= pic_reg_0[22];
            pic_reg_0[20] <= pic_reg_0[21];
            pic_reg_0[19] <= pic_reg_0[20];
            pic_reg_0[18] <= pic_reg_0[19];
            pic_reg_0[17] <= pic_reg_0[18];
            pic_reg_0[16] <= pic_reg_0[17];
            pic_reg_0[15] <= pic_reg_0[16];
            pic_reg_0[14] <= pic_reg_0[15];
            pic_reg_0[13] <= pic_reg_0[14];
            pic_reg_0[12] <= pic_reg_0[13];
            pic_reg_0[11] <= pic_reg_0[12];
            pic_reg_0[10] <= pic_reg_0[11];
            pic_reg_0[9] <= pic_reg_0[10];
            pic_reg_0[8] <= pic_reg_0[9];
            pic_reg_0[7] <= pic_reg_0[8];
            pic_reg_0[6] <= pic_reg_0[7];
            pic_reg_0[5] <= pic_reg_0[6];
            pic_reg_0[4] <= pic_reg_0[5];
            pic_reg_0[3] <= pic_reg_0[4];
            pic_reg_0[2] <= pic_reg_0[3];
            pic_reg_0[1] <= pic_reg_0[2];
            pic_reg_0[0] <= pic_reg_0[1];
        end
        else if(out_valid_count > 231 && (op_reg == erosion || op_reg == dilation)) begin
            pic_reg_0[25] <= 0;
            pic_reg_0[24] <= pic_reg_0[25];
            pic_reg_0[23] <= pic_reg_0[24];
            pic_reg_0[22] <= pic_reg_0[23];
            pic_reg_0[21] <= pic_reg_0[22];
            pic_reg_0[20] <= pic_reg_0[21];
            pic_reg_0[19] <= pic_reg_0[20];
            pic_reg_0[18] <= pic_reg_0[19];
            pic_reg_0[17] <= pic_reg_0[18];
            pic_reg_0[16] <= pic_reg_0[17];
            pic_reg_0[15] <= pic_reg_0[16];
            pic_reg_0[14] <= pic_reg_0[15];
            pic_reg_0[13] <= pic_reg_0[14];
            pic_reg_0[12] <= pic_reg_0[13];
            pic_reg_0[11] <= pic_reg_0[12];
            pic_reg_0[10] <= pic_reg_0[11];
            pic_reg_0[9] <= pic_reg_0[10];
            pic_reg_0[8] <= pic_reg_0[9];
            pic_reg_0[7] <= pic_reg_0[8];
            pic_reg_0[6] <= pic_reg_0[7];
            pic_reg_0[5] <= pic_reg_0[6];
            pic_reg_0[4] <= pic_reg_0[5];
            pic_reg_0[3] <= pic_reg_0[4];
            pic_reg_0[2] <= pic_reg_0[3];
            pic_reg_0[1] <= pic_reg_0[2];
            pic_reg_0[0] <= pic_reg_0[1];
        end
        else if(out_valid_count > 205 && (op_reg == opening || op_reg == closing)) begin
            pic_reg_0[25] <= 0;
            pic_reg_0[24] <= pic_reg_0[25];
            pic_reg_0[23] <= pic_reg_0[24];
            pic_reg_0[22] <= pic_reg_0[23];
            pic_reg_0[21] <= pic_reg_0[22];
            pic_reg_0[20] <= pic_reg_0[21];
            pic_reg_0[19] <= pic_reg_0[20];
            pic_reg_0[18] <= pic_reg_0[19];
            pic_reg_0[17] <= pic_reg_0[18];
            pic_reg_0[16] <= pic_reg_0[17];
            pic_reg_0[15] <= pic_reg_0[16];
            pic_reg_0[14] <= pic_reg_0[15];
            pic_reg_0[13] <= pic_reg_0[14];
            pic_reg_0[12] <= pic_reg_0[13];
            pic_reg_0[11] <= pic_reg_0[12];
            pic_reg_0[10] <= pic_reg_0[11];
            pic_reg_0[9] <= pic_reg_0[10];
            pic_reg_0[8] <= pic_reg_0[9];
            pic_reg_0[7] <= pic_reg_0[8];
            pic_reg_0[6] <= pic_reg_0[7];
            pic_reg_0[5] <= pic_reg_0[6];
            pic_reg_0[4] <= pic_reg_0[5];
            pic_reg_0[3] <= pic_reg_0[4];
            pic_reg_0[2] <= pic_reg_0[3];
            pic_reg_0[1] <= pic_reg_0[2];
            pic_reg_0[0] <= pic_reg_0[1];
        end
    end
end

//pic_reg_1
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 26; i = i + 1) begin
            pic_reg_1[i] <= 0;
        end
    end
    else begin
        if(count_flag && in_valid) begin
            pic_reg_1[25] <= {value_0[3], value_0[2], value_0[1], value_0[0]};
            pic_reg_1[24] <= pic_reg_1[25];
            pic_reg_1[23] <= pic_reg_1[24];
            pic_reg_1[22] <= pic_reg_1[23];
            pic_reg_1[21] <= pic_reg_1[22];
            pic_reg_1[20] <= pic_reg_1[21];
            pic_reg_1[19] <= pic_reg_1[20];
            pic_reg_1[18] <= pic_reg_1[19];
            pic_reg_1[17] <= pic_reg_1[18];
            pic_reg_1[16] <= pic_reg_1[17];
            pic_reg_1[15] <= pic_reg_1[16];
            pic_reg_1[14] <= pic_reg_1[15];
            pic_reg_1[13] <= pic_reg_1[14];
            pic_reg_1[12] <= pic_reg_1[13];
            pic_reg_1[11] <= pic_reg_1[12];
            pic_reg_1[10] <= pic_reg_1[11];
            pic_reg_1[9] <= pic_reg_1[10];
            pic_reg_1[8] <= pic_reg_1[9];
            pic_reg_1[7] <= pic_reg_1[8];
            pic_reg_1[6] <= pic_reg_1[7];
            pic_reg_1[5] <= pic_reg_1[6];
            pic_reg_1[4] <= pic_reg_1[5];
            pic_reg_1[3] <= pic_reg_1[4];
            pic_reg_1[2] <= pic_reg_1[3];
            pic_reg_1[1] <= pic_reg_1[2];
            pic_reg_1[0] <= pic_reg_1[1];
        end
        else if(out_valid_count > 205 && out_valid_count <= 231) begin
            pic_reg_1[25] <= {value_0[3], value_0[2], value_0[1], value_0[0]};
            pic_reg_1[24] <= pic_reg_1[25];
            pic_reg_1[23] <= pic_reg_1[24];
            pic_reg_1[22] <= pic_reg_1[23];
            pic_reg_1[21] <= pic_reg_1[22];
            pic_reg_1[20] <= pic_reg_1[21];
            pic_reg_1[19] <= pic_reg_1[20];
            pic_reg_1[18] <= pic_reg_1[19];
            pic_reg_1[17] <= pic_reg_1[18];
            pic_reg_1[16] <= pic_reg_1[17];
            pic_reg_1[15] <= pic_reg_1[16];
            pic_reg_1[14] <= pic_reg_1[15];
            pic_reg_1[13] <= pic_reg_1[14];
            pic_reg_1[12] <= pic_reg_1[13];
            pic_reg_1[11] <= pic_reg_1[12];
            pic_reg_1[10] <= pic_reg_1[11];
            pic_reg_1[9] <= pic_reg_1[10];
            pic_reg_1[8] <= pic_reg_1[9];
            pic_reg_1[7] <= pic_reg_1[8];
            pic_reg_1[6] <= pic_reg_1[7];
            pic_reg_1[5] <= pic_reg_1[6];
            pic_reg_1[4] <= pic_reg_1[5];
            pic_reg_1[3] <= pic_reg_1[4];
            pic_reg_1[2] <= pic_reg_1[3];
            pic_reg_1[1] <= pic_reg_1[2];
            pic_reg_1[0] <= pic_reg_1[1];
        end
        else if(out_valid_count > 231) begin
            pic_reg_1[25] <= 0;
            pic_reg_1[24] <= pic_reg_1[25];
            pic_reg_1[23] <= pic_reg_1[24];
            pic_reg_1[22] <= pic_reg_1[23];
            pic_reg_1[21] <= pic_reg_1[22];
            pic_reg_1[20] <= pic_reg_1[21];
            pic_reg_1[19] <= pic_reg_1[20];
            pic_reg_1[18] <= pic_reg_1[19];
            pic_reg_1[17] <= pic_reg_1[18];
            pic_reg_1[16] <= pic_reg_1[17];
            pic_reg_1[15] <= pic_reg_1[16];
            pic_reg_1[14] <= pic_reg_1[15];
            pic_reg_1[13] <= pic_reg_1[14];
            pic_reg_1[12] <= pic_reg_1[13];
            pic_reg_1[11] <= pic_reg_1[12];
            pic_reg_1[10] <= pic_reg_1[11];
            pic_reg_1[9] <= pic_reg_1[10];
            pic_reg_1[8] <= pic_reg_1[9];
            pic_reg_1[7] <= pic_reg_1[8];
            pic_reg_1[6] <= pic_reg_1[7];
            pic_reg_1[5] <= pic_reg_1[6];
            pic_reg_1[4] <= pic_reg_1[5];
            pic_reg_1[3] <= pic_reg_1[4];
            pic_reg_1[2] <= pic_reg_1[3];
            pic_reg_1[1] <= pic_reg_1[2];
            pic_reg_1[0] <= pic_reg_1[1];
        end
    end
end

//op_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        op_reg <= 0;
    end
    else begin
        if(next_state == IDLE) begin
            op_reg <= 0;
        end
        else if(op_valid) begin
            op_reg <= op;
        end
    end
end

//========================================================
// Counter
//========================================================
//count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count <= 0;
    end
    else begin

        if(in_valid) begin
            count <= count + 1;
        end

    end
end

//count_flag
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_flag <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            count_flag <= 0;
        end
        else if(count == 25) begin
            count_flag <= 1;
        end

    end
end

//opening_closing_flag
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        opening_closing_flag <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            opening_closing_flag <= 0;
        end
        else if(count == 51) begin
            opening_closing_flag <= 1;
        end
    end
end

//addr_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_count <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            addr_count <= 0;
        end
        else if(current_state == CAL) begin
            addr_count <= addr_count + 1;
        end

    end
end

//pad_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pad_count <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            pad_count <= 0;
        end
        else if(current_state == CAL && count_flag && op_reg != histogram) begin
            if(next_state == OUTPUT) begin
                pad_count <= pad_count;
            end
            else if(pad_count == 7) begin
                pad_count <= 0;
            end
            else begin
                pad_count <= pad_count + 1;
            end
        end
        else if(current_state == OUTPUT && out_valid_count > 231 && (op_reg == erosion || op_reg == dilation)) begin
            if(pad_count == 7) begin
                pad_count <= 0;
            end
            else begin
                pad_count <= pad_count + 1;
            end
        end
        else if(current_state == OUTPUT && out_valid_count > 205 && (op_reg == opening || op_reg == closing)) begin
            if(pad_count == 7) begin
                pad_count <= 0;
            end
            else begin
                pad_count <= pad_count + 1;
            end
        end
    end
end

//pad_count_2
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pad_count_2 <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            pad_count_2 <= 0;
        end
        else if(current_state == CAL && opening_closing_flag) begin
            if(next_state == OUTPUT) begin
                pad_count_2 <= pad_count_2;
            end
            else if(pad_count_2 == 7) begin
                pad_count_2 <= 0;
            end
            else begin
                pad_count_2 <= pad_count_2 + 1;

            end
        end
        else if(current_state == OUTPUT && out_valid_count > 205) begin
            if(pad_count_2 == 7) begin
                pad_count_2 <= 0;
            end
            else begin
                pad_count_2 <= pad_count_2 + 1;
            end
        end
    end
end

//========================================================
// SRAM Control
//========================================================
//32 bit 256 word
PIC_MEM R0(.Q(q_0), .CLK(clk), .CEN(1'b0), .WEN(wen_0), .A(addr_0), .D(d_0), .OEN(1'b0));

//wen_0
always@ (*) begin
    if(in_valid) begin
        if(count_flag && (op_reg == erosion || op_reg == dilation) && addr_count >= 229) begin
            wen_0 = 1;
        end
        else if(opening_closing_flag && (op_reg == opening || op_reg == closing) && addr_count >= 229) begin
            wen_0 = 1;
        end
        else if(op_reg == histogram && addr_count >= 229) begin
            wen_0 = 1;
        end
        else begin
            wen_0 = 0;
        end
    end
    else begin
        wen_0 = 1;
    end
end

//addr_0
always@ (*) begin
    if(op_reg == erosion || op_reg == dilation) begin
        if(count_flag && addr_count < 229) begin
            addr_0 = addr_count;
        end
        else if(addr_count == 229) begin
            addr_0 = 0;
        end
        else if(addr_count >= 230) begin
            addr_0 = out_valid_count - 1;
        end
        else begin
            addr_0 = 0;
        end
    end
    else if(op_reg == opening || op_reg == closing) begin
        if(opening_closing_flag && addr_count < 229) begin
            addr_0 = addr_count - 26;
        end
        else if(addr_count == 229) begin
            addr_0 = 0;
        end
        else begin
            addr_0 = out_valid_count - 1;
        end
    end
    else if(in_valid && addr_count < 229)begin
        addr_0 = count;
    end
    else if(op_reg == histogram) begin
        if(addr_count == 229) begin
            addr_0 = 0;
        end
        else begin
            addr_0 = out_valid_count - 1;
        end
    end
    else begin
        addr_0 = 0; 
    end
end


//d_0
always@ (*) begin
    if(count_flag && (op_reg == erosion || op_reg == dilation)) begin
        d_0 = {value_0[3], value_0[2], value_0[1], value_0[0]};
    end
    else if(opening_closing_flag && (op_reg == closing || op_reg == opening)) begin
        d_0 = {value_1[3], value_1[2], value_1[1], value_1[0]};
    end
    else if(in_valid && addr_count < 229)begin
        d_0 = pic_data;
    end
    else begin
        d_0 = 0;
    end
end

//========================================================
// IP
//========================================================
//comparator IP
DW_minmax #(width, num_inputs) M0(.a(a[0]), .tc(1'b0), .min_max(ctrl_0), .value(value_0[0])/*, .index(index[0])*/);
DW_minmax #(width, num_inputs) M1(.a(a[1]), .tc(1'b0), .min_max(ctrl_0), .value(value_0[1])/*, .index(index[1])*/);
DW_minmax #(width, num_inputs) M2(.a(a[2]), .tc(1'b0), .min_max(ctrl_0), .value(value_0[2])/*, .index(index[2])*/);
DW_minmax #(width, num_inputs) M3(.a(a[3]), .tc(1'b0), .min_max(ctrl_0), .value(value_0[3])/*, .index(index[3])*/);
//only for opening and closing
DW_minmax #(width, num_inputs) N0(.a(b[0]), .tc(1'b0), .min_max(ctrl_1), .value(value_1[0])/*, .index(index[0])*/);
DW_minmax #(width, num_inputs) N1(.a(b[1]), .tc(1'b0), .min_max(ctrl_1), .value(value_1[1])/*, .index(index[1])*/);
DW_minmax #(width, num_inputs) N2(.a(b[2]), .tc(1'b0), .min_max(ctrl_1), .value(value_1[2])/*, .index(index[2])*/);
DW_minmax #(width, num_inputs) N3(.a(b[3]), .tc(1'b0), .min_max(ctrl_1), .value(value_1[3])/*, .index(index[3])*/);
//for histogram
DW_minmax #(width, num_inputs_h) H0(.a(h), .tc(1'b0), .min_max(1'b0), .value(h_value)/*, .index(index[0])*/);

assign ctrl_0 = (op_reg == erosion || op_reg == opening) ? 0 : 1;
assign ctrl_1 = (op_reg == opening) ? 1 : 0;

//a
always@ (*) begin
    if(/*current_state == CAL &&*/ count_flag && op_reg != histogram) begin
        for(i = 0; i < 4; i = i + 1) begin
           a[i] = {result_s1_1[0 + i * 16], result_s1_1[1 + i * 16], result_s1_1[2 + i * 16], result_s1_1[3 + i * 16], result_s1_1[4 + i * 16], result_s1_1[5 + i * 16], result_s1_1[6 + i * 16], result_s1_1[7 + i * 16], result_s1_1[8 + i * 16], result_s1_1[9 + i * 16], result_s1_1[10 + i * 16], result_s1_1[11 + i * 16], result_s1_1[12 + i * 16], result_s1_1[13 + i * 16], result_s1_1[14 + i * 16], result_s1_1[15 + i * 16]};
        end
    end
    else begin
        for(i = 0; i < 4; i = i + 1) begin
            a[i] = 0;
        end
    end
end

//b
always@ (*) begin
    if(opening_closing_flag && (op_reg == opening || op_reg == closing)) begin
        for(i = 0; i < 4; i = i + 1) begin
            b[i] = {result_s2_1[0 + i * 16], result_s2_1[1 + i * 16], result_s2_1[2 + i * 16], result_s2_1[3 + i * 16], result_s2_1[4 + i * 16], result_s2_1[5 + i * 16], result_s2_1[6 + i * 16], result_s2_1[7 + i * 16], result_s2_1[8 + i * 16], result_s2_1[9 + i * 16], result_s2_1[10 + i * 16], result_s2_1[11 + i * 16], result_s2_1[12 + i * 16], result_s2_1[13 + i * 16], result_s2_1[14 + i * 16], result_s2_1[15 + i * 16]};
        end
    end
    else begin
        for(i = 0; i < 4; i = i + 1) begin
            b[i] = 0;
        end
    end
end

//h
always@ (*) begin
    if(in_valid) begin
        h = pic_data;
    end
    else begin
        h = 0;
    end
end

//cdf_min_index
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cdf_min_index <= 0;
    end
    else begin
        if(next_state == IDLE) begin
            cdf_min_index <= 255;
        end
        else if(in_valid) begin
            if(cdf_min_index > h_value) begin
                cdf_min_index <= h_value;
            end
        end
    end
end

//========================================================
// Calculation
//========================================================
//***************************************
// stage one: erosion and dilation
//***************************************
//result_s1_0
always@ (*) begin
    if(count_flag) begin
        if(pad_count <= 6) begin
            case(op_reg)
            erosion, opening: begin
                result_s1_0[0] = pic_reg_0[0][7:0] - se_reg[0];
                result_s1_0[1] = pic_reg_0[0][15:8] - se_reg[1];
                result_s1_0[2] = pic_reg_0[0][23:16] - se_reg[2];
                result_s1_0[3] = pic_reg_0[0][31:24] - se_reg[3];
                result_s1_0[4] = pic_reg_0[8][7:0] - se_reg[4];
                result_s1_0[5] = pic_reg_0[8][15:8] - se_reg[5];
                result_s1_0[6] = pic_reg_0[8][23:16] - se_reg[6];
                result_s1_0[7] = pic_reg_0[8][31:24] - se_reg[7];
                result_s1_0[8] = pic_reg_0[16][7:0] - se_reg[8];
                result_s1_0[9] = pic_reg_0[16][15:8] - se_reg[9];
                result_s1_0[10] = pic_reg_0[16][23:16] - se_reg[10];
                result_s1_0[11] = pic_reg_0[16][31:24] - se_reg[11];
                result_s1_0[12] = pic_reg_0[24][7:0] - se_reg[12];
                result_s1_0[13] = pic_reg_0[24][15:8] - se_reg[13];
                result_s1_0[14] = pic_reg_0[24][23:16] - se_reg[14];
                result_s1_0[15] = pic_reg_0[24][31:24] - se_reg[15];

                result_s1_0[16] = pic_reg_0[0][15:8] - se_reg[0];
                result_s1_0[17] = pic_reg_0[0][23:16] - se_reg[1];
                result_s1_0[18] = pic_reg_0[0][31:24] - se_reg[2];
                result_s1_0[19] = pic_reg_0[1][7:0] - se_reg[3];
                result_s1_0[20] = pic_reg_0[8][15:8] - se_reg[4];
                result_s1_0[21] = pic_reg_0[8][23:16] - se_reg[5];
                result_s1_0[22] = pic_reg_0[8][31:24] - se_reg[6];
                result_s1_0[23] = pic_reg_0[9][7:0] - se_reg[7];
                result_s1_0[24] = pic_reg_0[16][15:8] - se_reg[8];
                result_s1_0[25] = pic_reg_0[16][23:16] - se_reg[9];
                result_s1_0[26] = pic_reg_0[16][31:24] - se_reg[10];
                result_s1_0[27] = pic_reg_0[17][7:0] - se_reg[11];
                result_s1_0[28] = pic_reg_0[24][15:8] - se_reg[12];
                result_s1_0[29] = pic_reg_0[24][23:16] - se_reg[13];
                result_s1_0[30] = pic_reg_0[24][31:24] - se_reg[14];
                result_s1_0[31] = pic_reg_0[25][7:0] - se_reg[15];

                result_s1_0[32] = pic_reg_0[0][23:16] - se_reg[0];
                result_s1_0[33] = pic_reg_0[0][31:24] - se_reg[1];
                result_s1_0[34] = pic_reg_0[1][7:0] - se_reg[2];
                result_s1_0[35] = pic_reg_0[1][15:8] - se_reg[3];
                result_s1_0[36] = pic_reg_0[8][23:16] - se_reg[4];
                result_s1_0[37] = pic_reg_0[8][31:24] - se_reg[5];
                result_s1_0[38] = pic_reg_0[9][7:0] - se_reg[6];
                result_s1_0[39] = pic_reg_0[9][15:8] - se_reg[7];
                result_s1_0[40] = pic_reg_0[16][23:16] - se_reg[8];
                result_s1_0[41] = pic_reg_0[16][31:24] - se_reg[9];
                result_s1_0[42] = pic_reg_0[17][7:0] - se_reg[10];
                result_s1_0[43] = pic_reg_0[17][15:8] - se_reg[11];
                result_s1_0[44] = pic_reg_0[24][23:16] - se_reg[12];
                result_s1_0[45] = pic_reg_0[24][31:24] - se_reg[13];
                result_s1_0[46] = pic_reg_0[25][7:0] - se_reg[14];
                result_s1_0[47] = pic_reg_0[25][15:8] - se_reg[15];

                result_s1_0[48] = pic_reg_0[0][31:24] - se_reg[0];
                result_s1_0[49] = pic_reg_0[1][7:0] - se_reg[1];
                result_s1_0[50] = pic_reg_0[1][15:8] - se_reg[2];
                result_s1_0[51] = pic_reg_0[1][23:16] - se_reg[3];
                result_s1_0[52] = pic_reg_0[8][31:24] - se_reg[4];
                result_s1_0[53] = pic_reg_0[9][7:0] - se_reg[5];
                result_s1_0[54] = pic_reg_0[9][15:8] - se_reg[6];
                result_s1_0[55] = pic_reg_0[9][23:16] - se_reg[7];
                result_s1_0[56] = pic_reg_0[16][31:24] - se_reg[8];
                result_s1_0[57] = pic_reg_0[17][7:0] - se_reg[9];
                result_s1_0[58] = pic_reg_0[17][15:8] - se_reg[10];
                result_s1_0[59] = pic_reg_0[17][23:16] - se_reg[11];
                result_s1_0[60] = pic_reg_0[24][31:24] - se_reg[12];
                result_s1_0[61] = pic_reg_0[25][7:0] - se_reg[13];
                result_s1_0[62] = pic_reg_0[25][15:8] - se_reg[14];
                result_s1_0[63] = pic_reg_0[25][23:16] - se_reg[15];
            end
            dilation, closing: begin
                result_s1_0[0] = pic_reg_0[0][7:0] + se_reg[15];
                result_s1_0[1] = pic_reg_0[0][15:8] + se_reg[14];
                result_s1_0[2] = pic_reg_0[0][23:16] + se_reg[13];
                result_s1_0[3] = pic_reg_0[0][31:24] + se_reg[12];
                result_s1_0[4] = pic_reg_0[8][7:0] + se_reg[11];
                result_s1_0[5] = pic_reg_0[8][15:8] + se_reg[10];
                result_s1_0[6] = pic_reg_0[8][23:16] + se_reg[9];
                result_s1_0[7] = pic_reg_0[8][31:24] + se_reg[8];
                result_s1_0[8] = pic_reg_0[16][7:0] + se_reg[7];
                result_s1_0[9] = pic_reg_0[16][15:8] + se_reg[6];
                result_s1_0[10] = pic_reg_0[16][23:16] + se_reg[5];
                result_s1_0[11] = pic_reg_0[16][31:24] + se_reg[4];
                result_s1_0[12] = pic_reg_0[24][7:0] + se_reg[3];
                result_s1_0[13] = pic_reg_0[24][15:8] + se_reg[2];
                result_s1_0[14] = pic_reg_0[24][23:16] + se_reg[1];
                result_s1_0[15] = pic_reg_0[24][31:24] + se_reg[0];

                result_s1_0[16] = pic_reg_0[0][15:8] + se_reg[15];
                result_s1_0[17] = pic_reg_0[0][23:16] + se_reg[14];
                result_s1_0[18] = pic_reg_0[0][31:24] + se_reg[13];
                result_s1_0[19] = pic_reg_0[1][7:0] + se_reg[12];
                result_s1_0[20] = pic_reg_0[8][15:8] + se_reg[11];
                result_s1_0[21] = pic_reg_0[8][23:16] + se_reg[10];
                result_s1_0[22] = pic_reg_0[8][31:24] + se_reg[9];
                result_s1_0[23] = pic_reg_0[9][7:0] + se_reg[8];
                result_s1_0[24] = pic_reg_0[16][15:8] + se_reg[7];
                result_s1_0[25] = pic_reg_0[16][23:16] + se_reg[6];
                result_s1_0[26] = pic_reg_0[16][31:24] + se_reg[5];
                result_s1_0[27] = pic_reg_0[17][7:0] + se_reg[4];
                result_s1_0[28] = pic_reg_0[24][15:8] + se_reg[3];
                result_s1_0[29] = pic_reg_0[24][23:16] + se_reg[2];
                result_s1_0[30] = pic_reg_0[24][31:24] + se_reg[1];
                result_s1_0[31] = pic_reg_0[25][7:0] + se_reg[0];

                result_s1_0[32] = pic_reg_0[0][23:16] + se_reg[15];
                result_s1_0[33] = pic_reg_0[0][31:24] + se_reg[14];
                result_s1_0[34] = pic_reg_0[1][7:0] + se_reg[13];
                result_s1_0[35] = pic_reg_0[1][15:8] + se_reg[12];
                result_s1_0[36] = pic_reg_0[8][23:16] + se_reg[11];
                result_s1_0[37] = pic_reg_0[8][31:24] + se_reg[10];
                result_s1_0[38] = pic_reg_0[9][7:0] + se_reg[9];
                result_s1_0[39] = pic_reg_0[9][15:8] + se_reg[8];
                result_s1_0[40] = pic_reg_0[16][23:16] + se_reg[7];
                result_s1_0[41] = pic_reg_0[16][31:24] + se_reg[6];
                result_s1_0[42] = pic_reg_0[17][7:0] + se_reg[5];
                result_s1_0[43] = pic_reg_0[17][15:8] + se_reg[4];
                result_s1_0[44] = pic_reg_0[24][23:16] + se_reg[3];
                result_s1_0[45] = pic_reg_0[24][31:24] + se_reg[2];
                result_s1_0[46] = pic_reg_0[25][7:0] + se_reg[1];
                result_s1_0[47] = pic_reg_0[25][15:8] + se_reg[0];

                result_s1_0[48] = pic_reg_0[0][31:24] + se_reg[15];
                result_s1_0[49] = pic_reg_0[1][7:0] + se_reg[14];
                result_s1_0[50] = pic_reg_0[1][15:8] + se_reg[13];
                result_s1_0[51] = pic_reg_0[1][23:16] + se_reg[12];
                result_s1_0[52] = pic_reg_0[8][31:24] + se_reg[11];
                result_s1_0[53] = pic_reg_0[9][7:0] + se_reg[10];
                result_s1_0[54] = pic_reg_0[9][15:8] + se_reg[9];
                result_s1_0[55] = pic_reg_0[9][23:16] + se_reg[8];
                result_s1_0[56] = pic_reg_0[16][31:24] + se_reg[7];
                result_s1_0[57] = pic_reg_0[17][7:0] + se_reg[6];
                result_s1_0[58] = pic_reg_0[17][15:8] + se_reg[5];
                result_s1_0[59] = pic_reg_0[17][23:16] + se_reg[4];
                result_s1_0[60] = pic_reg_0[24][31:24] + se_reg[3];
                result_s1_0[61] = pic_reg_0[25][7:0] + se_reg[2];
                result_s1_0[62] = pic_reg_0[25][15:8] + se_reg[1];
                result_s1_0[63] = pic_reg_0[25][23:16] + se_reg[0];
            end
            default: begin
                for(i = 0; i < 64; i = i + 1) begin
                    result_s1_0[i] = 0;
                end
            end
            endcase
        end
        else begin //pad
            case(op_reg)
            erosion, opening: begin
                result_s1_0[0] = pic_reg_0[0][7:0] - se_reg[0];
                result_s1_0[1] = pic_reg_0[0][15:8] - se_reg[1];
                result_s1_0[2] = pic_reg_0[0][23:16] - se_reg[2];
                result_s1_0[3] = pic_reg_0[0][31:24] - se_reg[3];
                result_s1_0[4] = pic_reg_0[8][7:0] - se_reg[4];
                result_s1_0[5] = pic_reg_0[8][15:8] - se_reg[5];
                result_s1_0[6] = pic_reg_0[8][23:16] - se_reg[6];
                result_s1_0[7] = pic_reg_0[8][31:24] - se_reg[7];
                result_s1_0[8] = pic_reg_0[16][7:0] - se_reg[8];
                result_s1_0[9] = pic_reg_0[16][15:8] - se_reg[9];
                result_s1_0[10] = pic_reg_0[16][23:16] - se_reg[10];
                result_s1_0[11] = pic_reg_0[16][31:24] - se_reg[11];
                result_s1_0[12] = pic_reg_0[24][7:0] - se_reg[12];
                result_s1_0[13] = pic_reg_0[24][15:8] - se_reg[13];
                result_s1_0[14] = pic_reg_0[24][23:16] - se_reg[14];
                result_s1_0[15] = pic_reg_0[24][31:24] - se_reg[15];

                result_s1_0[16] = pic_reg_0[0][15:8] - se_reg[0];
                result_s1_0[17] = pic_reg_0[0][23:16] - se_reg[1];
                result_s1_0[18] = pic_reg_0[0][31:24] - se_reg[2];
                result_s1_0[19] = 0;
                result_s1_0[20] = pic_reg_0[8][15:8] - se_reg[4];
                result_s1_0[21] = pic_reg_0[8][23:16] - se_reg[5];
                result_s1_0[22] = pic_reg_0[8][31:24] - se_reg[6];
                result_s1_0[23] = 0;
                result_s1_0[24] = pic_reg_0[16][15:8] - se_reg[8];
                result_s1_0[25] = pic_reg_0[16][23:16] - se_reg[9];
                result_s1_0[26] = pic_reg_0[16][31:24] - se_reg[10];
                result_s1_0[27] = 0;
                result_s1_0[28] = pic_reg_0[24][15:8] - se_reg[12];
                result_s1_0[29] = pic_reg_0[24][23:16] - se_reg[13];
                result_s1_0[30] = pic_reg_0[24][31:24] - se_reg[14];
                result_s1_0[31] = 0;

                result_s1_0[32] = pic_reg_0[0][23:16] - se_reg[0];
                result_s1_0[33] = pic_reg_0[0][31:24] - se_reg[1];
                result_s1_0[34] = 0;
                result_s1_0[35] = 0;
                result_s1_0[36] = pic_reg_0[8][23:16] - se_reg[4];
                result_s1_0[37] = pic_reg_0[8][31:24] - se_reg[5];
                result_s1_0[38] = 0;
                result_s1_0[39] = 0;
                result_s1_0[40] = pic_reg_0[16][23:16] - se_reg[8];
                result_s1_0[41] = pic_reg_0[16][31:24] - se_reg[9];
                result_s1_0[42] = 0;
                result_s1_0[43] = 0;
                result_s1_0[44] = pic_reg_0[24][23:16] - se_reg[12];
                result_s1_0[45] = pic_reg_0[24][31:24] - se_reg[13];
                result_s1_0[46] = 0;
                result_s1_0[47] = 0;

                result_s1_0[48] = pic_reg_0[0][31:24] - se_reg[0];
                result_s1_0[49] = 0;
                result_s1_0[50] = 0;
                result_s1_0[51] = 0;
                result_s1_0[52] = pic_reg_0[8][31:24] - se_reg[4];
                result_s1_0[53] = 0;
                result_s1_0[54] = 0;
                result_s1_0[55] = 0;
                result_s1_0[56] = pic_reg_0[16][31:24] - se_reg[8];
                result_s1_0[57] = 0;
                result_s1_0[58] = 0;
                result_s1_0[59] = 0;
                result_s1_0[60] = pic_reg_0[24][31:24] - se_reg[12];
                result_s1_0[61] = 0;
                result_s1_0[62] = 0;
                result_s1_0[63] = 0;
            end
            dilation, closing: begin
                result_s1_0[0] = pic_reg_0[0][7:0] + se_reg[15];
                result_s1_0[1] = pic_reg_0[0][15:8] + se_reg[14];
                result_s1_0[2] = pic_reg_0[0][23:16] + se_reg[13];
                result_s1_0[3] = pic_reg_0[0][31:24] + se_reg[12];
                result_s1_0[4] = pic_reg_0[8][7:0] + se_reg[11];
                result_s1_0[5] = pic_reg_0[8][15:8] + se_reg[10];
                result_s1_0[6] = pic_reg_0[8][23:16] + se_reg[9];
                result_s1_0[7] = pic_reg_0[8][31:24] + se_reg[8];
                result_s1_0[8] = pic_reg_0[16][7:0] + se_reg[7];
                result_s1_0[9] = pic_reg_0[16][15:8] + se_reg[6];
                result_s1_0[10] = pic_reg_0[16][23:16] + se_reg[5];
                result_s1_0[11] = pic_reg_0[16][31:24] + se_reg[4];
                result_s1_0[12] = pic_reg_0[24][7:0] + se_reg[3];
                result_s1_0[13] = pic_reg_0[24][15:8] + se_reg[2];
                result_s1_0[14] = pic_reg_0[24][23:16] + se_reg[1];
                result_s1_0[15] = pic_reg_0[24][31:24] + se_reg[0];

                result_s1_0[16] = pic_reg_0[0][15:8] + se_reg[15];
                result_s1_0[17] = pic_reg_0[0][23:16] + se_reg[14];
                result_s1_0[18] = pic_reg_0[0][31:24] + se_reg[13];
                result_s1_0[19] = se_reg[12];
                result_s1_0[20] = pic_reg_0[8][15:8] + se_reg[11];
                result_s1_0[21] = pic_reg_0[8][23:16] + se_reg[10];
                result_s1_0[22] = pic_reg_0[8][31:24] + se_reg[9];
                result_s1_0[23] = se_reg[8];
                result_s1_0[24] = pic_reg_0[16][15:8] + se_reg[7];
                result_s1_0[25] = pic_reg_0[16][23:16] + se_reg[6];
                result_s1_0[26] = pic_reg_0[16][31:24] + se_reg[5];
                result_s1_0[27] = se_reg[4];
                result_s1_0[28] = pic_reg_0[24][15:8] + se_reg[3];
                result_s1_0[29] = pic_reg_0[24][23:16] + se_reg[2];
                result_s1_0[30] = pic_reg_0[24][31:24] + se_reg[1];
                result_s1_0[31] = se_reg[0];

                result_s1_0[32] = pic_reg_0[0][23:16] + se_reg[15];
                result_s1_0[33] = pic_reg_0[0][31:24] + se_reg[14];
                result_s1_0[34] = se_reg[13];
                result_s1_0[35] = se_reg[12];
                result_s1_0[36] = pic_reg_0[8][23:16] + se_reg[11];
                result_s1_0[37] = pic_reg_0[8][31:24] + se_reg[10];
                result_s1_0[38] = se_reg[9];
                result_s1_0[39] = se_reg[8];
                result_s1_0[40] = pic_reg_0[16][23:16] + se_reg[7];
                result_s1_0[41] = pic_reg_0[16][31:24] + se_reg[6];
                result_s1_0[42] = se_reg[5];
                result_s1_0[43] = se_reg[4];
                result_s1_0[44] = pic_reg_0[24][23:16] + se_reg[3];
                result_s1_0[45] = pic_reg_0[24][31:24] + se_reg[2];
                result_s1_0[46] = se_reg[1];
                result_s1_0[47] = se_reg[0];

                result_s1_0[48] = pic_reg_0[0][31:24] + se_reg[15];
                result_s1_0[49] = se_reg[14];
                result_s1_0[50] = se_reg[13];
                result_s1_0[51] = se_reg[12];
                result_s1_0[52] = pic_reg_0[8][31:24] + se_reg[11];
                result_s1_0[53] = se_reg[10];
                result_s1_0[54] = se_reg[9];
                result_s1_0[55] = se_reg[8];
                result_s1_0[56] = pic_reg_0[16][31:24] + se_reg[7];
                result_s1_0[57] = se_reg[6];
                result_s1_0[58] = se_reg[5];
                result_s1_0[59] = se_reg[4];
                result_s1_0[60] = pic_reg_0[24][31:24] + se_reg[3];
                result_s1_0[61] = se_reg[2];
                result_s1_0[62] = se_reg[1];
                result_s1_0[63] = se_reg[0];

            end
            default: begin
                for(i = 0; i < 64; i = i + 1) begin
                    result_s1_0[i] = 0;
                end
            end
            endcase
        end
    end
    else begin
        for(i = 0; i < 64; i = i + 1) begin
            result_s1_0[i] = 0;
        end
    end
end

//avoid overflow
always@ (*) begin
    if(/*current_state == CAL &&*/ count_flag) begin
        case(op_reg)
        erosion, opening: begin
            for(i = 0; i < 64; i = i + 1) begin
                result_s1_1[i] = (result_s1_0[i][8] == 1) ? 0 : result_s1_0[i];
            end
        end
        dilation, closing: begin
            for(i = 0; i < 64; i = i + 1) begin
                result_s1_1[i] = (result_s1_0[i][8] == 1) ? 255 : result_s1_0[i];
            end
        end
        default: begin
            for(i = 0; i < 64; i = i + 1) begin
                result_s1_1[i] = 0;
            end
        end
        endcase
    end
    else begin
        for(i = 0; i < 64; i = i + 1) begin
            result_s1_1[i] = 0;
        end
    end
end

//***************************************
// stage two: opening and closing
//***************************************
//result_s2_0
always@ (*) begin
    if(opening_closing_flag) begin
        if(pad_count_2 <= 6) begin
            case(op_reg)
            closing: begin
                result_s2_0[0] = pic_reg_1[0][7:0] - se_reg[0];
                result_s2_0[1] = pic_reg_1[0][15:8] - se_reg[1];
                result_s2_0[2] = pic_reg_1[0][23:16] - se_reg[2];
                result_s2_0[3] = pic_reg_1[0][31:24] - se_reg[3];
                result_s2_0[4] = pic_reg_1[8][7:0] - se_reg[4];
                result_s2_0[5] = pic_reg_1[8][15:8] - se_reg[5];
                result_s2_0[6] = pic_reg_1[8][23:16] - se_reg[6];
                result_s2_0[7] = pic_reg_1[8][31:24] - se_reg[7];
                result_s2_0[8] = pic_reg_1[16][7:0] - se_reg[8];
                result_s2_0[9] = pic_reg_1[16][15:8] - se_reg[9];
                result_s2_0[10] = pic_reg_1[16][23:16] - se_reg[10];
                result_s2_0[11] = pic_reg_1[16][31:24] - se_reg[11];
                result_s2_0[12] = pic_reg_1[24][7:0] - se_reg[12];
                result_s2_0[13] = pic_reg_1[24][15:8] - se_reg[13];
                result_s2_0[14] = pic_reg_1[24][23:16] - se_reg[14];
                result_s2_0[15] = pic_reg_1[24][31:24] - se_reg[15];

                result_s2_0[16] = pic_reg_1[0][15:8] - se_reg[0];
                result_s2_0[17] = pic_reg_1[0][23:16] - se_reg[1];
                result_s2_0[18] = pic_reg_1[0][31:24] - se_reg[2];
                result_s2_0[19] = pic_reg_1[1][7:0] - se_reg[3];
                result_s2_0[20] = pic_reg_1[8][15:8] - se_reg[4];
                result_s2_0[21] = pic_reg_1[8][23:16] - se_reg[5];
                result_s2_0[22] = pic_reg_1[8][31:24] - se_reg[6];
                result_s2_0[23] = pic_reg_1[9][7:0] - se_reg[7];
                result_s2_0[24] = pic_reg_1[16][15:8] - se_reg[8];
                result_s2_0[25] = pic_reg_1[16][23:16] - se_reg[9];
                result_s2_0[26] = pic_reg_1[16][31:24] - se_reg[10];
                result_s2_0[27] = pic_reg_1[17][7:0] - se_reg[11];
                result_s2_0[28] = pic_reg_1[24][15:8] - se_reg[12];
                result_s2_0[29] = pic_reg_1[24][23:16] - se_reg[13];
                result_s2_0[30] = pic_reg_1[24][31:24] - se_reg[14];
                result_s2_0[31] = pic_reg_1[25][7:0] - se_reg[15];

                result_s2_0[32] = pic_reg_1[0][23:16] - se_reg[0];
                result_s2_0[33] = pic_reg_1[0][31:24] - se_reg[1];
                result_s2_0[34] = pic_reg_1[1][7:0] - se_reg[2];
                result_s2_0[35] = pic_reg_1[1][15:8] - se_reg[3];
                result_s2_0[36] = pic_reg_1[8][23:16] - se_reg[4];
                result_s2_0[37] = pic_reg_1[8][31:24] - se_reg[5];
                result_s2_0[38] = pic_reg_1[9][7:0] - se_reg[6];
                result_s2_0[39] = pic_reg_1[9][15:8] - se_reg[7];
                result_s2_0[40] = pic_reg_1[16][23:16] - se_reg[8];
                result_s2_0[41] = pic_reg_1[16][31:24] - se_reg[9];
                result_s2_0[42] = pic_reg_1[17][7:0] - se_reg[10];
                result_s2_0[43] = pic_reg_1[17][15:8] - se_reg[11];
                result_s2_0[44] = pic_reg_1[24][23:16] - se_reg[12];
                result_s2_0[45] = pic_reg_1[24][31:24] - se_reg[13];
                result_s2_0[46] = pic_reg_1[25][7:0] - se_reg[14];
                result_s2_0[47] = pic_reg_1[25][15:8] - se_reg[15];

                result_s2_0[48] = pic_reg_1[0][31:24] - se_reg[0];
                result_s2_0[49] = pic_reg_1[1][7:0] - se_reg[1];
                result_s2_0[50] = pic_reg_1[1][15:8] - se_reg[2];
                result_s2_0[51] = pic_reg_1[1][23:16] - se_reg[3];
                result_s2_0[52] = pic_reg_1[8][31:24] - se_reg[4];
                result_s2_0[53] = pic_reg_1[9][7:0] - se_reg[5];
                result_s2_0[54] = pic_reg_1[9][15:8] - se_reg[6];
                result_s2_0[55] = pic_reg_1[9][23:16] - se_reg[7];
                result_s2_0[56] = pic_reg_1[16][31:24] - se_reg[8];
                result_s2_0[57] = pic_reg_1[17][7:0] - se_reg[9];
                result_s2_0[58] = pic_reg_1[17][15:8] - se_reg[10];
                result_s2_0[59] = pic_reg_1[17][23:16] - se_reg[11];
                result_s2_0[60] = pic_reg_1[24][31:24] - se_reg[12];
                result_s2_0[61] = pic_reg_1[25][7:0] - se_reg[13];
                result_s2_0[62] = pic_reg_1[25][15:8] - se_reg[14];
                result_s2_0[63] = pic_reg_1[25][23:16] - se_reg[15];
            end
            opening: begin
                result_s2_0[0] = pic_reg_1[0][7:0] + se_reg[15];
                result_s2_0[1] = pic_reg_1[0][15:8] + se_reg[14];
                result_s2_0[2] = pic_reg_1[0][23:16] + se_reg[13];
                result_s2_0[3] = pic_reg_1[0][31:24] + se_reg[12];
                result_s2_0[4] = pic_reg_1[8][7:0] + se_reg[11];
                result_s2_0[5] = pic_reg_1[8][15:8] + se_reg[10];
                result_s2_0[6] = pic_reg_1[8][23:16] + se_reg[9];
                result_s2_0[7] = pic_reg_1[8][31:24] + se_reg[8];
                result_s2_0[8] = pic_reg_1[16][7:0] + se_reg[7];
                result_s2_0[9] = pic_reg_1[16][15:8] + se_reg[6];
                result_s2_0[10] = pic_reg_1[16][23:16] + se_reg[5];
                result_s2_0[11] = pic_reg_1[16][31:24] + se_reg[4];
                result_s2_0[12] = pic_reg_1[24][7:0] + se_reg[3];
                result_s2_0[13] = pic_reg_1[24][15:8] + se_reg[2];
                result_s2_0[14] = pic_reg_1[24][23:16] + se_reg[1];
                result_s2_0[15] = pic_reg_1[24][31:24] + se_reg[0];

                result_s2_0[16] = pic_reg_1[0][15:8] + se_reg[15];
                result_s2_0[17] = pic_reg_1[0][23:16] + se_reg[14];
                result_s2_0[18] = pic_reg_1[0][31:24] + se_reg[13];
                result_s2_0[19] = pic_reg_1[1][7:0] + se_reg[12];
                result_s2_0[20] = pic_reg_1[8][15:8] + se_reg[11];
                result_s2_0[21] = pic_reg_1[8][23:16] + se_reg[10];
                result_s2_0[22] = pic_reg_1[8][31:24] + se_reg[9];
                result_s2_0[23] = pic_reg_1[9][7:0] + se_reg[8];
                result_s2_0[24] = pic_reg_1[16][15:8] + se_reg[7];
                result_s2_0[25] = pic_reg_1[16][23:16] + se_reg[6];
                result_s2_0[26] = pic_reg_1[16][31:24] + se_reg[5];
                result_s2_0[27] = pic_reg_1[17][7:0] + se_reg[4];
                result_s2_0[28] = pic_reg_1[24][15:8] + se_reg[3];
                result_s2_0[29] = pic_reg_1[24][23:16] + se_reg[2];
                result_s2_0[30] = pic_reg_1[24][31:24] + se_reg[1];
                result_s2_0[31] = pic_reg_1[25][7:0] + se_reg[0];

                result_s2_0[32] = pic_reg_1[0][23:16] + se_reg[15];
                result_s2_0[33] = pic_reg_1[0][31:24] + se_reg[14];
                result_s2_0[34] = pic_reg_1[1][7:0] + se_reg[13];
                result_s2_0[35] = pic_reg_1[1][15:8] + se_reg[12];
                result_s2_0[36] = pic_reg_1[8][23:16] + se_reg[11];
                result_s2_0[37] = pic_reg_1[8][31:24] + se_reg[10];
                result_s2_0[38] = pic_reg_1[9][7:0] + se_reg[9];
                result_s2_0[39] = pic_reg_1[9][15:8] + se_reg[8];
                result_s2_0[40] = pic_reg_1[16][23:16] + se_reg[7];
                result_s2_0[41] = pic_reg_1[16][31:24] + se_reg[6];
                result_s2_0[42] = pic_reg_1[17][7:0] + se_reg[5];
                result_s2_0[43] = pic_reg_1[17][15:8] + se_reg[4];
                result_s2_0[44] = pic_reg_1[24][23:16] + se_reg[3];
                result_s2_0[45] = pic_reg_1[24][31:24] + se_reg[2];
                result_s2_0[46] = pic_reg_1[25][7:0] + se_reg[1];
                result_s2_0[47] = pic_reg_1[25][15:8] + se_reg[0];

                result_s2_0[48] = pic_reg_1[0][31:24] + se_reg[15];
                result_s2_0[49] = pic_reg_1[1][7:0] + se_reg[14];
                result_s2_0[50] = pic_reg_1[1][15:8] + se_reg[13];
                result_s2_0[51] = pic_reg_1[1][23:16] + se_reg[12];
                result_s2_0[52] = pic_reg_1[8][31:24] + se_reg[11];
                result_s2_0[53] = pic_reg_1[9][7:0] + se_reg[10];
                result_s2_0[54] = pic_reg_1[9][15:8] + se_reg[9];
                result_s2_0[55] = pic_reg_1[9][23:16] + se_reg[8];
                result_s2_0[56] = pic_reg_1[16][31:24] + se_reg[7];
                result_s2_0[57] = pic_reg_1[17][7:0] + se_reg[6];
                result_s2_0[58] = pic_reg_1[17][15:8] + se_reg[5];
                result_s2_0[59] = pic_reg_1[17][23:16] + se_reg[4];
                result_s2_0[60] = pic_reg_1[24][31:24] + se_reg[3];
                result_s2_0[61] = pic_reg_1[25][7:0] + se_reg[2];
                result_s2_0[62] = pic_reg_1[25][15:8] + se_reg[1];
                result_s2_0[63] = pic_reg_1[25][23:16] + se_reg[0];
            end
            default: begin
                for(i = 0; i < 64; i = i + 1) begin
                    result_s2_0[i] = 0;
                end
            end
            endcase
        end
        else begin //pad
            case(op_reg)
            closing: begin
                result_s2_0[0] = pic_reg_1[0][7:0] - se_reg[0];
                result_s2_0[1] = pic_reg_1[0][15:8] - se_reg[1];
                result_s2_0[2] = pic_reg_1[0][23:16] - se_reg[2];
                result_s2_0[3] = pic_reg_1[0][31:24] - se_reg[3];
                result_s2_0[4] = pic_reg_1[8][7:0] - se_reg[4];
                result_s2_0[5] = pic_reg_1[8][15:8] - se_reg[5];
                result_s2_0[6] = pic_reg_1[8][23:16] - se_reg[6];
                result_s2_0[7] = pic_reg_1[8][31:24] - se_reg[7];
                result_s2_0[8] = pic_reg_1[16][7:0] - se_reg[8];
                result_s2_0[9] = pic_reg_1[16][15:8] - se_reg[9];
                result_s2_0[10] = pic_reg_1[16][23:16] - se_reg[10];
                result_s2_0[11] = pic_reg_1[16][31:24] - se_reg[11];
                result_s2_0[12] = pic_reg_1[24][7:0] - se_reg[12];
                result_s2_0[13] = pic_reg_1[24][15:8] - se_reg[13];
                result_s2_0[14] = pic_reg_1[24][23:16] - se_reg[14];
                result_s2_0[15] = pic_reg_1[24][31:24] - se_reg[15];

                result_s2_0[16] = pic_reg_1[0][15:8] - se_reg[0];
                result_s2_0[17] = pic_reg_1[0][23:16] - se_reg[1];
                result_s2_0[18] = pic_reg_1[0][31:24] - se_reg[2];
                result_s2_0[19] = 0;
                result_s2_0[20] = pic_reg_1[8][15:8] - se_reg[4];
                result_s2_0[21] = pic_reg_1[8][23:16] - se_reg[5];
                result_s2_0[22] = pic_reg_1[8][31:24] - se_reg[6];
                result_s2_0[23] = 0;
                result_s2_0[24] = pic_reg_1[16][15:8] - se_reg[8];
                result_s2_0[25] = pic_reg_1[16][23:16] - se_reg[9];
                result_s2_0[26] = pic_reg_1[16][31:24] - se_reg[10];
                result_s2_0[27] = 0;
                result_s2_0[28] = pic_reg_1[24][15:8] - se_reg[12];
                result_s2_0[29] = pic_reg_1[24][23:16] - se_reg[13];
                result_s2_0[30] = pic_reg_1[24][31:24] - se_reg[14];
                result_s2_0[31] = 0;

                result_s2_0[32] = pic_reg_1[0][23:16] - se_reg[0];
                result_s2_0[33] = pic_reg_1[0][31:24] - se_reg[1];
                result_s2_0[34] = 0;
                result_s2_0[35] = 0;
                result_s2_0[36] = pic_reg_1[8][23:16] - se_reg[4];
                result_s2_0[37] = pic_reg_1[8][31:24] - se_reg[5];
                result_s2_0[38] = 0;
                result_s2_0[39] = 0;
                result_s2_0[40] = pic_reg_1[16][23:16] - se_reg[8];
                result_s2_0[41] = pic_reg_1[16][31:24] - se_reg[9];
                result_s2_0[42] = 0;
                result_s2_0[43] = 0;
                result_s2_0[44] = pic_reg_1[24][23:16] - se_reg[12];
                result_s2_0[45] = pic_reg_1[24][31:24] - se_reg[13];
                result_s2_0[46] = 0;
                result_s2_0[47] = 0;

                result_s2_0[48] = pic_reg_1[0][31:24] - se_reg[0];
                result_s2_0[49] = 0;
                result_s2_0[50] = 0;
                result_s2_0[51] = 0;
                result_s2_0[52] = pic_reg_1[8][31:24] - se_reg[4];
                result_s2_0[53] = 0;
                result_s2_0[54] = 0;
                result_s2_0[55] = 0;
                result_s2_0[56] = pic_reg_1[16][31:24] - se_reg[8];
                result_s2_0[57] = 0;
                result_s2_0[58] = 0;
                result_s2_0[59] = 0;
                result_s2_0[60] = pic_reg_1[24][31:24] - se_reg[12];
                result_s2_0[61] = 0;
                result_s2_0[62] = 0;
                result_s2_0[63] = 0;

            end
            opening: begin
                result_s2_0[0] = pic_reg_1[0][7:0] + se_reg[15];
                result_s2_0[1] = pic_reg_1[0][15:8] + se_reg[14];
                result_s2_0[2] = pic_reg_1[0][23:16] + se_reg[13];
                result_s2_0[3] = pic_reg_1[0][31:24] + se_reg[12];
                result_s2_0[4] = pic_reg_1[8][7:0] + se_reg[11];
                result_s2_0[5] = pic_reg_1[8][15:8] + se_reg[10];
                result_s2_0[6] = pic_reg_1[8][23:16] + se_reg[9];
                result_s2_0[7] = pic_reg_1[8][31:24] + se_reg[8];
                result_s2_0[8] = pic_reg_1[16][7:0] + se_reg[7];
                result_s2_0[9] = pic_reg_1[16][15:8] + se_reg[6];
                result_s2_0[10] = pic_reg_1[16][23:16] + se_reg[5];
                result_s2_0[11] = pic_reg_1[16][31:24] + se_reg[4];
                result_s2_0[12] = pic_reg_1[24][7:0] + se_reg[3];
                result_s2_0[13] = pic_reg_1[24][15:8] + se_reg[2];
                result_s2_0[14] = pic_reg_1[24][23:16] + se_reg[1];
                result_s2_0[15] = pic_reg_1[24][31:24] + se_reg[0];

                result_s2_0[16] = pic_reg_1[0][15:8] + se_reg[15];
                result_s2_0[17] = pic_reg_1[0][23:16] + se_reg[14];
                result_s2_0[18] = pic_reg_1[0][31:24] + se_reg[13];
                result_s2_0[19] = se_reg[12];
                result_s2_0[20] = pic_reg_1[8][15:8] + se_reg[11];
                result_s2_0[21] = pic_reg_1[8][23:16] + se_reg[10];
                result_s2_0[22] = pic_reg_1[8][31:24] + se_reg[9];
                result_s2_0[23] = se_reg[8];
                result_s2_0[24] = pic_reg_1[16][15:8] + se_reg[7];
                result_s2_0[25] = pic_reg_1[16][23:16] + se_reg[6];
                result_s2_0[26] = pic_reg_1[16][31:24] + se_reg[5];
                result_s2_0[27] = se_reg[4];
                result_s2_0[28] = pic_reg_1[24][15:8] + se_reg[3];
                result_s2_0[29] = pic_reg_1[24][23:16] + se_reg[2];
                result_s2_0[30] = pic_reg_1[24][31:24] + se_reg[1];
                result_s2_0[31] = se_reg[0];

                result_s2_0[32] = pic_reg_1[0][23:16] + se_reg[15];
                result_s2_0[33] = pic_reg_1[0][31:24] + se_reg[14];
                result_s2_0[34] = se_reg[13];
                result_s2_0[35] = se_reg[12];
                result_s2_0[36] = pic_reg_1[8][23:16] + se_reg[11];
                result_s2_0[37] = pic_reg_1[8][31:24] + se_reg[10];
                result_s2_0[38] = se_reg[9];
                result_s2_0[39] = se_reg[8];
                result_s2_0[40] = pic_reg_1[16][23:16] + se_reg[7];
                result_s2_0[41] = pic_reg_1[16][31:24] + se_reg[6];
                result_s2_0[42] = se_reg[5];
                result_s2_0[43] = se_reg[4];
                result_s2_0[44] = pic_reg_1[24][23:16] + se_reg[3];
                result_s2_0[45] = pic_reg_1[24][31:24] + se_reg[2];
                result_s2_0[46] = se_reg[1];
                result_s2_0[47] = se_reg[0];

                result_s2_0[48] = pic_reg_1[0][31:24] + se_reg[15];
                result_s2_0[49] = se_reg[14];
                result_s2_0[50] = se_reg[13];
                result_s2_0[51] = se_reg[12];
                result_s2_0[52] = pic_reg_1[8][31:24] + se_reg[11];
                result_s2_0[53] = se_reg[10];
                result_s2_0[54] = se_reg[9];
                result_s2_0[55] = se_reg[8];
                result_s2_0[56] = pic_reg_1[16][31:24] + se_reg[7];
                result_s2_0[57] = se_reg[6];
                result_s2_0[58] = se_reg[5];
                result_s2_0[59] = se_reg[4];
                result_s2_0[60] = pic_reg_1[24][31:24] + se_reg[3];
                result_s2_0[61] = se_reg[2];
                result_s2_0[62] = se_reg[1];
                result_s2_0[63] = se_reg[0];
            end
            default: begin
                for(i = 0; i < 64; i = i + 1) begin
                    result_s2_0[i] = 0;
                end
            end
            endcase
        end
    end
    else begin
        for(i = 0; i < 64; i = i + 1) begin
            result_s2_0[i] = 0;
        end
    end
end

//avoid overflow
always@ (*) begin
    if(opening_closing_flag) begin
        case(op_reg)
        opening: begin
            for(i = 0; i < 64; i = i + 1) begin
                result_s2_1[i] = (result_s2_0[i][8] == 1) ? 255 : result_s2_0[i];
            end
        end
        closing: begin
            for(i = 0; i < 64; i = i + 1) begin
                result_s2_1[i] = (result_s2_0[i][8] == 1) ? 0 : result_s2_0[i];
            end
        end
        default: begin
            for(i = 0; i < 64; i = i + 1) begin
                result_s2_1[i] = 0;
            end
        end
        endcase
    end
    else begin
        for(i = 0; i < 64; i = i + 1) begin
            result_s2_1[i] = 0;
        end
    end
end


//***************************************
// histogram
//***************************************
//compute cdf
generate
for(m = 0; m < 256; m = m + 1) begin
    always@ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            h_acc[m] = 0;
        end
        else begin
            if(next_state == IDLE) begin
                h_acc[m] = 0;
            end
            else if(in_valid) begin
                if(pic_data[31:24] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(pic_data[23:16] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(pic_data[15:8] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(pic_data[7:0] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
            end
        end
    end
end

endgenerate

//cdf_min
// always@ (posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         cdf_min <= 0;
//     end
//     else begin
//         if(current_state == IDLE) begin
//             cdf_min <= 0;
//         end
//         else if(current_state == CAL) begin
//             cdf_min <= h_acc[cdf_min_index];
//         end
//     end
// end
always@ (*) begin
    if(current_state == IDLE) begin
        cdf_min = 0;
    end
    else if(current_state == CAL) begin
        cdf_min = h_acc[cdf_min_index];
    end
    else begin
        cdf_min = 0;
    end
end

//h_mult
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            h_mult[i] <= 0;
        end
    end
    else begin
        if(current_state == IDLE) begin
            for(i = 0; i < 4; i = i + 1) begin
                h_mult[i] <= 0;
            end
        end
        else if(current_state == CAL && op_reg == histogram && out_valid_count == 257) begin
            h_mult[3] <= (h_acc[out_reg[31:24]] - cdf_min) * 255;
            h_mult[2] <= (h_acc[out_reg[23:16]] - cdf_min) * 255;
            h_mult[1] <= (h_acc[out_reg[15:8]] - cdf_min) * 255;
            h_mult[0] <= (h_acc[out_reg[7:0]] - cdf_min) * 255;
        end
        else if(current_state == CAL && op_reg == histogram && addr_count >= 230 && out_valid_count < 257) begin
            h_mult[3] <= (h_acc[q_0[31:24]] - cdf_min) * 255;
            h_mult[2] <= (h_acc[q_0[23:16]] - cdf_min) * 255;
            h_mult[1] <= (h_acc[q_0[15:8]] - cdf_min) * 255;
            h_mult[0] <= (h_acc[q_0[7:0]] - cdf_min) * 255;
        end
    end
end

assign cdf_denominator = cdf_max - cdf_min;

//h_div
always@ (*) begin
    
    if(current_state == CAL && op_reg == histogram && out_valid_count == 258) begin
        for(i = 0; i < 4; i = i + 1) begin
            h_div[i] = h_mult[i] / cdf_denominator;
        end
    end
    else if(current_state == CAL && op_reg == histogram && addr_count >= 231) begin
        for(i = 0; i < 4; i = i + 1) begin
            h_div[i] = h_mult[i] / cdf_denominator;
        end
    end
    else begin
        for(i = 0; i < 4; i = i + 1) begin
            h_div[i] = 0;
        end
    end
    
end

//========================================================
// Output Block
//========================================================
//out_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_reg <= 0;
    end
    else begin
        if((op_reg == erosion || op_reg == dilation) && addr_count == 229) begin
            out_reg <= {value_0[3], value_0[2], value_0[1], value_0[0]};
        end
        else if((op_reg == opening || op_reg == closing) && addr_count == 229) begin
            out_reg <= {value_1[3], value_1[2], value_1[1], value_1[0]};
        end
        else if(op_reg == histogram && addr_count == 229 && in_valid) begin
            out_reg <= pic_data; 
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
        else if(addr_count >= 228) begin
            out_valid_count <= out_valid_count + 1;
        end
    end

end

//out_valid
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if((next_state == OUTPUT || current_state == OUTPUT) /*&& op_reg != histogram*/) begin
            // if(op_reg == histogram && addr_count >= 3) begin
            //     out_valid <= 1;
            // end
            //if(/*op_reg == erosion || op_reg == dilation*/op_reg != histogram) begin
                out_valid <= 1;
            //end
        end
        else if(current_state == CAL && op_reg == histogram && addr_count >= 231) begin
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

        if((next_state == OUTPUT || current_state == OUTPUT) /*&& op_reg != histogram*/) begin
            if(op_reg == erosion || op_reg == dilation) begin
                if(out_valid_count <= 230) begin
                    out_data <= q_0;
                end
                else if(out_valid_count == 231) begin
                    out_data <= out_reg;
                end
                else begin
                    out_data <= {value_0[3], value_0[2], value_0[1], value_0[0]};
                end
            end
            else if(op_reg == closing || op_reg == opening) begin
                if(out_valid_count <= 204) begin
                    out_data <= q_0;
                end
                else if(out_valid_count == 205) begin
                    out_data <= out_reg;
                end
                else begin
                    out_data <= {value_1[3], value_1[2], value_1[1], value_1[0]};
                end
            end
            else begin
                out_data <= 0;
            end
        end
        else if(current_state == CAL && op_reg == histogram && addr_count > 230) begin
            out_data <= {h_div[3], h_div[2], h_div[1], h_div[0]};
        end
        else begin
            out_data <= 0;
        end
    end
end

endmodule