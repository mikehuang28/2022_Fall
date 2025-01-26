//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : B2BCD_IP.v
//   Module Name : B2BCD_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module B2BCD_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   Binary_code;
output [DIGIT*4-1:0] BCD_code;

/*
(4,2) (8,3) (12,4) (16,5) (20,7)
*/

parameter W = WIDTH - 3;
parameter D = DIGIT * 4;
genvar i, j;
integer m;

// ===============================================================
// Soft IP DESIGN
// ===============================================================


wire [D-1:0] Binary_code_temp;
assign Binary_code_temp = {{(D - WIDTH){1'b0}}, Binary_code};
assign BCD_code = loop_i[W - 1].BCD_temp;

reg [D-1:0] result;

generate

for(i = 0; i < W; i = i + 1) begin: loop_i
    reg [3:0] result [0:5];
    reg [D-1:0] BCD_temp;
    //if(i == 0) begin
    case(i)
    0: begin
        for(j = 0; j <= i / 3; j = j + 1) begin
            always@ (*) begin
                case(Binary_code_temp[WIDTH - i + j * 4 -: 4])
                0: result[j] = 0;
                1: result[j] = 1;
                2: result[j] = 2;
                3: result[j] = 3;
                4: result[j] = 4;
                5: result[j] = 8;
                6: result[j] = 9;
                7: result[j] = 10;
                8: result[j] = 11;
                9: result[j] = 12;
                default: result[j] = 0;
                endcase
            end
        end
    end
    //else begin //i != 0
    default: begin //i != 0
        for(j = 0; j <= i / 3; j = j + 1) begin
            always@ (*) begin
                case(loop_i[i - 1].BCD_temp[WIDTH - i + j * 4 -: 4])
                0: result[j] = 0;
                1: result[j] = 1;
                2: result[j] = 2;
                3: result[j] = 3;
                4: result[j] = 4;
                5: result[j] = 8;
                6: result[j] = 9;
                7: result[j] = 10;
                8: result[j] = 11;
                9: result[j] = 12;
                default: result[j] = 0;
                endcase
            end
        end
    end
    endcase



    //if(i == 0) begin
    case(i)
    0: begin
        always@ (*) begin
            BCD_temp = Binary_code_temp;
            for(m = 0; m <= i / 3; m = m + 1) begin
                BCD_temp[WIDTH - i + m * 4 -: 4] = result[m];
            end
        end
    end
    //else begin //i != 0
    default: begin
        always@ (*) begin
            BCD_temp = loop_i[i - 1].BCD_temp;
            for(m = 0; m <= i / 3; m = m + 1) begin
                BCD_temp[WIDTH - i + m * 4 -: 4] = result[m];
            end
        end
    end
    endcase
end

endgenerate







endmodule

module handle_binary(Binary_temp, BCD);
parameter WIDTH = 4;
parameter DIGIT = 2;
input [DIGIT * 4-1:0] Binary_temp;
output [DIGIT * 4-1:0] BCD;
reg [DIGIT * 4-1:0] BCD;
integer k;

always@ (*) begin
    BCD = 0;
    for (k = 0; k < WIDTH; k = k + 1) begin
        case(WIDTH)
        0, 1, 2, 3, 4: begin
            if (BCD[3:0] >= 5) BCD[3:0] = BCD[3:0] + 3;
            if (BCD[7:4] >= 5) BCD[7:4] = BCD[7:4] + 3;
            BCD = {BCD[DIGIT*4-2:0], Binary_temp[WIDTH - 1 - k]};	//Shift one bit, and shift in proper bit from input
        end
        5, 6, 7, 8: begin
            if (BCD[3:0] >= 5) BCD[3:0] = BCD[3:0] + 3;
            if (BCD[7:4] >= 5) BCD[7:4] = BCD[7:4] + 3;

            BCD = {BCD[DIGIT*4-2:0], Binary_temp[WIDTH - 1 - k]};	//Shift one bit, and shift in proper bit from input
        end
        9, 10, 11, 12: begin
            if (BCD[3:0] >= 5) BCD[3:0] = BCD[3:0] + 3;
            if (BCD[7:4] >= 5) BCD[7:4] = BCD[7:4] + 3;

            BCD = {BCD[DIGIT*4-2:0], Binary_temp[WIDTH - 1 - k]};	//Shift one bit, and shift in proper bit from input
        end
        13, 14, 15, 16: begin
            if (BCD[3:0] >= 5) BCD[3:0] = BCD[3:0] + 3;
            if (BCD[7:4] >= 5) BCD[7:4] = BCD[7:4] + 3;

            BCD = {BCD[DIGIT*4-2:0], Binary_temp[WIDTH - 1 - k]};	//Shift one bit, and shift in proper bit from input
        end
        17, 18, 19, 20: begin
            if (BCD[3:0] >= 5) BCD[3:0] = BCD[3:0] + 3;
            if (BCD[7:4] >= 5) BCD[7:4] = BCD[7:4] + 3;

            BCD = {BCD[DIGIT*4-2:0], Binary_temp[WIDTH - 1 - k]};	//Shift one bit, and shift in proper bit from input
        end
        // default: begin
        //     if (BCD[3:0] >= 5) BCD[3:0] = BCD[3:0] + 3;
        //     if (BCD[7:4] >= 5) BCD[7:4] = BCD[7:4] + 3;
        //     if (BCD[11:8] >= 5) BCD[11:8] = BCD[11:8] + 3;
        //     if (BCD[15:12] >= 5) BCD[15:12] = BCD[15:12] + 3;
        //     if (BCD[19:16] >= 5) BCD[19:16] = BCD[19:16] + 3;
        //     if (BCD[23:20] >= 5) BCD[23:20] = BCD[23:20] + 3;
        //     BCD = {BCD[DIGIT*4-2:0], Binary_temp[WIDTH - 1 - m]};	//Shift one bit, and shift in proper bit from input
        // end
        endcase

        //BCD = {BCD[DIGIT*4-2:0], Binary_temp[WIDTH - 1 - m]};	//Shift one bit, and shift in proper bit from input
    end
end



endmodule




















