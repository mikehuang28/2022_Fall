//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Midterm Project
//   File Name   : EDH.v
//   Module Name : EDH
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_minmax.v"
//synopsys translate_on

module EDH(
    clk,
    rst_n,
    in_valid,
    op,
    pic_no,
    se_no,
    busy,

    awid_m_inf,
    awaddr_m_inf,
    awsize_m_inf,
    awburst_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,

    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,

    bid_m_inf,
    bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf,

    arid_m_inf,
    araddr_m_inf,
    arlen_m_inf,
    arsize_m_inf,
    arburst_m_inf,
    arvalid_m_inf,
    arready_m_inf,

    rid_m_inf,
    rdata_m_inf,
    rresp_m_inf,
    rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf
);

//========================================================
// Parameter Declaration
//========================================================
//axi
parameter ID_WIDTH = 4;
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 128;

//fsm
parameter IDLE = 0;
parameter READ_SE = 1;
parameter READ_PIC = 2;
parameter WRITE_DRAM = 3;

//designware
parameter width = 8;
parameter num_inputs = 16;

parameter cdf_max = 4096;
integer i;
genvar m;

//========================================================
// Input and Output Declaration
//========================================================
input clk, rst_n, in_valid;
input [1:0] op;
input [3:0] pic_no;
input [5:0] se_no;
output reg busy;

//axi write address channel
output wire [ID_WIDTH-1:0]    awid_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [1:0]             awburst_m_inf;
output wire [7:0]             awlen_m_inf;
output reg                    awvalid_m_inf;
input wire                    awready_m_inf;

// axi write data channel
output reg [DATA_WIDTH-1:0]  wdata_m_inf;
output wire                  wlast_m_inf;
output wire                  wvalid_m_inf;
input wire                   wready_m_inf;

// axi write response channel
input wire [ID_WIDTH-1:0]    bid_m_inf;
input wire [1:0]             bresp_m_inf;
input wire                   bvalid_m_inf;
output wire                  bready_m_inf;

// axi read address channel
output wire [ID_WIDTH-1:0]   arid_m_inf;
output reg [ADDR_WIDTH-1:0]  araddr_m_inf;
output wire [7:0]            arlen_m_inf;
output wire [2:0]            arsize_m_inf;
output wire [1:0]            arburst_m_inf;
output reg                   arvalid_m_inf;
input wire                   arready_m_inf;

// axi read data channel
input wire [ID_WIDTH-1:0]    rid_m_inf;
input wire [DATA_WIDTH-1:0]  rdata_m_inf;
input wire [1:0]             rresp_m_inf;
input wire                   rlast_m_inf;
input wire                   rvalid_m_inf;
output wire                  rready_m_inf;

//========================================================
// Register and Wire Declaration
//========================================================
reg [1:0] next_state, current_state;
reg [1:0] op_reg;
reg [3:0] pic_no_reg;
reg [5:0] se_no_reg;
reg [1:0] handshake_count;
reg [8:0] addr_pic_count;
reg [8:0] start_op_count;
reg [1:0] pad_count;
reg [7:0] se_reg [15:0];
reg [127:0] pic_reg [15:0];
reg [8:0] result_reg [255:0];
reg [7:0] result_reg_2 [255:0];
reg [12:0] h_acc [255:0]; //histogram accumulation
reg [12:0] cdf_min;
reg [7:0] cdf_min_index;
//reg [127:0] h_result;
reg [20:0] h_mult [15:0];
reg [7:0] h_div [15:0];
wire [11:0] cdf_denominator;
reg [127:0] h_result1;
reg [127:0] h_result2;

//sram && dram
wire [127:0] q_pic;
reg wen_pic;
reg [7:0] addr_pic;
reg [127:0] d_pic;
reg wvalid_m_inf_reg;

//designware
wire min_max_control;
reg [127:0] a [15:0];
wire [7:0] value [15:0];
wire [3:0] index [15:0];

//========================================================
// Finite State Machine
//========================================================
//current state
always@ (posedge clk or negedge rst_n) begin
  if(!rst_n)
    current_state <= IDLE;
  else
    current_state <= next_state;
end

//next state combintional logic
always@ (*) begin
    case(current_state)
    IDLE: begin
        if(in_valid)
            next_state = READ_SE;
        else
            next_state = IDLE;
    end
    READ_SE: begin
        if(rlast_m_inf)
            next_state = READ_PIC;
        else
            next_state = READ_SE;
    end
    READ_PIC: begin
        if(addr_pic_count == 255 && op_reg != 2)
            next_state = WRITE_DRAM;
        else if(start_op_count == 256 && op_reg == 2)
            next_state = WRITE_DRAM;
        else
            next_state = READ_PIC;
    end
    WRITE_DRAM: begin
        if(bvalid_m_inf)
            next_state = IDLE;
        else
            next_state = WRITE_DRAM;
    end
    default: next_state = current_state;
    endcase
end

//========================================================
// Counter
//========================================================
//handshake_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        handshake_count <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            handshake_count <= 0;
        end
        else if(current_state == READ_SE) begin
            if(rlast_m_inf)
                handshake_count <= 0;
            else if(handshake_count <= 1)
                handshake_count <= handshake_count + 1;
            else
                handshake_count <= handshake_count;
        end
        else if(current_state == READ_PIC) begin
            if(handshake_count <= 1)
                handshake_count <= handshake_count + 1;
            else if(next_state == WRITE_DRAM)
                handshake_count <= 0;
            else
                handshake_count <= handshake_count;
        end
        else if(current_state == WRITE_DRAM) begin
            if(handshake_count <= 1)
                handshake_count <= handshake_count + 1;
            else
                handshake_count <= handshake_count;
        end
    end
end

//address count for pic
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_pic_count <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            addr_pic_count <= 0;
        end
        else if(current_state == READ_PIC && op_reg != 2) begin
            if(start_op_count < 16)
                addr_pic_count <= 0;
            else
                addr_pic_count <= addr_pic_count + 1;
        end
        else if(current_state == READ_PIC && op_reg == 2) begin
            if(addr_pic_count == 255)
                addr_pic_count <= 0;
            else if(rvalid_m_inf)
                addr_pic_count <= addr_pic_count + 1;

        end
        else if(current_state == WRITE_DRAM) begin

            addr_pic_count <= addr_pic_count + 1;

        end
    end
end

//start_op_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_op_count <= 0;
    end
    else begin
        if(current_state == READ_PIC) begin
            if(start_op_count == 256 && op_reg == 2)
                start_op_count <= 0;
            else if(rvalid_m_inf)
                start_op_count <= start_op_count + 1;
            else if(addr_pic_count == 255 && op_reg != 2)
                start_op_count <= 0;

            // else if(op_reg == 2 && start_op_count)
            //     start_op_count <= start_op_count + 1;
        end
        else if(current_state == WRITE_DRAM) begin
            if(wready_m_inf) begin
                start_op_count <= start_op_count + 1;
            end
        end
        else begin
            start_op_count <= 0;
        end

    end
end

//pad_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pad_count <= 0;
    end
    else begin
        if(current_state == READ_PIC && start_op_count > 15 && op_reg != 2) begin
            if(pad_count == 3) begin
                pad_count <= 0;
            end
            else begin
                pad_count <= pad_count + 1;
            end
        end
    end
end

//========================================================
// Input Block
//========================================================
//op
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        op_reg <= 0;
    end
    else begin
        if(in_valid && current_state == IDLE) begin
            op_reg <= op;
        end
        else begin
            op_reg <= op_reg;
        end
    end
end

//pic_no
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pic_no_reg <= 0;
    end
    else begin
        if(in_valid && current_state == IDLE) begin
            pic_no_reg <= pic_no;
        end
        else begin
            pic_no_reg <= pic_no_reg;
        end
    end
end

//se_no
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        se_no_reg <= 0;
    end
    else begin
        if(in_valid && current_state == IDLE) begin
            se_no_reg <= se_no;
        end
        else begin
            se_no_reg <= se_no_reg;
        end
    end
end

//se_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            se_reg[i] <= 0;
        end
    end
    else begin
        if(current_state == IDLE) begin
            for(i = 0; i < 16; i = i + 1) begin
                se_reg[i] <= 0;
            end
        end
        else if(current_state == READ_SE) begin
            for(i = 0; i < 16; i = i + 1) begin
                //se_reg[i] <= rdata_m_inf[i * 8 +: 8];
                se_reg[i] <= rdata_m_inf[127 - 8 * i -: 8];
            end
        end
        else begin
            for(i = 0; i < 16; i = i + 1) begin
                se_reg[i] <= se_reg[i];
            end
        end
    end

end

//pic_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            pic_reg[i] <= 0;
        end
    end
    else begin
        if(current_state == READ_SE) begin
            for(i = 0; i < 16; i = i + 1) begin
                pic_reg[i] <= 0;
            end
        end
        else if(current_state == READ_PIC) begin
            if(op_reg == 0 || op_reg == 1) begin //erosion and dilation
                pic_reg[15] <= rdata_m_inf;
                pic_reg[14] <= pic_reg[15];
                pic_reg[13] <= pic_reg[14];
                pic_reg[12] <= pic_reg[13];
                pic_reg[11] <= pic_reg[12];
                pic_reg[10] <= pic_reg[11];
                pic_reg[9] <= pic_reg[10];
                pic_reg[8] <= pic_reg[9];
                pic_reg[7] <= pic_reg[8];
                pic_reg[6] <= pic_reg[7];
                pic_reg[5] <= pic_reg[6];
                pic_reg[4] <= pic_reg[5];
                pic_reg[3] <= pic_reg[4];
                pic_reg[2] <= pic_reg[3];
                pic_reg[1] <= pic_reg[2];
                pic_reg[0] <= pic_reg[1];
            end
            else begin //no need for histogram
                for(i = 0; i < 16; i = i + 1) begin
                    pic_reg[i] <= 0;
                end
            end
        end
    end
end

//========================================================
// Output Logic
//========================================================
//busy
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        busy <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            busy <= 0;
        end
        else if(current_state == READ_SE && !in_valid) begin
            busy <= 1;
        end
    end
end

//========================================================
// DRAM Access
//========================================================
//******************************
// read data from DRAM
//******************************
assign arid_m_inf = 4'd0;
assign arlen_m_inf = (current_state == READ_SE) ? 8'd0 : 8'd255;
assign arsize_m_inf = 3'b100; //only support this burst size which means 16 bytes in each transfer
assign arburst_m_inf = 2'b1;
assign rready_m_inf = 1'b1;

//araddr_m_inf
always@ (*) begin
    if(current_state == READ_SE) begin
        araddr_m_inf = {16'h0003, 6'd0, se_no_reg , 4'h0};
    end
    else if(current_state == READ_PIC) begin
        araddr_m_inf = {16'h0004, pic_no_reg, 12'h000};
    end
    else begin
        araddr_m_inf = 32'h00030400;
    end
end

//arvalid_m_inf
always@ (*) begin
    if((current_state == READ_SE || current_state == READ_PIC) && handshake_count <= 1) begin
        arvalid_m_inf = 'd1;
    end
    else if(arready_m_inf) begin
        arvalid_m_inf = 'd0;
    end
    else begin
        arvalid_m_inf = 'd0;
    end
end

//******************************
// write data to DRAM
//******************************
assign awid_m_inf = 4'd0;
assign awlen_m_inf = 'd255;
assign awsize_m_inf = 3'b100;
assign awburst_m_inf = 2'b1;
assign bready_m_inf = 1'b1;
assign wlast_m_inf = (current_state == WRITE_DRAM && start_op_count == 255);
assign awaddr_m_inf = {16'h0004, pic_no_reg, 12'h000};
//assign wdata_m_inf = (op_reg == 2) ? h_result : q_pic;

always@ (*) begin
    if(current_state == WRITE_DRAM && op_reg == 2) begin
    //if(op_reg == 2) begin //histogram
        if(start_op_count == 0)
            wdata_m_inf = h_result1;
        else if(start_op_count == 1)
            wdata_m_inf = h_result2;
        else
            wdata_m_inf = {h_div[15], h_div[14], h_div[13], h_div[12], h_div[11], h_div[10], h_div[9], h_div[8], h_div[7], h_div[6], h_div[5], h_div[4], h_div[3], h_div[2], h_div[1], h_div[0]};
    end
    else begin //erosion && dilation
        wdata_m_inf = q_pic;
    end
end

//awvalid_m_inf
always@ (*) begin
    if(current_state == WRITE_DRAM && handshake_count <= 1) begin
        awvalid_m_inf = 'd1;
    end
    else if(awready_m_inf) begin
        awvalid_m_inf = 'd0;
    end
    else begin
        awvalid_m_inf = 'd0;
    end
end

//wvalid_m_inf
assign wvalid_m_inf = wvalid_m_inf_reg;
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wvalid_m_inf_reg <= 0;
    end
    else if(current_state == WRITE_DRAM && handshake_count <= 1) begin
        wvalid_m_inf_reg <= 'd0;
    end
    else if(current_state == WRITE_DRAM && awready_m_inf) begin
        wvalid_m_inf_reg <= 'd1;
    end
    else if(current_state == WRITE_DRAM && start_op_count <= 258 ) begin
        wvalid_m_inf_reg <= 'd1;
    end
    else begin
        wvalid_m_inf_reg <= 'd0;
    end
end

//========================================================
// SRAM Control
//========================================================
RA1SH_128_256 U_pic(.Q(q_pic), .CLK(clk), .CEN(1'b0), .WEN(wen_pic), .A(addr_pic), .D(d_pic), .OEN(1'b0));

//wen_pic
always@ (*) begin
    if(current_state == READ_PIC && start_op_count > 15 && op_reg != 2)
        wen_pic = 0;
    else if(current_state == READ_PIC && op_reg == 2 && start_op_count <= 255) //histogram
        wen_pic = 0;
    else
        wen_pic = 1;
end

//addr_pic
always@ (*) begin
    if(current_state == READ_PIC && start_op_count > 15 && op_reg != 2) begin
        addr_pic = addr_pic_count;
    end
    else if(current_state == READ_PIC && op_reg == 2) begin
        addr_pic = addr_pic_count;
    end
    else if(current_state == WRITE_DRAM && op_reg != 2) begin
        if(wready_m_inf)
            addr_pic = start_op_count + 1;
        else
            addr_pic = 0;
    end
    else if(current_state == WRITE_DRAM && op_reg == 2) begin
        if(addr_pic_count == 0)
            addr_pic = start_op_count;
        else if(addr_pic_count == 1)
            addr_pic = start_op_count + 1;
        else if(wready_m_inf)
            addr_pic = start_op_count + 3;
        else
            addr_pic = start_op_count + 2;
    end
    else begin
        addr_pic = addr_pic_count;
    end
end

//d_pic
always@ (*) begin
    if(op_reg == 0 || op_reg == 1) begin //erosion && dilation
        d_pic = {value[15], value[14], value[13], value[12], value[11], value[10], value[9], value[8], value[7], value[6], value[5], value[4], value[3], value[2], value[1], value[0]};
    end
    else begin //histogram
        d_pic = rdata_m_inf;
    end
end

//========================================================
// Designware
//========================================================
//comparator IP
DW_minmax #(width, num_inputs) M0(.a(a[0]), .tc(1'b0), .min_max(min_max_control), .value(value[0]), .index(index[0]));
DW_minmax #(width, num_inputs) M1(.a(a[1]), .tc(1'b0), .min_max(min_max_control), .value(value[1]), .index(index[1]));
DW_minmax #(width, num_inputs) M2(.a(a[2]), .tc(1'b0), .min_max(min_max_control), .value(value[2]), .index(index[2]));
DW_minmax #(width, num_inputs) M3(.a(a[3]), .tc(1'b0), .min_max(min_max_control), .value(value[3]), .index(index[3]));
DW_minmax #(width, num_inputs) M4(.a(a[4]), .tc(1'b0), .min_max(min_max_control), .value(value[4]), .index(index[4]));
DW_minmax #(width, num_inputs) M5(.a(a[5]), .tc(1'b0), .min_max(min_max_control), .value(value[5]), .index(index[5]));
DW_minmax #(width, num_inputs) M6(.a(a[6]), .tc(1'b0), .min_max(min_max_control), .value(value[6]), .index(index[6]));
DW_minmax #(width, num_inputs) M7(.a(a[7]), .tc(1'b0), .min_max(min_max_control), .value(value[7]), .index(index[7]));
DW_minmax #(width, num_inputs) M8(.a(a[8]), .tc(1'b0), .min_max(min_max_control), .value(value[8]), .index(index[8]));
DW_minmax #(width, num_inputs) M9(.a(a[9]), .tc(1'b0), .min_max(min_max_control), .value(value[9]), .index(index[9]));
DW_minmax #(width, num_inputs) M10(.a(a[10]), .tc(1'b0), .min_max(min_max_control), .value(value[10]), .index(index[10]));
DW_minmax #(width, num_inputs) M11(.a(a[11]), .tc(1'b0), .min_max(min_max_control), .value(value[11]), .index(index[11]));
DW_minmax #(width, num_inputs) M12(.a(a[12]), .tc(1'b0), .min_max(min_max_control), .value(value[12]), .index(index[12]));
DW_minmax #(width, num_inputs) M13(.a(a[13]), .tc(1'b0), .min_max(min_max_control), .value(value[13]), .index(index[13]));
DW_minmax #(width, num_inputs) M14(.a(a[14]), .tc(1'b0), .min_max(min_max_control), .value(value[14]), .index(index[14]));
DW_minmax #(width, num_inputs) M15(.a(a[15]), .tc(1'b0), .min_max(min_max_control), .value(value[15]), .index(index[15]));

//min_max
assign min_max_control = (op_reg == 1) ? 1 : 0;

//a
always@ (*) begin
    if(current_state == READ_PIC && start_op_count > 15 && op_reg != 2) begin
        for(i = 0; i < 16; i = i + 1) begin
            a[i] = {result_reg_2[0 + i * 16], result_reg_2[1 + i * 16], result_reg_2[2 + i * 16], result_reg_2[3 + i * 16], result_reg_2[4 + i * 16], result_reg_2[5 + i * 16], result_reg_2[6 + i * 16], result_reg_2[7 + i * 16], result_reg_2[8 + i * 16], result_reg_2[9 + i * 16], result_reg_2[10 + i* 16], result_reg_2[11 + i * 16], result_reg_2[12 + i * 16], result_reg_2[13 + i * 16], result_reg_2[14 + i * 16], result_reg_2[15 + i * 16]};
        end
    end
    else if(current_state == READ_PIC && op_reg == 2) begin
        a[0] = rdata_m_inf;
        for(i = 1; i < 16; i = i + 1) begin
            a[i] = 0;
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            a[i] = 0;
        end
    end
end

//cdf_min_index
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cdf_min_index <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            cdf_min_index <= 255;
        end
        else if(current_state == READ_PIC && op_reg == 2 /*&& rvalid_m_inf*/) begin
            // if(start_op_count == 0) begin
            //     cdf_min_index <= value[0];
            // end
            if(start_op_count && cdf_min_index > value[0]) begin
                cdf_min_index <= value[0];
            end
        end
        else begin
            cdf_min_index <= cdf_min_index;
        end
    end
end

//========================================================
// Calculation
//========================================================
//******************************
// erosion && dilation
//******************************
generate
    for(m = 0; m < 16; m = m + 1) begin
        if(m < 13) begin //no need to pad
            always@ (*) begin
                if(current_state == READ_PIC && start_op_count > 15) begin
                    if(op_reg == 0) begin //erosion
                        result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] - se_reg[15];
                        result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] - se_reg[14];
                        result_reg[2 + m * 16] = pic_reg[0][16 + m * 8 +: 8] - se_reg[13];
                        result_reg[3 + m * 16] = pic_reg[0][24 + m * 8 +: 8] - se_reg[12];
                        result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] - se_reg[11];
                        result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] - se_reg[10];
                        result_reg[6 + m * 16] = pic_reg[4][16 + m * 8 +: 8] - se_reg[9];
                        result_reg[7 + m * 16] = pic_reg[4][24 + m * 8 +: 8] - se_reg[8];
                        result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] - se_reg[7];
                        result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] - se_reg[6];
                        result_reg[10 + m * 16] = pic_reg[8][16 + m * 8 +: 8] - se_reg[5];
                        result_reg[11 + m * 16] = pic_reg[8][24 + m * 8 +: 8] - se_reg[4];
                        result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] - se_reg[3];
                        result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] - se_reg[2];
                        result_reg[14 + m * 16] = pic_reg[12][16 + m * 8 +: 8] - se_reg[1];
                        result_reg[15 + m * 16] = pic_reg[12][24 + m * 8 +: 8] - se_reg[0];
                    end
                    else if(op_reg == 1) begin //dilation
                        result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] + se_reg[0];
                        result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] + se_reg[1];
                        result_reg[2 + m * 16] = pic_reg[0][16 + m * 8 +: 8] + se_reg[2];
                        result_reg[3 + m * 16] = pic_reg[0][24 + m * 8 +: 8] + se_reg[3];
                        result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] + se_reg[4];
                        result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] + se_reg[5];
                        result_reg[6 + m * 16] = pic_reg[4][16 + m * 8 +: 8] + se_reg[6];
                        result_reg[7 + m * 16] = pic_reg[4][24 + m * 8 +: 8] + se_reg[7];
                        result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] + se_reg[8];
                        result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] + se_reg[9];
                        result_reg[10 + m * 16] = pic_reg[8][16 + m * 8 +: 8] + se_reg[10];
                        result_reg[11 + m * 16] = pic_reg[8][24 + m * 8 +: 8] + se_reg[11];
                        result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] + se_reg[12];
                        result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] + se_reg[13];
                        result_reg[14 + m * 16] = pic_reg[12][16 + m * 8 +: 8] + se_reg[14];
                        result_reg[15 + m * 16] = pic_reg[12][24 + m * 8 +: 8] + se_reg[15];
                    end
                    else begin
                        result_reg[0 + m * 16] = 0;
                        result_reg[1 + m * 16] = 0;
                        result_reg[2 + m * 16] = 0;
                        result_reg[3 + m * 16] = 0;
                        result_reg[4 + m * 16] = 0;
                        result_reg[5 + m * 16] = 0;
                        result_reg[6 + m * 16] = 0;
                        result_reg[7 + m * 16] = 0;
                        result_reg[8 + m * 16] = 0;
                        result_reg[9 + m * 16] = 0;
                        result_reg[10 + m * 16] = 0;
                        result_reg[11 + m * 16] = 0;
                        result_reg[12 + m * 16] = 0;
                        result_reg[13 + m * 16] = 0;
                        result_reg[14 + m * 16] = 0;
                        result_reg[15 + m * 16] = 0;
                    end
                end
                else begin
                    result_reg[0 + m * 16] = 0;
                    result_reg[1 + m * 16] = 0;
                    result_reg[2 + m * 16] = 0;
                    result_reg[3 + m * 16] = 0;
                    result_reg[4 + m * 16] = 0;
                    result_reg[5 + m * 16] = 0;
                    result_reg[6 + m * 16] = 0;
                    result_reg[7 + m * 16] = 0;
                    result_reg[8 + m * 16] = 0;
                    result_reg[9 + m * 16] = 0;
                    result_reg[10 + m * 16] = 0;
                    result_reg[11 + m * 16] = 0;
                    result_reg[12 + m * 16] = 0;
                    result_reg[13 + m * 16] = 0;
                    result_reg[14 + m * 16] = 0;
                    result_reg[15 + m * 16] = 0;
                end
            end
        end
        else if(m == 13) begin
            always@ (*) begin
                if(current_state == READ_PIC && start_op_count > 15) begin
                    if(pad_count == 3) begin //pad 1
                        if(op_reg == 0) begin
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] - se_reg[15];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] - se_reg[14];
                            result_reg[2 + m * 16] = pic_reg[0][16 + m * 8 +: 8] - se_reg[13];
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] - se_reg[11];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] - se_reg[10];
                            result_reg[6 + m * 16] = pic_reg[4][16 + m * 8 +: 8] - se_reg[9];
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] - se_reg[7];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] - se_reg[6];
                            result_reg[10 + m * 16] = pic_reg[8][16 + m * 8 +: 8] - se_reg[5];
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] - se_reg[3];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] - se_reg[2];
                            result_reg[14 + m * 16] = pic_reg[12][16 + m * 8 +: 8] - se_reg[1];
                            result_reg[15 + m * 16] = 0;
                        end
                        else if(op_reg == 1) begin
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] + se_reg[0];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] + se_reg[1];
                            result_reg[2 + m * 16] = pic_reg[0][16 + m * 8 +: 8] + se_reg[2];
                            result_reg[3 + m * 16] = se_reg[3];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] + se_reg[4];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] + se_reg[5];
                            result_reg[6 + m * 16] = pic_reg[4][16 + m * 8 +: 8] + se_reg[6];
                            result_reg[7 + m * 16] = se_reg[7];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] + se_reg[8];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] + se_reg[9];
                            result_reg[10 + m * 16] = pic_reg[8][16 + m * 8 +: 8] + se_reg[10];
                            result_reg[11 + m * 16] = se_reg[11];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] + se_reg[12];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] + se_reg[13];
                            result_reg[14 + m * 16] = pic_reg[12][16 + m * 8 +: 8] + se_reg[14];
                            result_reg[15 + m * 16] = se_reg[15];
                        end
                        else begin
                            result_reg[0 + m * 16] = 0;
                            result_reg[1 + m * 16] = 0;
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = 0;
                            result_reg[5 + m * 16] = 0;
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = 0;
                            result_reg[9 + m * 16] = 0;
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = 0;
                            result_reg[13 + m * 16] = 0;
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                    end
                    else begin //no need to pad
                        if(op_reg == 0) begin //erosion
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] - se_reg[15];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] - se_reg[14];
                            result_reg[2 + m * 16] = pic_reg[0][16 + m * 8 +: 8] - se_reg[13];
                            result_reg[3 + m * 16] = pic_reg[1][111 - m * 8 -: 8] - se_reg[12];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] - se_reg[11];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] - se_reg[10];
                            result_reg[6 + m * 16] = pic_reg[4][16 + m * 8 +: 8] - se_reg[9];
                            result_reg[7 + m * 16] = pic_reg[5][111 - m * 8 -: 8] - se_reg[8];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] - se_reg[7];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] - se_reg[6];
                            result_reg[10 + m * 16] = pic_reg[8][16 + m * 8 +: 8] - se_reg[5];
                            result_reg[11 + m * 16] = pic_reg[9][111 - m * 8 -: 8] - se_reg[4];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] - se_reg[3];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] - se_reg[2];
                            result_reg[14 + m * 16] = pic_reg[12][16 + m * 8 +: 8] - se_reg[1];
                            result_reg[15 + m * 16] = pic_reg[13][111 - m * 8 -: 8] - se_reg[0];
                        end
                        else if(op_reg == 1) begin //dilation
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] + se_reg[0];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] + se_reg[1];
                            result_reg[2 + m * 16] = pic_reg[0][16 + m * 8 +: 8] + se_reg[2];
                            result_reg[3 + m * 16] = pic_reg[1][111 - m * 8 -: 8] + se_reg[3];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] + se_reg[4];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] + se_reg[5];
                            result_reg[6 + m * 16] = pic_reg[4][16 + m * 8 +: 8] + se_reg[6];
                            result_reg[7 + m * 16] = pic_reg[5][111 - m * 8 -: 8] + se_reg[7];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] + se_reg[8];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] + se_reg[9];
                            result_reg[10 + m * 16] = pic_reg[8][16 + m * 8 +: 8] + se_reg[10];
                            result_reg[11 + m * 16] = pic_reg[9][111 - m * 8 -: 8] + se_reg[11];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] + se_reg[12];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] + se_reg[13];
                            result_reg[14 + m * 16] = pic_reg[12][16 + m * 8 +: 8] + se_reg[14];
                            result_reg[15 + m * 16] = pic_reg[13][111 - m * 8 -: 8] + se_reg[15];
                        end
                        else begin
                            result_reg[0 + m * 16] = 0;
                            result_reg[1 + m * 16] = 0;
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = 0;
                            result_reg[5 + m * 16] = 0;
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = 0;
                            result_reg[9 + m * 16] = 0;
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = 0;
                            result_reg[13 + m * 16] = 0;
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                    end
                end
                else begin
                    result_reg[0 + m * 16] = 0;
                    result_reg[1 + m * 16] = 0;
                    result_reg[2 + m * 16] = 0;
                    result_reg[3 + m * 16] = 0;
                    result_reg[4 + m * 16] = 0;
                    result_reg[5 + m * 16] = 0;
                    result_reg[6 + m * 16] = 0;
                    result_reg[7 + m * 16] = 0;
                    result_reg[8 + m * 16] = 0;
                    result_reg[9 + m * 16] = 0;
                    result_reg[10 + m * 16] = 0;
                    result_reg[11 + m * 16] = 0;
                    result_reg[12 + m * 16] = 0;
                    result_reg[13 + m * 16] = 0;
                    result_reg[14 + m * 16] = 0;
                    result_reg[15 + m * 16] = 0;
                end
            end
        end
        else if(m == 14) begin
            always@ (*) begin
                if(current_state == READ_PIC && start_op_count > 15) begin
                    if(pad_count == 3) begin //pad 2
                        if(op_reg == 0) begin
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] - se_reg[15];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] - se_reg[14];
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] - se_reg[11];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] - se_reg[10];
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] - se_reg[7];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] - se_reg[6];
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] - se_reg[3];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] - se_reg[2];
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                        else if(op_reg == 1) begin
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] + se_reg[0];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] + se_reg[1];
                            result_reg[2 + m * 16] = se_reg[2];
                            result_reg[3 + m * 16] = se_reg[3];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] + se_reg[4];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] + se_reg[5];
                            result_reg[6 + m * 16] = se_reg[6];
                            result_reg[7 + m * 16] = se_reg[7];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] + se_reg[8];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] + se_reg[9];
                            result_reg[10 + m * 16] = se_reg[10];
                            result_reg[11 + m * 16] = se_reg[11];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] + se_reg[12];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] + se_reg[13];
                            result_reg[14 + m * 16] = se_reg[14];
                            result_reg[15 + m * 16] = se_reg[15];
                        end
                        else begin
                            result_reg[0 + m * 16] = 0;
                            result_reg[1 + m * 16] = 0;
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = 0;
                            result_reg[5 + m * 16] = 0;
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = 0;
                            result_reg[9 + m * 16] = 0;
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = 0;
                            result_reg[13 + m * 16] = 0;
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                    end
                    else begin //no need to pad
                        if(op_reg == 0) begin //erosion
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] - se_reg[15];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] - se_reg[14];
                            result_reg[2 + m * 16] = pic_reg[1][119 - m * 8 -: 8] - se_reg[13];
                            result_reg[3 + m * 16] = pic_reg[1][127 - m * 8 -: 8] - se_reg[12];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] - se_reg[11];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] - se_reg[10];
                            result_reg[6 + m * 16] = pic_reg[5][119 - m * 8 -: 8] - se_reg[9];
                            result_reg[7 + m * 16] = pic_reg[5][127 - m * 8 -: 8] - se_reg[8];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] - se_reg[7];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] - se_reg[6];
                            result_reg[10 + m * 16] = pic_reg[9][119 - m * 8 -: 8] - se_reg[5];
                            result_reg[11 + m * 16] = pic_reg[9][127 - m * 8 -: 8] - se_reg[4];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] - se_reg[3];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] - se_reg[2];
                            result_reg[14 + m * 16] = pic_reg[13][119 - m * 8 -: 8] - se_reg[1];
                            result_reg[15 + m * 16] = pic_reg[13][127 - m * 8 -: 8] - se_reg[0];
                        end
                        else if(op_reg == 1) begin //dilation
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] + se_reg[0];
                            result_reg[1 + m * 16] = pic_reg[0][8 + m * 8 +: 8] + se_reg[1];
                            result_reg[2 + m * 16] = pic_reg[1][119 - m * 8 -: 8] + se_reg[2];
                            result_reg[3 + m * 16] = pic_reg[1][127 - m * 8 -: 8] + se_reg[3];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] + se_reg[4];
                            result_reg[5 + m * 16] = pic_reg[4][8 + m * 8 +: 8] + se_reg[5];
                            result_reg[6 + m * 16] = pic_reg[5][119 - m * 8 -: 8] + se_reg[6];
                            result_reg[7 + m * 16] = pic_reg[5][127 - m * 8 -: 8] + se_reg[7];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] + se_reg[8];
                            result_reg[9 + m * 16] = pic_reg[8][8 + m * 8 +: 8] + se_reg[9];
                            result_reg[10 + m * 16] = pic_reg[9][119 - m * 8 -: 8] + se_reg[10];
                            result_reg[11 + m * 16] = pic_reg[9][127 - m * 8 -: 8] + se_reg[11];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] + se_reg[12];
                            result_reg[13 + m * 16] = pic_reg[12][8 + m * 8 +: 8] + se_reg[13];
                            result_reg[14 + m * 16] = pic_reg[13][119 - m * 8 -: 8] + se_reg[14];
                            result_reg[15 + m * 16] = pic_reg[13][127 - m * 8 -: 8] + se_reg[15];
                        end
                        else begin
                            result_reg[0 + m * 16] = 0;
                            result_reg[1 + m * 16] = 0;
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = 0;
                            result_reg[5 + m * 16] = 0;
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = 0;
                            result_reg[9 + m * 16] = 0;
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = 0;
                            result_reg[13 + m * 16] = 0;
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                    end
                end
                else begin
                    result_reg[0 + m * 16] = 0;
                    result_reg[1 + m * 16] = 0;
                    result_reg[2 + m * 16] = 0;
                    result_reg[3 + m * 16] = 0;
                    result_reg[4 + m * 16] = 0;
                    result_reg[5 + m * 16] = 0;
                    result_reg[6 + m * 16] = 0;
                    result_reg[7 + m * 16] = 0;
                    result_reg[8 + m * 16] = 0;
                    result_reg[9 + m * 16] = 0;
                    result_reg[10 + m * 16] = 0;
                    result_reg[11 + m * 16] = 0;
                    result_reg[12 + m * 16] = 0;
                    result_reg[13 + m * 16] = 0;
                    result_reg[14 + m * 16] = 0;
                    result_reg[15 + m * 16] = 0;
                end
            end
        end
        else begin //m == 15
            always@ (*) begin
                if(current_state == READ_PIC && start_op_count > 15) begin
                    if(pad_count == 3) begin //pad 3
                        if(op_reg == 0) begin
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] - se_reg[15];
                            result_reg[1 + m * 16] = 0;
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] - se_reg[11];
                            result_reg[5 + m * 16] = 0;
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] - se_reg[7];
                            result_reg[9 + m * 16] = 0;
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] - se_reg[3];
                            result_reg[13 + m * 16] = 0;
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                        else if(op_reg == 1) begin
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] + se_reg[0];
                            result_reg[1 + m * 16] = se_reg[1];
                            result_reg[2 + m * 16] = se_reg[2];
                            result_reg[3 + m * 16] = se_reg[3];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] + se_reg[4];
                            result_reg[5 + m * 16] = se_reg[5];
                            result_reg[6 + m * 16] = se_reg[6];
                            result_reg[7 + m * 16] = se_reg[7];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] + se_reg[8];
                            result_reg[9 + m * 16] = se_reg[9];
                            result_reg[10 + m * 16] = se_reg[10];
                            result_reg[11 + m * 16] = se_reg[11];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] + se_reg[12];
                            result_reg[13 + m * 16] = se_reg[13];
                            result_reg[14 + m * 16] = se_reg[14];
                            result_reg[15 + m * 16] = se_reg[15];
                        end
                        else begin
                            result_reg[0 + m * 16] = 0;
                            result_reg[1 + m * 16] = 0;
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = 0;
                            result_reg[5 + m * 16] = 0;
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = 0;
                            result_reg[9 + m * 16] = 0;
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = 0;
                            result_reg[13 + m * 16] = 0;
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                    end
                    else begin // no need to pad
                        if(op_reg == 0) begin //erosion
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] - se_reg[15];
                            result_reg[1 + m * 16] = pic_reg[1][127 - m * 8 -: 8] - se_reg[14];
                            result_reg[2 + m * 16] = pic_reg[1][135 - m * 8 -: 8] - se_reg[13];
                            result_reg[3 + m * 16] = pic_reg[1][143 - m * 8 -: 8] - se_reg[12];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] - se_reg[11];
                            result_reg[5 + m * 16] = pic_reg[5][127 - m * 8 -: 8] - se_reg[10];
                            result_reg[6 + m * 16] = pic_reg[5][135 - m * 8 -: 8] - se_reg[9];
                            result_reg[7 + m * 16] = pic_reg[5][143 - m * 8 -: 8] - se_reg[8];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] - se_reg[7];
                            result_reg[9 + m * 16] = pic_reg[9][127 - m * 8 -: 8] - se_reg[6];
                            result_reg[10 + m * 16] = pic_reg[9][135 - m * 8 -: 8] - se_reg[5];
                            result_reg[11 + m * 16] = pic_reg[9][143 - m * 8 -: 8] - se_reg[4];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] - se_reg[3];
                            result_reg[13 + m * 16] = pic_reg[13][127 - m * 8 -: 8] - se_reg[2];
                            result_reg[14 + m * 16] = pic_reg[13][135 - m * 8 -: 8] - se_reg[1];
                            result_reg[15 + m * 16] = pic_reg[13][143 - m * 8 -: 8] - se_reg[0];
                        end
                        else if(op_reg == 1) begin //dilation
                            result_reg[0 + m * 16] = pic_reg[0][0 + m * 8 +: 8] + se_reg[0];
                            result_reg[1 + m * 16] = pic_reg[1][127 - m * 8 -: 8] + se_reg[1];
                            result_reg[2 + m * 16] = pic_reg[1][135 - m * 8 -: 8] + se_reg[2];
                            result_reg[3 + m * 16] = pic_reg[1][143 - m * 8 -: 8] + se_reg[3];
                            result_reg[4 + m * 16] = pic_reg[4][0 + m * 8 +: 8] + se_reg[4];
                            result_reg[5 + m * 16] = pic_reg[5][127 - m * 8 -: 8] + se_reg[5];
                            result_reg[6 + m * 16] = pic_reg[5][135 - m * 8 -: 8] + se_reg[6];
                            result_reg[7 + m * 16] = pic_reg[5][143 - m * 8 -: 8] + se_reg[7];
                            result_reg[8 + m * 16] = pic_reg[8][0 + m * 8 +: 8] + se_reg[8];
                            result_reg[9 + m * 16] = pic_reg[9][127 - m * 8 -: 8] + se_reg[9];
                            result_reg[10 + m * 16] = pic_reg[9][135 - m * 8 -: 8] + se_reg[10];
                            result_reg[11 + m * 16] = pic_reg[9][143 - m * 8 -: 8] + se_reg[11];
                            result_reg[12 + m * 16] = pic_reg[12][0 + m * 8 +: 8] + se_reg[12];
                            result_reg[13 + m * 16] = pic_reg[13][127 - m * 8 -: 8] + se_reg[13];
                            result_reg[14 + m * 16] = pic_reg[13][135 - m * 8 -: 8] + se_reg[14];
                            result_reg[15 + m * 16] = pic_reg[13][143 - m * 8 -: 8] + se_reg[15];
                        end
                        else begin
                            result_reg[0 + m * 16] = 0;
                            result_reg[1 + m * 16] = 0;
                            result_reg[2 + m * 16] = 0;
                            result_reg[3 + m * 16] = 0;
                            result_reg[4 + m * 16] = 0;
                            result_reg[5 + m * 16] = 0;
                            result_reg[6 + m * 16] = 0;
                            result_reg[7 + m * 16] = 0;
                            result_reg[8 + m * 16] = 0;
                            result_reg[9 + m * 16] = 0;
                            result_reg[10 + m * 16] = 0;
                            result_reg[11 + m * 16] = 0;
                            result_reg[12 + m * 16] = 0;
                            result_reg[13 + m * 16] = 0;
                            result_reg[14 + m * 16] = 0;
                            result_reg[15 + m * 16] = 0;
                        end
                    end
                end
                else begin
                    result_reg[0 + m * 16] = 0;
                    result_reg[1 + m * 16] = 0;
                    result_reg[2 + m * 16] = 0;
                    result_reg[3 + m * 16] = 0;
                    result_reg[4 + m * 16] = 0;
                    result_reg[5 + m * 16] = 0;
                    result_reg[6 + m * 16] = 0;
                    result_reg[7 + m * 16] = 0;
                    result_reg[8 + m * 16] = 0;
                    result_reg[9 + m * 16] = 0;
                    result_reg[10 + m * 16] = 0;
                    result_reg[11 + m * 16] = 0;
                    result_reg[12 + m * 16] = 0;
                    result_reg[13 + m * 16] = 0;
                    result_reg[14 + m * 16] = 0;
                    result_reg[15 + m * 16] = 0;
                end
            end
        end
    end
endgenerate

//avoid overflow
generate
    for(m = 0; m < 16; m = m + 1) begin
        always@ (*) begin
            if(current_state == READ_PIC && start_op_count > 15) begin
                if(op_reg == 0) begin
                    result_reg_2[0 + m * 16] = (result_reg[0 + m * 16][8] == 1) ? 0 : result_reg[0 + m * 16];
                    result_reg_2[1 + m * 16] = (result_reg[1 + m * 16][8] == 1) ? 0 : result_reg[1 + m * 16];
                    result_reg_2[2 + m * 16] = (result_reg[2 + m * 16][8] == 1) ? 0 : result_reg[2 + m * 16];
                    result_reg_2[3 + m * 16] = (result_reg[3 + m * 16][8] == 1) ? 0 : result_reg[3 + m * 16];
                    result_reg_2[4 + m * 16] = (result_reg[4 + m * 16][8] == 1) ? 0 : result_reg[4 + m * 16];
                    result_reg_2[5 + m * 16] = (result_reg[5 + m * 16][8] == 1) ? 0 : result_reg[5 + m * 16];
                    result_reg_2[6 + m * 16] = (result_reg[6 + m * 16][8] == 1) ? 0 : result_reg[6 + m * 16];
                    result_reg_2[7 + m * 16] = (result_reg[7 + m * 16][8] == 1) ? 0 : result_reg[7 + m * 16];
                    result_reg_2[8 + m * 16] = (result_reg[8 + m * 16][8] == 1) ? 0 : result_reg[8 + m * 16];
                    result_reg_2[9 + m * 16] = (result_reg[9 + m * 16][8] == 1) ? 0 : result_reg[9 + m * 16];
                    result_reg_2[10 + m * 16] = (result_reg[10 + m * 16][8] == 1) ? 0 : result_reg[10 + m * 16];
                    result_reg_2[11 + m * 16] = (result_reg[11 + m * 16][8] == 1) ? 0 : result_reg[11 + m * 16];
                    result_reg_2[12 + m * 16] = (result_reg[12 + m * 16][8] == 1) ? 0 : result_reg[12 + m * 16];
                    result_reg_2[13 + m * 16] = (result_reg[13 + m * 16][8] == 1) ? 0 : result_reg[13 + m * 16];
                    result_reg_2[14 + m * 16] = (result_reg[14 + m * 16][8] == 1) ? 0 : result_reg[14 + m * 16];
                    result_reg_2[15 + m * 16] = (result_reg[15 + m * 16][8] == 1) ? 0 : result_reg[15 + m * 16];
                end
                else if(op_reg == 1) begin
                    result_reg_2[0 + m * 16] = (result_reg[0 + m * 16][8] == 1) ? 255: result_reg[0 + m * 16];
                    result_reg_2[1 + m * 16] = (result_reg[1 + m * 16][8] == 1) ? 255: result_reg[1 + m * 16];
                    result_reg_2[2 + m * 16] = (result_reg[2 + m * 16][8] == 1) ? 255: result_reg[2 + m * 16];
                    result_reg_2[3 + m * 16] = (result_reg[3 + m * 16][8] == 1) ? 255: result_reg[3 + m * 16];
                    result_reg_2[4 + m * 16] = (result_reg[4 + m * 16][8] == 1) ? 255: result_reg[4 + m * 16];
                    result_reg_2[5 + m * 16] = (result_reg[5 + m * 16][8] == 1) ? 255: result_reg[5 + m * 16];
                    result_reg_2[6 + m * 16] = (result_reg[6 + m * 16][8] == 1) ? 255: result_reg[6 + m * 16];
                    result_reg_2[7 + m * 16] = (result_reg[7 + m * 16][8] == 1) ? 255: result_reg[7 + m * 16];
                    result_reg_2[8 + m * 16] = (result_reg[8 + m * 16][8] == 1) ? 255: result_reg[8 + m * 16];
                    result_reg_2[9 + m * 16] = (result_reg[9 + m * 16][8] == 1) ? 255: result_reg[9 + m * 16];
                    result_reg_2[10 + m * 16] = (result_reg[10 + m * 16][8] == 1) ? 255: result_reg[10 + m * 16];
                    result_reg_2[11 + m * 16] = (result_reg[11 + m * 16][8] == 1) ? 255: result_reg[11 + m * 16];
                    result_reg_2[12 + m * 16] = (result_reg[12 + m * 16][8] == 1) ? 255: result_reg[12 + m * 16];
                    result_reg_2[13 + m * 16] = (result_reg[13 + m * 16][8] == 1) ? 255: result_reg[13 + m * 16];
                    result_reg_2[14 + m * 16] = (result_reg[14 + m * 16][8] == 1) ? 255: result_reg[14 + m * 16];
                    result_reg_2[15 + m * 16] = (result_reg[15 + m * 16][8] == 1) ? 255: result_reg[15 + m * 16];
                end
                else begin
                    result_reg_2[0 + m * 16] = 0;
                    result_reg_2[1 + m * 16] = 0;
                    result_reg_2[2 + m * 16] = 0;
                    result_reg_2[3 + m * 16] = 0;
                    result_reg_2[4 + m * 16] = 0;
                    result_reg_2[5 + m * 16] = 0;
                    result_reg_2[6 + m * 16] = 0;
                    result_reg_2[7 + m * 16] = 0;
                    result_reg_2[8 + m * 16] = 0;
                    result_reg_2[9 + m * 16] = 0;
                    result_reg_2[10 + m * 16] = 0;
                    result_reg_2[11 + m * 16] = 0;
                    result_reg_2[12 + m * 16] = 0;
                    result_reg_2[13 + m * 16] = 0;
                    result_reg_2[14 + m * 16] = 0;
                    result_reg_2[15 + m * 16] = 0;
                end
            end
            else begin
                result_reg_2[0 + m * 16] = 0;
                result_reg_2[1 + m * 16] = 0;
                result_reg_2[2 + m * 16] = 0;
                result_reg_2[3 + m * 16] = 0;
                result_reg_2[4 + m * 16] = 0;
                result_reg_2[5 + m * 16] = 0;
                result_reg_2[6 + m * 16] = 0;
                result_reg_2[7 + m * 16] = 0;
                result_reg_2[8 + m * 16] = 0;
                result_reg_2[9 + m * 16] = 0;
                result_reg_2[10 + m * 16] = 0;
                result_reg_2[11 + m * 16] = 0;
                result_reg_2[12 + m * 16] = 0;
                result_reg_2[13 + m * 16] = 0;
                result_reg_2[14 + m * 16] = 0;
                result_reg_2[15 + m * 16] = 0;
            end
        end
    end

endgenerate

//******************************
// histogram
//******************************
//compute cdf
generate
for(m = 0; m < 256; m = m + 1) begin
    always@ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            h_acc[m] = 0;
        end
        else begin
            if(current_state == IDLE) begin
                h_acc[m] = 0;
            end
            else if(current_state == READ_PIC && op_reg == 2 && rvalid_m_inf) begin //compute cdf
                if(rdata_m_inf[127:120] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[119:112] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[111:104] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[103:96] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[95:88] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[87:80] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[79:72] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[71:64] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[63:56] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[55:48] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[47:40] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[39:32] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[31:24] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[23:16] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[15:8] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
                if(rdata_m_inf[7:0] <= m) begin
                    h_acc[m] = h_acc[m] + 1;
                end
                else begin
                    h_acc[m] = h_acc[m];
                end
            end
            // else if(current_state == READ_PIC && op_reg == 2 && start_op_count == 257) begin //cdf table
            //     h_acc[m] = (h_acc[m] > 0) ? ((h_acc[m] - cdf_min) * 255) / (cdf_max - cdf_min) : 0;
            // end
        end
    end
end
endgenerate

//cdf_min
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cdf_min <= 0;
    end
    else begin
        if(current_state == READ_PIC && op_reg == 2 && start_op_count == 256) begin
            cdf_min <= h_acc[cdf_min_index];
        end
        else if(current_state == WRITE_DRAM && op_reg == 2) begin
            cdf_min <= cdf_min;
        end
    end
end

//h_mult
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            h_mult[i] <= 0;
        end
    end
    else begin
        if(current_state == IDLE) begin
            for(i = 0; i < 16; i = i + 1) begin
                h_mult[i] <= 0;
            end
        end
        else if(current_state == WRITE_DRAM && op_reg == 2) begin
            if(addr_pic_count > 0) begin
                h_mult[15] <= ((h_acc[q_pic[127:120]] - cdf_min) * 255);
                h_mult[14] <= ((h_acc[q_pic[119:112]] - cdf_min) * 255);
                h_mult[13] <= ((h_acc[q_pic[111:104]] - cdf_min) * 255);
                h_mult[12] <= ((h_acc[q_pic[103:96]] - cdf_min) * 255);
                h_mult[11] <= ((h_acc[q_pic[95:88]] - cdf_min) * 255);
                h_mult[10] <= ((h_acc[q_pic[87:80]] - cdf_min) * 255);
                h_mult[9] <= ((h_acc[q_pic[79:72]] - cdf_min) * 255);
                h_mult[8] <= ((h_acc[q_pic[71:64]] - cdf_min) * 255);
                h_mult[7] <= ((h_acc[q_pic[63:56]] - cdf_min) * 255);
                h_mult[6] <= ((h_acc[q_pic[55:48]] - cdf_min) * 255);
                h_mult[5] <= ((h_acc[q_pic[47:40]] - cdf_min) * 255);
                h_mult[4] <= ((h_acc[q_pic[39:32]] - cdf_min) * 255);
                h_mult[3] <= ((h_acc[q_pic[31:24]] - cdf_min) * 255);
                h_mult[2] <= ((h_acc[q_pic[23:16]] - cdf_min) * 255);
                h_mult[1] <= ((h_acc[q_pic[15:8]] - cdf_min) * 255);
                h_mult[0] <= ((h_acc[q_pic[7:0]] - cdf_min) * 255);
            end
        end
    end
end

assign cdf_denominator = cdf_max - cdf_min;

//h_div
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            h_div[i] <= 0;
        end
    end
    else begin
        if(current_state == IDLE) begin
            for(i = 0; i < 16; i = i + 1) begin
                h_div[i] <= 0;
            end
        end
        else if(current_state == WRITE_DRAM && op_reg == 2) begin
            for(i = 0; i < 16; i = i + 1) begin
                h_div[i] <= h_mult[i] / cdf_denominator;
            end
        end
    end
end

//first output
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        h_result1 <= 0;
    end
    else begin
        if(current_state == WRITE_DRAM && op_reg == 2) begin
            if(addr_pic_count == 3) begin
                h_result1 <= {h_div[15], h_div[14], h_div[13], h_div[12], h_div[11], h_div[10], h_div[9], h_div[8], h_div[7], h_div[6], h_div[5], h_div[4], h_div[3], h_div[2], h_div[1], h_div[0]};
            end
        end
        else begin
            h_result1 <= 0;
        end
    end
end

//second output
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        h_result2 <= 0;
    end
    else begin
        if(current_state == WRITE_DRAM && op_reg == 2) begin
            if(addr_pic_count == 4) begin
                h_result2 <= {h_div[15], h_div[14], h_div[13], h_div[12], h_div[11], h_div[10], h_div[9], h_div[8], h_div[7], h_div[6], h_div[5], h_div[4], h_div[3], h_div[2], h_div[1], h_div[0]};
            end
        end
        else begin
            h_result2 <= 0;
        end
    end
end

//output rest of them
// always@ (*) begin
//     if(current_state == WRITE_DRAM && op_reg == 2) begin
//         h_result = {h_div[15], h_div[14], h_div[13], h_div[12], h_div[11], h_div[10], h_div[9], h_div[8], h_div[7], h_div[6], h_div[5], h_div[4], h_div[3], h_div[2], h_div[1], h_div[0]};
//     end
//     else begin
//         h_result = 0;
//     end
// end

endmodule

// h_result[127:120] = h_acc[q_pic[127:120]];
//             h_result[119:112] = h_acc[q_pic[119:112]];
//             h_result[111:104] = h_acc[q_pic[111:104]];
//             h_result[103:96] = h_acc[q_pic[103:96]];
//             h_result[95:88] = h_acc[q_pic[95:88]];
//             h_result[87:80] = h_acc[q_pic[87:80]];
//             h_result[79:72] = h_acc[q_pic[79:72]];
//             h_result[71:64] = h_acc[q_pic[71:64]];
//             h_result[63:56] = h_acc[q_pic[63:56]];
//             h_result[55:48] = h_acc[q_pic[55:48]];
//             h_result[47:40] = h_acc[q_pic[47:40]];
//             h_result[39:32] = h_acc[q_pic[39:32]];
//             h_result[31:24] = h_acc[q_pic[31:24]];
//             h_result[23:16] = h_acc[q_pic[23:16]];
//             h_result[15:8] = h_acc[q_pic[15:8]];
//             h_result[7:0] = h_acc[q_pic[7:0]];

//histogram result
// always@ (*) begin
//     if(current_state == WRITE_DRAM && op_reg == 2) begin
//         h_result[127:120] = ((h_acc[q_pic[127:120]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[119:112] = ((h_acc[q_pic[119:112]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[111:104] = ((h_acc[q_pic[111:104]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[103:96] = ((h_acc[q_pic[103:96]]  - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[95:88] = ((h_acc[q_pic[95:88]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[87:80] = ((h_acc[q_pic[87:80]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[79:72] = ((h_acc[q_pic[79:72]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[71:64] = ((h_acc[q_pic[71:64]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[63:56] = ((h_acc[q_pic[63:56]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[55:48] = ((h_acc[q_pic[55:48]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[47:40] = ((h_acc[q_pic[47:40]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[39:32] = ((h_acc[q_pic[39:32]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[31:24] = ((h_acc[q_pic[31:24]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[23:16] = ((h_acc[q_pic[23:16]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[15:8] = ((h_acc[q_pic[15:8]] - cdf_min) * 255) / (cdf_max - cdf_min);
//         h_result[7:0] = ((h_acc[q_pic[7:0]] - cdf_min) * 255) / (cdf_max - cdf_min);
//     end
//     else begin
//         h_result = 0;
//     end
// end