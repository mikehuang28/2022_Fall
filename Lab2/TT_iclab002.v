module TT(
    //Input Port
    clk,
    rst_n,
	in_valid,
    source,
    destination,

    //Output Port
    out_valid,
    cost
    );

input               clk, rst_n, in_valid;
input       [3:0]   source;
input       [3:0]   destination;

output reg          out_valid;
output reg  [3:0]   cost;

//==============================================//
//             Parameter and Integer            //
//==============================================//

parameter IDLE = 0;
parameter INPUT = 1;
parameter CAL = 2;
//parameter OUTPUT = 3;

integer i, j;
//genvar k, l, m;
//==============================================//
//            FSM State Declaration             //
//==============================================//

reg [1:0] current_state, next_state;
wire find_answer; //make it successfully
wire no_path; //cannot make it to the destination
reg empty; //no stations at all

//==============================================//
//                 reg declaration              //
//==============================================//

reg [3:0] source_reg;
reg [3:0] destination_reg;
reg adj_matrix [0:15][0:15];
reg s_vector [0:15];
//reg s_vector_temp [0:15];

reg [7:0] in_valid_count;
//reg [3:0] cal_count;
reg [3:0] cost_count;

//==============================================//
//             Current State Block              //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE; /* initial state */
    else
        current_state <= next_state;
end

//==============================================//
//              Next State Block                //
//==============================================//
always@(*) begin
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
            if(find_answer || no_path || empty)
                next_state = IDLE;
            else
                next_state = CAL;
        end
        default: next_state = IDLE;
    endcase
end

//==============================================//
//                  Input Block                 //
//==============================================//

//in_valid_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid_count <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            in_valid_count <= 0;
        end
        else if(current_state == INPUT && in_valid) begin
            in_valid_count <= in_valid_count + 1;
        end
        else begin
            in_valid_count <= 0;
        end
    end
end

//source
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        source_reg <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            source_reg <= source;
        end
        else if(current_state == CAL) begin
            source_reg <= 0;
        end
        else begin
            source_reg <= 0;
        end
    end
end

//destination
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        destination_reg <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            destination_reg <= destination;
        end
        else begin
            destination_reg <= destination_reg;
        end
    end
end

//adjacency matrix
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            for(j = 0; j < 16; j = j + 1) begin
                adj_matrix[i][j] <= 0;
            end
        end
    end
    else begin
        if(current_state == IDLE) begin
            for(i = 0; i < 16; i = i + 1) begin
                for(j = 0; j < 16; j = j + 1) begin
                    adj_matrix[i][j] <= 0;
                end
            end
        end
        else if(current_state == INPUT && in_valid) begin //1: connected
            adj_matrix[source][destination] <= 1;
            adj_matrix[destination][source] <= 1;
        end
        else begin
            for(i = 0; i < 16; i = i + 1) begin
                for(j = 0; j < 16; j = j + 1) begin
                    adj_matrix[i][j] <= adj_matrix[i][j];
                end
            end
        end
    end
end

//source vector
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            s_vector[i] <= 0;
        end
    end
    else begin
        if(current_state == IDLE && in_valid) begin
            s_vector[source] <= 1;
        end
        else if(current_state == INPUT) begin
            for(i = 0; i < 16; i = i + 1) begin
                s_vector[i] <= s_vector[i];
            end
        end
        else if(current_state == CAL) begin
            for(i = 0; i < 16; i = i + 1) begin //matrix * vector
                s_vector[0] <= (adj_matrix[0][0] & s_vector[0]) | (adj_matrix[1][0] & s_vector[1]) | (adj_matrix[2][0] & s_vector[2]) | (adj_matrix[3][0] & s_vector[3]) | (adj_matrix[4][0] & s_vector[4]) | (adj_matrix[5][0] & s_vector[5]) | (adj_matrix[6][0] & s_vector[6]) | (adj_matrix[7][0] & s_vector[7]) | (adj_matrix[8][0] & s_vector[8]) | (adj_matrix[9][0] & s_vector[9]) | (adj_matrix[10][0] & s_vector[10]) | (adj_matrix[11][0] & s_vector[11]) | (adj_matrix[12][0] & s_vector[12]) | (adj_matrix[13][0] & s_vector[13]) | (adj_matrix[14][0] & s_vector[14]) | (adj_matrix[15][0] & s_vector[15]);
                s_vector[1] <= (adj_matrix[0][1] & s_vector[0]) | (adj_matrix[1][1] & s_vector[1]) | (adj_matrix[2][1] & s_vector[2]) | (adj_matrix[3][1] & s_vector[3]) | (adj_matrix[4][1] & s_vector[4]) | (adj_matrix[5][1] & s_vector[5]) | (adj_matrix[6][1] & s_vector[6]) | (adj_matrix[7][1] & s_vector[7]) | (adj_matrix[8][1] & s_vector[8]) | (adj_matrix[9][1] & s_vector[9]) | (adj_matrix[10][1] & s_vector[10]) | (adj_matrix[11][1] & s_vector[11]) | (adj_matrix[12][1] & s_vector[12]) | (adj_matrix[13][1] & s_vector[13]) | (adj_matrix[14][1] & s_vector[14]) | (adj_matrix[15][1] & s_vector[15]);
                s_vector[2] <= (adj_matrix[0][2] & s_vector[0]) | (adj_matrix[1][2] & s_vector[1]) | (adj_matrix[2][2] & s_vector[2]) | (adj_matrix[3][2] & s_vector[3]) | (adj_matrix[4][2] & s_vector[4]) | (adj_matrix[5][2] & s_vector[5]) | (adj_matrix[6][2] & s_vector[6]) | (adj_matrix[7][2] & s_vector[7]) | (adj_matrix[8][2] & s_vector[8]) | (adj_matrix[9][2] & s_vector[9]) | (adj_matrix[10][2] & s_vector[10]) | (adj_matrix[11][2] & s_vector[11]) | (adj_matrix[12][2] & s_vector[12]) | (adj_matrix[13][2] & s_vector[13]) | (adj_matrix[14][2] & s_vector[14]) | (adj_matrix[15][2] & s_vector[15]);
                s_vector[3] <= (adj_matrix[0][3] & s_vector[0]) | (adj_matrix[1][3] & s_vector[1]) | (adj_matrix[2][3] & s_vector[2]) | (adj_matrix[3][3] & s_vector[3]) | (adj_matrix[4][3] & s_vector[4]) | (adj_matrix[5][3] & s_vector[5]) | (adj_matrix[6][3] & s_vector[6]) | (adj_matrix[7][3] & s_vector[7]) | (adj_matrix[8][3] & s_vector[8]) | (adj_matrix[9][3] & s_vector[9]) | (adj_matrix[10][3] & s_vector[10]) | (adj_matrix[11][3] & s_vector[11]) | (adj_matrix[12][3] & s_vector[12]) | (adj_matrix[13][3] & s_vector[13]) | (adj_matrix[14][3] & s_vector[14]) | (adj_matrix[15][3] & s_vector[15]);
                s_vector[4] <= (adj_matrix[0][4] & s_vector[0]) | (adj_matrix[1][4] & s_vector[1]) | (adj_matrix[2][4] & s_vector[2]) | (adj_matrix[3][4] & s_vector[3]) | (adj_matrix[4][4] & s_vector[4]) | (adj_matrix[5][4] & s_vector[5]) | (adj_matrix[6][4] & s_vector[6]) | (adj_matrix[7][4] & s_vector[7]) | (adj_matrix[8][4] & s_vector[8]) | (adj_matrix[9][4] & s_vector[9]) | (adj_matrix[10][4] & s_vector[10]) | (adj_matrix[11][4] & s_vector[11]) | (adj_matrix[12][4] & s_vector[12]) | (adj_matrix[13][4] & s_vector[13]) | (adj_matrix[14][4] & s_vector[14]) | (adj_matrix[15][4] & s_vector[15]);
                s_vector[5] <= (adj_matrix[0][5] & s_vector[0]) | (adj_matrix[1][5] & s_vector[1]) | (adj_matrix[2][5] & s_vector[2]) | (adj_matrix[3][5] & s_vector[3]) | (adj_matrix[4][5] & s_vector[4]) | (adj_matrix[5][5] & s_vector[5]) | (adj_matrix[6][5] & s_vector[6]) | (adj_matrix[7][5] & s_vector[7]) | (adj_matrix[8][5] & s_vector[8]) | (adj_matrix[9][5] & s_vector[9]) | (adj_matrix[10][5] & s_vector[10]) | (adj_matrix[11][5] & s_vector[11]) | (adj_matrix[12][5] & s_vector[12]) | (adj_matrix[13][5] & s_vector[13]) | (adj_matrix[14][5] & s_vector[14]) | (adj_matrix[15][5] & s_vector[15]);
                s_vector[6] <= (adj_matrix[0][6] & s_vector[0]) | (adj_matrix[1][6] & s_vector[1]) | (adj_matrix[2][6] & s_vector[2]) | (adj_matrix[3][6] & s_vector[3]) | (adj_matrix[4][6] & s_vector[4]) | (adj_matrix[5][6] & s_vector[5]) | (adj_matrix[6][6] & s_vector[6]) | (adj_matrix[7][6] & s_vector[7]) | (adj_matrix[8][6] & s_vector[8]) | (adj_matrix[9][6] & s_vector[9]) | (adj_matrix[10][6] & s_vector[10]) | (adj_matrix[11][6] & s_vector[11]) | (adj_matrix[12][6] & s_vector[12]) | (adj_matrix[13][6] & s_vector[13]) | (adj_matrix[14][6] & s_vector[14]) | (adj_matrix[15][6] & s_vector[15]);
                s_vector[7] <= (adj_matrix[0][7] & s_vector[0]) | (adj_matrix[1][7] & s_vector[1]) | (adj_matrix[2][7] & s_vector[2]) | (adj_matrix[3][7] & s_vector[3]) | (adj_matrix[4][7] & s_vector[4]) | (adj_matrix[5][7] & s_vector[5]) | (adj_matrix[6][7] & s_vector[6]) | (adj_matrix[7][7] & s_vector[7]) | (adj_matrix[8][7] & s_vector[8]) | (adj_matrix[9][7] & s_vector[9]) | (adj_matrix[10][7] & s_vector[10]) | (adj_matrix[11][7] & s_vector[11]) | (adj_matrix[12][7] & s_vector[12]) | (adj_matrix[13][7] & s_vector[13]) | (adj_matrix[14][7] & s_vector[14]) | (adj_matrix[15][7] & s_vector[15]);
                s_vector[8] <= (adj_matrix[0][8] & s_vector[0]) | (adj_matrix[1][8] & s_vector[1]) | (adj_matrix[2][8] & s_vector[2]) | (adj_matrix[3][8] & s_vector[3]) | (adj_matrix[4][8] & s_vector[4]) | (adj_matrix[5][8] & s_vector[5]) | (adj_matrix[6][8] & s_vector[6]) | (adj_matrix[7][8] & s_vector[7]) | (adj_matrix[8][8] & s_vector[8]) | (adj_matrix[9][8] & s_vector[9]) | (adj_matrix[10][8] & s_vector[10]) | (adj_matrix[11][8] & s_vector[11]) | (adj_matrix[12][8] & s_vector[12]) | (adj_matrix[13][8] & s_vector[13]) | (adj_matrix[14][8] & s_vector[14]) | (adj_matrix[15][8] & s_vector[15]);
                s_vector[9] <= (adj_matrix[0][9] & s_vector[0]) | (adj_matrix[1][9] & s_vector[1]) | (adj_matrix[2][9] & s_vector[2]) | (adj_matrix[3][9] & s_vector[3]) | (adj_matrix[4][9] & s_vector[4]) | (adj_matrix[5][9] & s_vector[5]) | (adj_matrix[6][9] & s_vector[6]) | (adj_matrix[7][9] & s_vector[7]) | (adj_matrix[8][9] & s_vector[8]) | (adj_matrix[9][9] & s_vector[9]) | (adj_matrix[10][9] & s_vector[10]) | (adj_matrix[11][9] & s_vector[11]) | (adj_matrix[12][9] & s_vector[12]) | (adj_matrix[13][9] & s_vector[13]) | (adj_matrix[14][9] & s_vector[14]) | (adj_matrix[15][9] & s_vector[15]);
                s_vector[10] <= (adj_matrix[0][10] & s_vector[0]) | (adj_matrix[1][10] & s_vector[1]) | (adj_matrix[2][10] & s_vector[2]) | (adj_matrix[3][10] & s_vector[3]) | (adj_matrix[4][10] & s_vector[4]) | (adj_matrix[5][10] & s_vector[5]) | (adj_matrix[6][10] & s_vector[6]) | (adj_matrix[7][10] & s_vector[7]) | (adj_matrix[8][10] & s_vector[8]) | (adj_matrix[9][10] & s_vector[9]) | (adj_matrix[10][10] & s_vector[10]) | (adj_matrix[11][10] & s_vector[11]) | (adj_matrix[12][10] & s_vector[12]) | (adj_matrix[13][10] & s_vector[13]) | (adj_matrix[14][10] & s_vector[14]) | (adj_matrix[15][10] & s_vector[15]);
                s_vector[11] <= (adj_matrix[0][11] & s_vector[0]) | (adj_matrix[1][11] & s_vector[1]) | (adj_matrix[2][11] & s_vector[2]) | (adj_matrix[3][11] & s_vector[3]) | (adj_matrix[4][11] & s_vector[4]) | (adj_matrix[5][11] & s_vector[5]) | (adj_matrix[6][11] & s_vector[6]) | (adj_matrix[7][11] & s_vector[7]) | (adj_matrix[8][11] & s_vector[8]) | (adj_matrix[9][11] & s_vector[9]) | (adj_matrix[10][11] & s_vector[10]) | (adj_matrix[11][11] & s_vector[11]) | (adj_matrix[12][11] & s_vector[12]) | (adj_matrix[13][11] & s_vector[13]) | (adj_matrix[14][11] & s_vector[14]) | (adj_matrix[15][11] & s_vector[15]);
                s_vector[12] <= (adj_matrix[0][12] & s_vector[0]) | (adj_matrix[1][12] & s_vector[1]) | (adj_matrix[2][12] & s_vector[2]) | (adj_matrix[3][12] & s_vector[3]) | (adj_matrix[4][12] & s_vector[4]) | (adj_matrix[5][12] & s_vector[5]) | (adj_matrix[6][12] & s_vector[6]) | (adj_matrix[7][12] & s_vector[7]) | (adj_matrix[8][12] & s_vector[8]) | (adj_matrix[9][12] & s_vector[9]) | (adj_matrix[10][12] & s_vector[10]) | (adj_matrix[11][12] & s_vector[11]) | (adj_matrix[12][12] & s_vector[12]) | (adj_matrix[13][12] & s_vector[13]) | (adj_matrix[14][12] & s_vector[14]) | (adj_matrix[15][12] & s_vector[15]);
                s_vector[13] <= (adj_matrix[0][13] & s_vector[0]) | (adj_matrix[1][13] & s_vector[1]) | (adj_matrix[2][13] & s_vector[2]) | (adj_matrix[3][13] & s_vector[3]) | (adj_matrix[4][13] & s_vector[4]) | (adj_matrix[5][13] & s_vector[5]) | (adj_matrix[6][13] & s_vector[6]) | (adj_matrix[7][13] & s_vector[7]) | (adj_matrix[8][13] & s_vector[8]) | (adj_matrix[9][13] & s_vector[9]) | (adj_matrix[10][13] & s_vector[10]) | (adj_matrix[11][13] & s_vector[11]) | (adj_matrix[12][13] & s_vector[12]) | (adj_matrix[13][13] & s_vector[13]) | (adj_matrix[14][13] & s_vector[14]) | (adj_matrix[15][13] & s_vector[15]);
                s_vector[14] <= (adj_matrix[0][14] & s_vector[0]) | (adj_matrix[1][14] & s_vector[1]) | (adj_matrix[2][14] & s_vector[2]) | (adj_matrix[3][14] & s_vector[3]) | (adj_matrix[4][14] & s_vector[4]) | (adj_matrix[5][14] & s_vector[5]) | (adj_matrix[6][14] & s_vector[6]) | (adj_matrix[7][14] & s_vector[7]) | (adj_matrix[8][14] & s_vector[8]) | (adj_matrix[9][14] & s_vector[9]) | (adj_matrix[10][14] & s_vector[10]) | (adj_matrix[11][14] & s_vector[11]) | (adj_matrix[12][14] & s_vector[12]) | (adj_matrix[13][14] & s_vector[13]) | (adj_matrix[14][14] & s_vector[14]) | (adj_matrix[15][14] & s_vector[15]);
                s_vector[15] <= (adj_matrix[0][15] & s_vector[0]) | (adj_matrix[1][15] & s_vector[1]) | (adj_matrix[2][15] & s_vector[2]) | (adj_matrix[3][15] & s_vector[3]) | (adj_matrix[4][15] & s_vector[4]) | (adj_matrix[5][15] & s_vector[5]) | (adj_matrix[6][15] & s_vector[6]) | (adj_matrix[7][15] & s_vector[7]) | (adj_matrix[8][15] & s_vector[8]) | (adj_matrix[9][15] & s_vector[9]) | (adj_matrix[10][15] & s_vector[10]) | (adj_matrix[11][15] & s_vector[11]) | (adj_matrix[12][15] & s_vector[12]) | (adj_matrix[13][15] & s_vector[13]) | (adj_matrix[14][15] & s_vector[14]) | (adj_matrix[15][15] & s_vector[15]);
            end
        end
        else begin
            for(i = 0; i < 16; i = i + 1) begin
                s_vector[i] <= 0;
            end
        end
    end
end


//==============================================//
//              Calculation Block               //
//==============================================//

assign find_answer = (s_vector[destination_reg] == 1) && (cost_count <= 15);
assign no_path = (s_vector[destination_reg] == 0) && (cost_count == 15);

//empty
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        empty <= 0;
    end
    else begin
        if(current_state == INPUT && in_valid_count == 0) begin
            empty <= 1;
        end
        else begin
            empty <= 0;
        end
    end
end

//cost_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cost_count <= 0;
    end
    else begin
        if(current_state == CAL) begin
            cost_count <= cost_count + 1;
        end
        else begin
            cost_count <= 0;
        end
    end
end

//==============================================//
//                Output Block                  //
//==============================================//

//out_valid
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 0; /* remember to reset */
    else begin
        if(current_state == CAL) begin
            if(empty) begin
                out_valid <= 1;
            end
            else if(find_answer) begin
                out_valid <= 1;
            end
            else if(no_path) begin
                out_valid <= 1;
            end
        end
        else begin
            out_valid <= 0;
        end
    end
end

//cost
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cost <= 0; /* remember to reset */
    else begin
        if(current_state == CAL) begin
            if(find_answer) begin
                cost <= cost_count;
            end
            // else if(no_path) begin
            //     cost <= 0;
            // end
            // else if(empty) begin
            //     cost <= 0;
            // end
            else begin
                cost <= 0;
            end
        end
        else begin
            cost <= 0;
        end
    end
end


endmodule



// //cal count
// always@ (posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         cal_count <= 0;
//     end
//     else begin
//         if(current_state == CAL) begin
//             cal_count <= cal_count + 1;
//         end
//         else begin
//             cal_count <= 0;
//         end
//     end
// end




//calculate vector
// always@ (posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         for(i = 0; i < 16; i = i + 1) begin
//             s_vector_temp[i] <= 0;
//         end
//     end
//     else begin
//         if(current_state == IDLE) begin
//             for(i = 0; i < 16; i = i + 1) begin
//                 s_vector_temp[i] <= 0;
//             end
//         end
//         else if(current_state == INPUT) begin
//             for(i = 0; i < 16; i = i + 1) begin
//                 s_vector_temp[i] <= s_vector_temp[i];
//             end
//         end
//         else if(current_state == CAL) begin
//             if(cal_count == 0) begin // adj_matrix * one hot vector
//                 s_vector_temp[0] <= (adj_matrix[0][0] & s_vector[0]) | (adj_matrix[1][0] & s_vector[1]) | (adj_matrix[2][0] & s_vector[2]) | (adj_matrix[3][0] & s_vector[3]) | (adj_matrix[4][0] & s_vector[4]) | (adj_matrix[5][0] & s_vector[5]) | (adj_matrix[6][0] & s_vector[6]) | (adj_matrix[7][0] & s_vector[7]) | (adj_matrix[8][0] & s_vector[8]) | (adj_matrix[9][0] & s_vector[9]) | (adj_matrix[10][0] & s_vector[10]) | (adj_matrix[11][0] & s_vector[11]) | (adj_matrix[12][0] & s_vector[12]) | (adj_matrix[13][0] & s_vector[13]) | (adj_matrix[14][0] & s_vector[14]) | (adj_matrix[15][0] & s_vector[15]);
//                 s_vector_temp[1] <= (adj_matrix[0][1] & s_vector[0]) | (adj_matrix[1][1] & s_vector[1]) | (adj_matrix[2][1] & s_vector[2]) | (adj_matrix[3][1] & s_vector[3]) | (adj_matrix[4][1] & s_vector[4]) | (adj_matrix[5][1] & s_vector[5]) | (adj_matrix[6][1] & s_vector[6]) | (adj_matrix[7][1] & s_vector[7]) | (adj_matrix[8][1] & s_vector[8]) | (adj_matrix[9][1] & s_vector[9]) | (adj_matrix[10][1] & s_vector[10]) | (adj_matrix[11][1] & s_vector[11]) | (adj_matrix[12][1] & s_vector[12]) | (adj_matrix[13][1] & s_vector[13]) | (adj_matrix[14][1] & s_vector[14]) | (adj_matrix[15][1] & s_vector[15]);
//                 s_vector_temp[2] <= (adj_matrix[0][2] & s_vector[0]) | (adj_matrix[1][2] & s_vector[1]) | (adj_matrix[2][2] & s_vector[2]) | (adj_matrix[3][2] & s_vector[3]) | (adj_matrix[4][2] & s_vector[4]) | (adj_matrix[5][2] & s_vector[5]) | (adj_matrix[6][2] & s_vector[6]) | (adj_matrix[7][2] & s_vector[7]) | (adj_matrix[8][2] & s_vector[8]) | (adj_matrix[9][2] & s_vector[9]) | (adj_matrix[10][2] & s_vector[10]) | (adj_matrix[11][2] & s_vector[11]) | (adj_matrix[12][2] & s_vector[12]) | (adj_matrix[13][2] & s_vector[13]) | (adj_matrix[14][2] & s_vector[14]) | (adj_matrix[15][2] & s_vector[15]);
//                 s_vector_temp[3] <= (adj_matrix[0][3] & s_vector[0]) | (adj_matrix[1][3] & s_vector[1]) | (adj_matrix[2][3] & s_vector[2]) | (adj_matrix[3][3] & s_vector[3]) | (adj_matrix[4][3] & s_vector[4]) | (adj_matrix[5][3] & s_vector[5]) | (adj_matrix[6][3] & s_vector[6]) | (adj_matrix[7][3] & s_vector[7]) | (adj_matrix[8][3] & s_vector[8]) | (adj_matrix[9][3] & s_vector[9]) | (adj_matrix[10][3] & s_vector[10]) | (adj_matrix[11][3] & s_vector[11]) | (adj_matrix[12][3] & s_vector[12]) | (adj_matrix[13][3] & s_vector[13]) | (adj_matrix[14][3] & s_vector[14]) | (adj_matrix[15][3] & s_vector[15]);
//                 s_vector_temp[4] <= (adj_matrix[0][4] & s_vector[0]) | (adj_matrix[1][4] & s_vector[1]) | (adj_matrix[2][4] & s_vector[2]) | (adj_matrix[3][4] & s_vector[3]) | (adj_matrix[4][4] & s_vector[4]) | (adj_matrix[5][4] & s_vector[5]) | (adj_matrix[6][4] & s_vector[6]) | (adj_matrix[7][4] & s_vector[7]) | (adj_matrix[8][4] & s_vector[8]) | (adj_matrix[9][4] & s_vector[9]) | (adj_matrix[10][4] & s_vector[10]) | (adj_matrix[11][4] & s_vector[11]) | (adj_matrix[12][4] & s_vector[12]) | (adj_matrix[13][4] & s_vector[13]) | (adj_matrix[14][4] & s_vector[14]) | (adj_matrix[15][4] & s_vector[15]);
//                 s_vector_temp[5] <= (adj_matrix[0][5] & s_vector[0]) | (adj_matrix[1][5] & s_vector[1]) | (adj_matrix[2][5] & s_vector[2]) | (adj_matrix[3][5] & s_vector[3]) | (adj_matrix[4][5] & s_vector[4]) | (adj_matrix[5][5] & s_vector[5]) | (adj_matrix[6][5] & s_vector[6]) | (adj_matrix[7][5] & s_vector[7]) | (adj_matrix[8][5] & s_vector[8]) | (adj_matrix[9][5] & s_vector[9]) | (adj_matrix[10][5] & s_vector[10]) | (adj_matrix[11][5] & s_vector[11]) | (adj_matrix[12][5] & s_vector[12]) | (adj_matrix[13][5] & s_vector[13]) | (adj_matrix[14][5] & s_vector[14]) | (adj_matrix[15][5] & s_vector[15]);
//                 s_vector_temp[6] <= (adj_matrix[0][6] & s_vector[0]) | (adj_matrix[1][6] & s_vector[1]) | (adj_matrix[2][6] & s_vector[2]) | (adj_matrix[3][6] & s_vector[3]) | (adj_matrix[4][6] & s_vector[4]) | (adj_matrix[5][6] & s_vector[5]) | (adj_matrix[6][6] & s_vector[6]) | (adj_matrix[7][6] & s_vector[7]) | (adj_matrix[8][6] & s_vector[8]) | (adj_matrix[9][6] & s_vector[9]) | (adj_matrix[10][6] & s_vector[10]) | (adj_matrix[11][6] & s_vector[11]) | (adj_matrix[12][6] & s_vector[12]) | (adj_matrix[13][6] & s_vector[13]) | (adj_matrix[14][6] & s_vector[14]) | (adj_matrix[15][6] & s_vector[15]);
//                 s_vector_temp[7] <= (adj_matrix[0][7] & s_vector[0]) | (adj_matrix[1][7] & s_vector[1]) | (adj_matrix[2][7] & s_vector[2]) | (adj_matrix[3][7] & s_vector[3]) | (adj_matrix[4][7] & s_vector[4]) | (adj_matrix[5][7] & s_vector[5]) | (adj_matrix[6][7] & s_vector[6]) | (adj_matrix[7][7] & s_vector[7]) | (adj_matrix[8][7] & s_vector[8]) | (adj_matrix[9][7] & s_vector[9]) | (adj_matrix[10][7] & s_vector[10]) | (adj_matrix[11][7] & s_vector[11]) | (adj_matrix[12][7] & s_vector[12]) | (adj_matrix[13][7] & s_vector[13]) | (adj_matrix[14][7] & s_vector[14]) | (adj_matrix[15][7] & s_vector[15]);

//                 s_vector_temp[8] <= (adj_matrix[0][8] & s_vector[0]) | (adj_matrix[1][8] & s_vector[1]) | (adj_matrix[2][8] & s_vector[2]) | (adj_matrix[3][8] & s_vector[3]) | (adj_matrix[4][8] & s_vector[4]) | (adj_matrix[5][8] & s_vector[5]) | (adj_matrix[6][8] & s_vector[6]) | (adj_matrix[7][8] & s_vector[7]) | (adj_matrix[8][8] & s_vector[8]) | (adj_matrix[9][8] & s_vector[9]) | (adj_matrix[10][8] & s_vector[10]) | (adj_matrix[11][8] & s_vector[11]) | (adj_matrix[12][8] & s_vector[12]) | (adj_matrix[13][8] & s_vector[13]) | (adj_matrix[14][8] & s_vector[14]) | (adj_matrix[15][8] & s_vector[15]);
//                 s_vector_temp[9] <= (adj_matrix[0][9] & s_vector[0]) | (adj_matrix[1][9] & s_vector[1]) | (adj_matrix[2][9] & s_vector[2]) | (adj_matrix[3][9] & s_vector[3]) | (adj_matrix[4][9] & s_vector[4]) | (adj_matrix[5][9] & s_vector[5]) | (adj_matrix[6][9] & s_vector[6]) | (adj_matrix[7][9] & s_vector[7]) | (adj_matrix[8][9] & s_vector[8]) | (adj_matrix[9][9] & s_vector[9]) | (adj_matrix[10][9] & s_vector[10]) | (adj_matrix[11][9] & s_vector[11]) | (adj_matrix[12][9] & s_vector[12]) | (adj_matrix[13][9] & s_vector[13]) | (adj_matrix[14][9] & s_vector[14]) | (adj_matrix[15][9] & s_vector[15]);
//                 s_vector_temp[10] <= (adj_matrix[0][10] & s_vector[0]) | (adj_matrix[1][10] & s_vector[1]) | (adj_matrix[2][10] & s_vector[2]) | (adj_matrix[3][10] & s_vector[3]) | (adj_matrix[4][10] & s_vector[4]) | (adj_matrix[5][10] & s_vector[5]) | (adj_matrix[6][10] & s_vector[6]) | (adj_matrix[7][10] & s_vector[7]) | (adj_matrix[8][10] & s_vector[8]) | (adj_matrix[9][10] & s_vector[9]) | (adj_matrix[10][10] & s_vector[10]) | (adj_matrix[11][10] & s_vector[11]) | (adj_matrix[12][10] & s_vector[12]) | (adj_matrix[13][10] & s_vector[13]) | (adj_matrix[14][10] & s_vector[14]) | (adj_matrix[15][10] & s_vector[15]);
//                 s_vector_temp[11] <= (adj_matrix[0][11] & s_vector[0]) | (adj_matrix[1][11] & s_vector[1]) | (adj_matrix[2][11] & s_vector[2]) | (adj_matrix[3][11] & s_vector[3]) | (adj_matrix[4][11] & s_vector[4]) | (adj_matrix[5][11] & s_vector[5]) | (adj_matrix[6][11] & s_vector[6]) | (adj_matrix[7][11] & s_vector[7]) | (adj_matrix[8][11] & s_vector[8]) | (adj_matrix[9][11] & s_vector[9]) | (adj_matrix[10][11] & s_vector[10]) | (adj_matrix[11][11] & s_vector[11]) | (adj_matrix[12][11] & s_vector[12]) | (adj_matrix[13][11] & s_vector[13]) | (adj_matrix[14][11] & s_vector[14]) | (adj_matrix[15][11] & s_vector[15]);
//                 s_vector_temp[12] <= (adj_matrix[0][12] & s_vector[0]) | (adj_matrix[1][12] & s_vector[1]) | (adj_matrix[2][12] & s_vector[2]) | (adj_matrix[3][12] & s_vector[3]) | (adj_matrix[4][12] & s_vector[4]) | (adj_matrix[5][12] & s_vector[5]) | (adj_matrix[6][12] & s_vector[6]) | (adj_matrix[7][12] & s_vector[7]) | (adj_matrix[8][12] & s_vector[8]) | (adj_matrix[9][12] & s_vector[9]) | (adj_matrix[10][12] & s_vector[10]) | (adj_matrix[11][12] & s_vector[11]) | (adj_matrix[12][12] & s_vector[12]) | (adj_matrix[13][12] & s_vector[13]) | (adj_matrix[14][12] & s_vector[14]) | (adj_matrix[15][12] & s_vector[15]);
//                 s_vector_temp[13] <= (adj_matrix[0][13] & s_vector[0]) | (adj_matrix[1][13] & s_vector[1]) | (adj_matrix[2][13] & s_vector[2]) | (adj_matrix[3][13] & s_vector[3]) | (adj_matrix[4][13] & s_vector[4]) | (adj_matrix[5][13] & s_vector[5]) | (adj_matrix[6][13] & s_vector[6]) | (adj_matrix[7][13] & s_vector[7]) | (adj_matrix[8][13] & s_vector[8]) | (adj_matrix[9][13] & s_vector[9]) | (adj_matrix[10][13] & s_vector[10]) | (adj_matrix[11][13] & s_vector[11]) | (adj_matrix[12][13] & s_vector[12]) | (adj_matrix[13][13] & s_vector[13]) | (adj_matrix[14][13] & s_vector[14]) | (adj_matrix[15][13] & s_vector[15]);
//                 s_vector_temp[14] <= (adj_matrix[0][14] & s_vector[0]) | (adj_matrix[1][14] & s_vector[1]) | (adj_matrix[2][14] & s_vector[2]) | (adj_matrix[3][14] & s_vector[3]) | (adj_matrix[4][14] & s_vector[4]) | (adj_matrix[5][14] & s_vector[5]) | (adj_matrix[6][14] & s_vector[6]) | (adj_matrix[7][14] & s_vector[7]) | (adj_matrix[8][14] & s_vector[8]) | (adj_matrix[9][14] & s_vector[9]) | (adj_matrix[10][14] & s_vector[10]) | (adj_matrix[11][14] & s_vector[11]) | (adj_matrix[12][14] & s_vector[12]) | (adj_matrix[13][14] & s_vector[13]) | (adj_matrix[14][14] & s_vector[14]) | (adj_matrix[15][14] & s_vector[15]);
//                 s_vector_temp[15] <= (adj_matrix[0][15] & s_vector[0]) | (adj_matrix[1][15] & s_vector[1]) | (adj_matrix[2][15] & s_vector[2]) | (adj_matrix[3][15] & s_vector[3]) | (adj_matrix[4][15] & s_vector[4]) | (adj_matrix[5][15] & s_vector[5]) | (adj_matrix[6][15] & s_vector[6]) | (adj_matrix[7][15] & s_vector[7]) | (adj_matrix[8][15] & s_vector[8]) | (adj_matrix[9][15] & s_vector[9]) | (adj_matrix[10][15] & s_vector[10]) | (adj_matrix[11][15] & s_vector[11]) | (adj_matrix[12][15] & s_vector[12]) | (adj_matrix[13][15] & s_vector[13]) | (adj_matrix[14][15] & s_vector[14]) | (adj_matrix[15][15] & s_vector[15]);
//             end

//             else if(cal_count > 0) begin //repeat multiplication until answer is found
//                 s_vector_temp[0] <= (adj_matrix[0][0] & s_vector_temp[0]) | (adj_matrix[1][0] & s_vector_temp[1]) | (adj_matrix[2][0] & s_vector_temp[2]) | (adj_matrix[3][0] & s_vector_temp[3]) | (adj_matrix[4][0] & s_vector_temp[4]) | (adj_matrix[5][0] & s_vector_temp[5]) | (adj_matrix[6][0] & s_vector_temp[6]) | (adj_matrix[7][0] & s_vector_temp[7]) | (adj_matrix[8][0] & s_vector_temp[8]) | (adj_matrix[9][0] & s_vector_temp[9]) | (adj_matrix[10][0] & s_vector_temp[10]) | (adj_matrix[11][0] & s_vector_temp[11]) | (adj_matrix[12][0] & s_vector_temp[12]) | (adj_matrix[13][0] & s_vector_temp[13]) | (adj_matrix[14][0] & s_vector_temp[14]) | (adj_matrix[15][0] & s_vector_temp[15]);
//                 s_vector_temp[1] <= (adj_matrix[0][1] & s_vector_temp[0]) | (adj_matrix[1][1] & s_vector_temp[1]) | (adj_matrix[2][1] & s_vector_temp[2]) | (adj_matrix[3][1] & s_vector_temp[3]) | (adj_matrix[4][1] & s_vector_temp[4]) | (adj_matrix[5][1] & s_vector_temp[5]) | (adj_matrix[6][1] & s_vector_temp[6]) | (adj_matrix[7][1] & s_vector_temp[7]) | (adj_matrix[8][1] & s_vector_temp[8]) | (adj_matrix[9][1] & s_vector_temp[9]) | (adj_matrix[10][1] & s_vector_temp[10]) | (adj_matrix[11][1] & s_vector_temp[11]) | (adj_matrix[12][1] & s_vector_temp[12]) | (adj_matrix[13][1] & s_vector_temp[13]) | (adj_matrix[14][1] & s_vector_temp[14]) | (adj_matrix[15][1] & s_vector_temp[15]);
//                 s_vector_temp[2] <= (adj_matrix[0][2] & s_vector_temp[0]) | (adj_matrix[1][2] & s_vector_temp[1]) | (adj_matrix[2][2] & s_vector_temp[2]) | (adj_matrix[3][2] & s_vector_temp[3]) | (adj_matrix[4][2] & s_vector_temp[4]) | (adj_matrix[5][2] & s_vector_temp[5]) | (adj_matrix[6][2] & s_vector_temp[6]) | (adj_matrix[7][2] & s_vector_temp[7]) | (adj_matrix[8][2] & s_vector_temp[8]) | (adj_matrix[9][2] & s_vector_temp[9]) | (adj_matrix[10][2] & s_vector_temp[10]) | (adj_matrix[11][2] & s_vector_temp[11]) | (adj_matrix[12][2] & s_vector_temp[12]) | (adj_matrix[13][2] & s_vector_temp[13]) | (adj_matrix[14][2] & s_vector_temp[14]) | (adj_matrix[15][2] & s_vector_temp[15]);
//                 s_vector_temp[3] <= (adj_matrix[0][3] & s_vector_temp[0]) | (adj_matrix[1][3] & s_vector_temp[1]) | (adj_matrix[2][3] & s_vector_temp[2]) | (adj_matrix[3][3] & s_vector_temp[3]) | (adj_matrix[4][3] & s_vector_temp[4]) | (adj_matrix[5][3] & s_vector_temp[5]) | (adj_matrix[6][3] & s_vector_temp[6]) | (adj_matrix[7][3] & s_vector_temp[7]) | (adj_matrix[8][3] & s_vector_temp[8]) | (adj_matrix[9][3] & s_vector_temp[9]) | (adj_matrix[10][3] & s_vector_temp[10]) | (adj_matrix[11][3] & s_vector_temp[11]) | (adj_matrix[12][3] & s_vector_temp[12]) | (adj_matrix[13][3] & s_vector_temp[13]) | (adj_matrix[14][3] & s_vector_temp[14]) | (adj_matrix[15][3] & s_vector_temp[15]);
//                 s_vector_temp[4] <= (adj_matrix[0][4] & s_vector_temp[0]) | (adj_matrix[1][4] & s_vector_temp[1]) | (adj_matrix[2][4] & s_vector_temp[2]) | (adj_matrix[3][4] & s_vector_temp[3]) | (adj_matrix[4][4] & s_vector_temp[4]) | (adj_matrix[5][4] & s_vector_temp[5]) | (adj_matrix[6][4] & s_vector_temp[6]) | (adj_matrix[7][4] & s_vector_temp[7]) | (adj_matrix[8][4] & s_vector_temp[8]) | (adj_matrix[9][4] & s_vector_temp[9]) | (adj_matrix[10][4] & s_vector_temp[10]) | (adj_matrix[11][4] & s_vector_temp[11]) | (adj_matrix[12][4] & s_vector_temp[12]) | (adj_matrix[13][4] & s_vector_temp[13]) | (adj_matrix[14][4] & s_vector_temp[14]) | (adj_matrix[15][4] & s_vector_temp[15]);
//                 s_vector_temp[5] <= (adj_matrix[0][5] & s_vector_temp[0]) | (adj_matrix[1][5] & s_vector_temp[1]) | (adj_matrix[2][5] & s_vector_temp[2]) | (adj_matrix[3][5] & s_vector_temp[3]) | (adj_matrix[4][5] & s_vector_temp[4]) | (adj_matrix[5][5] & s_vector_temp[5]) | (adj_matrix[6][5] & s_vector_temp[6]) | (adj_matrix[7][5] & s_vector_temp[7]) | (adj_matrix[8][5] & s_vector_temp[8]) | (adj_matrix[9][5] & s_vector_temp[9]) | (adj_matrix[10][5] & s_vector_temp[10]) | (adj_matrix[11][5] & s_vector_temp[11]) | (adj_matrix[12][5] & s_vector_temp[12]) | (adj_matrix[13][5] & s_vector_temp[13]) | (adj_matrix[14][5] & s_vector_temp[14]) | (adj_matrix[15][5] & s_vector_temp[15]);
//                 s_vector_temp[6] <= (adj_matrix[0][6] & s_vector_temp[0]) | (adj_matrix[1][6] & s_vector_temp[1]) | (adj_matrix[2][6] & s_vector_temp[2]) | (adj_matrix[3][6] & s_vector_temp[3]) | (adj_matrix[4][6] & s_vector_temp[4]) | (adj_matrix[5][6] & s_vector_temp[5]) | (adj_matrix[6][6] & s_vector_temp[6]) | (adj_matrix[7][6] & s_vector_temp[7]) | (adj_matrix[8][6] & s_vector_temp[8]) | (adj_matrix[9][6] & s_vector_temp[9]) | (adj_matrix[10][6] & s_vector_temp[10]) | (adj_matrix[11][6] & s_vector_temp[11]) | (adj_matrix[12][6] & s_vector_temp[12]) | (adj_matrix[13][6] & s_vector_temp[13]) | (adj_matrix[14][6] & s_vector_temp[14]) | (adj_matrix[15][6] & s_vector_temp[15]);
//                 s_vector_temp[7] <= (adj_matrix[0][7] & s_vector_temp[0]) | (adj_matrix[1][7] & s_vector_temp[1]) | (adj_matrix[2][7] & s_vector_temp[2]) | (adj_matrix[3][7] & s_vector_temp[3]) | (adj_matrix[4][7] & s_vector_temp[4]) | (adj_matrix[5][7] & s_vector_temp[5]) | (adj_matrix[6][7] & s_vector_temp[6]) | (adj_matrix[7][7] & s_vector_temp[7]) | (adj_matrix[8][7] & s_vector_temp[8]) | (adj_matrix[9][7] & s_vector_temp[9]) | (adj_matrix[10][7] & s_vector_temp[10]) | (adj_matrix[11][7] & s_vector_temp[11]) | (adj_matrix[12][7] & s_vector_temp[12]) | (adj_matrix[13][7] & s_vector_temp[13]) | (adj_matrix[14][7] & s_vector_temp[14]) | (adj_matrix[15][7] & s_vector_temp[15]);

//                 s_vector_temp[8] <= (adj_matrix[0][8] & s_vector_temp[0]) | (adj_matrix[1][8] & s_vector_temp[1]) | (adj_matrix[2][8] & s_vector_temp[2]) | (adj_matrix[3][8] & s_vector_temp[3]) | (adj_matrix[4][8] & s_vector_temp[4]) | (adj_matrix[5][8] & s_vector_temp[5]) | (adj_matrix[6][8] & s_vector_temp[6]) | (adj_matrix[7][8] & s_vector_temp[7]) | (adj_matrix[8][8] & s_vector_temp[8]) | (adj_matrix[9][8] & s_vector_temp[9]) | (adj_matrix[10][8] & s_vector_temp[10]) | (adj_matrix[11][8] & s_vector_temp[11]) | (adj_matrix[12][8] & s_vector_temp[12]) | (adj_matrix[13][8] & s_vector_temp[13]) | (adj_matrix[14][8] & s_vector_temp[14]) | (adj_matrix[15][8] & s_vector_temp[15]);
//                 s_vector_temp[9] <= (adj_matrix[0][9] & s_vector_temp[0]) | (adj_matrix[1][9] & s_vector_temp[1]) | (adj_matrix[2][9] & s_vector_temp[2]) | (adj_matrix[3][9] & s_vector_temp[3]) | (adj_matrix[4][9] & s_vector_temp[4]) | (adj_matrix[5][9] & s_vector_temp[5]) | (adj_matrix[6][9] & s_vector_temp[6]) | (adj_matrix[7][9] & s_vector_temp[7]) | (adj_matrix[8][9] & s_vector_temp[8]) | (adj_matrix[9][9] & s_vector_temp[9]) | (adj_matrix[10][9] & s_vector_temp[10]) | (adj_matrix[11][9] & s_vector_temp[11]) | (adj_matrix[12][9] & s_vector_temp[12]) | (adj_matrix[13][9] & s_vector_temp[13]) | (adj_matrix[14][9] & s_vector_temp[14]) | (adj_matrix[15][9] & s_vector_temp[15]);
//                 s_vector_temp[10] <= (adj_matrix[0][10] & s_vector_temp[0]) | (adj_matrix[1][10] & s_vector_temp[1]) | (adj_matrix[2][10] & s_vector_temp[2]) | (adj_matrix[3][10] & s_vector_temp[3]) | (adj_matrix[4][10] & s_vector_temp[4]) | (adj_matrix[5][10] & s_vector_temp[5]) | (adj_matrix[6][10] & s_vector_temp[6]) | (adj_matrix[7][10] & s_vector_temp[7]) | (adj_matrix[8][10] & s_vector_temp[8]) | (adj_matrix[9][10] & s_vector_temp[9]) | (adj_matrix[10][10] & s_vector_temp[10]) | (adj_matrix[11][10] & s_vector_temp[11]) | (adj_matrix[12][10] & s_vector_temp[12]) | (adj_matrix[13][10] & s_vector_temp[13]) | (adj_matrix[14][10] & s_vector_temp[14]) | (adj_matrix[15][10] & s_vector_temp[15]);
//                 s_vector_temp[11] <= (adj_matrix[0][11] & s_vector_temp[0]) | (adj_matrix[1][11] & s_vector_temp[1]) | (adj_matrix[2][11] & s_vector_temp[2]) | (adj_matrix[3][11] & s_vector_temp[3]) | (adj_matrix[4][11] & s_vector_temp[4]) | (adj_matrix[5][11] & s_vector_temp[5]) | (adj_matrix[6][11] & s_vector_temp[6]) | (adj_matrix[7][11] & s_vector_temp[7]) | (adj_matrix[8][11] & s_vector_temp[8]) | (adj_matrix[9][11] & s_vector_temp[9]) | (adj_matrix[10][11] & s_vector_temp[10]) | (adj_matrix[11][11] & s_vector_temp[11]) | (adj_matrix[12][11] & s_vector_temp[12]) | (adj_matrix[13][11] & s_vector_temp[13]) | (adj_matrix[14][11] & s_vector_temp[14]) | (adj_matrix[15][11] & s_vector_temp[15]);
//                 s_vector_temp[12] <= (adj_matrix[0][12] & s_vector_temp[0]) | (adj_matrix[1][12] & s_vector_temp[1]) | (adj_matrix[2][12] & s_vector_temp[2]) | (adj_matrix[3][12] & s_vector_temp[3]) | (adj_matrix[4][12] & s_vector_temp[4]) | (adj_matrix[5][12] & s_vector_temp[5]) | (adj_matrix[6][12] & s_vector_temp[6]) | (adj_matrix[7][12] & s_vector_temp[7]) | (adj_matrix[8][12] & s_vector_temp[8]) | (adj_matrix[9][12] & s_vector_temp[9]) | (adj_matrix[10][12] & s_vector_temp[10]) | (adj_matrix[11][12] & s_vector_temp[11]) | (adj_matrix[12][12] & s_vector_temp[12]) | (adj_matrix[13][12] & s_vector_temp[13]) | (adj_matrix[14][12] & s_vector_temp[14]) | (adj_matrix[15][12] & s_vector_temp[15]);
//                 s_vector_temp[13] <= (adj_matrix[0][13] & s_vector_temp[0]) | (adj_matrix[1][13] & s_vector_temp[1]) | (adj_matrix[2][13] & s_vector_temp[2]) | (adj_matrix[3][13] & s_vector_temp[3]) | (adj_matrix[4][13] & s_vector_temp[4]) | (adj_matrix[5][13] & s_vector_temp[5]) | (adj_matrix[6][13] & s_vector_temp[6]) | (adj_matrix[7][13] & s_vector_temp[7]) | (adj_matrix[8][13] & s_vector_temp[8]) | (adj_matrix[9][13] & s_vector_temp[9]) | (adj_matrix[10][13] & s_vector_temp[10]) | (adj_matrix[11][13] & s_vector_temp[11]) | (adj_matrix[12][13] & s_vector_temp[12]) | (adj_matrix[13][13] & s_vector_temp[13]) | (adj_matrix[14][13] & s_vector_temp[14]) | (adj_matrix[15][13] & s_vector_temp[15]);
//                 s_vector_temp[14] <= (adj_matrix[0][14] & s_vector_temp[0]) | (adj_matrix[1][14] & s_vector_temp[1]) | (adj_matrix[2][14] & s_vector_temp[2]) | (adj_matrix[3][14] & s_vector_temp[3]) | (adj_matrix[4][14] & s_vector_temp[4]) | (adj_matrix[5][14] & s_vector_temp[5]) | (adj_matrix[6][14] & s_vector_temp[6]) | (adj_matrix[7][14] & s_vector_temp[7]) | (adj_matrix[8][14] & s_vector_temp[8]) | (adj_matrix[9][14] & s_vector_temp[9]) | (adj_matrix[10][14] & s_vector_temp[10]) | (adj_matrix[11][14] & s_vector_temp[11]) | (adj_matrix[12][14] & s_vector_temp[12]) | (adj_matrix[13][14] & s_vector_temp[13]) | (adj_matrix[14][14] & s_vector_temp[14]) | (adj_matrix[15][14] & s_vector_temp[15]);
//                 s_vector_temp[15] <= (adj_matrix[0][15] & s_vector_temp[0]) | (adj_matrix[1][15] & s_vector_temp[1]) | (adj_matrix[2][15] & s_vector_temp[2]) | (adj_matrix[3][15] & s_vector_temp[3]) | (adj_matrix[4][15] & s_vector_temp[4]) | (adj_matrix[5][15] & s_vector_temp[5]) | (adj_matrix[6][15] & s_vector_temp[6]) | (adj_matrix[7][15] & s_vector_temp[7]) | (adj_matrix[8][15] & s_vector_temp[8]) | (adj_matrix[9][15] & s_vector_temp[9]) | (adj_matrix[10][15] & s_vector_temp[10]) | (adj_matrix[11][15] & s_vector_temp[11]) | (adj_matrix[12][15] & s_vector_temp[12]) | (adj_matrix[13][15] & s_vector_temp[13]) | (adj_matrix[14][15] & s_vector_temp[14]) | (adj_matrix[15][15] & s_vector_temp[15]);

//             end
//             else begin
//                 for(i = 0; i < 16; i = i + 1) begin
//                     s_vector_temp[i] <= s_vector_temp[i];
//                 end
//             end
//         end
//         else begin
//             for(i = 0; i < 16; i = i + 1) begin
//                 s_vector_temp[i] <= s_vector_temp[i];
//             end
//         end

//     end
// end