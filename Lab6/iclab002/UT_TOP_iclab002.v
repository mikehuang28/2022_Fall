//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : UT_TOP.v
//   Module Name : UT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "B2BCD_IP.v"

//synopsys translate_on

module UT_TOP (
    // Input signals
    clk, rst_n, in_valid, in_time,
    // Output signals
    out_valid, out_display, out_day
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [30:0] in_time;
output reg out_valid;
output reg [3:0] out_display;
output reg [2:0] out_day;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
//fsm
parameter IDLE = 0;
parameter INPUT = 1;
parameter CAL = 2;
parameter OUTPUT = 3;

//================================================================
// Wire & Reg Declaration
//================================================================
reg [1:0] next_state, current_state;
reg [4:0] count;
reg [4:0] four_year_span;
reg [1:0] leap_count; //0,1,2,3
reg [30:0] in_time_reg;
reg [26:0] four_year;
reg [24:0] one_year;
reg [21:0] month;
reg [17:0] date;
reg [17:0] hour;

//div
reg [5:0] minute;
reg [5:0] second;

//for ip
reg [10:0] year_ip_in;
reg [3:0] month_ip_in;
reg [4:0] date_ip_in;
reg [4:0] hour_ip_in;
reg [5:0] minute_ip_in;
reg [5:0] second_ip_in;
reg [11:0] bin;
wire [15:0] bout;

reg [2:0] out_day_reg; //0:sunday
reg [15:0] year_ip_out;
reg [7:0] month_ip_out, date_ip_out, hour_ip_out, minute_ip_out, second_ip_out;

//================================================================
// Finite State Machine
//================================================================
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
            next_state = CAL;
        else
            next_state = IDLE;
    end
    // INPUT: begin
    //     if(!in_valid)
    //         next_state = CAL;
    //     else
    //         next_state = INPUT;
    // end
    CAL: begin
        if(count == 17)
            next_state = IDLE;
        else
            next_state = CAL;
    end
    default: next_state = current_state;
    endcase
end

//================================================================
// Soft IP
//================================================================

B2BCD_IP #(.WIDTH(12), .DIGIT(4)) B0(.Binary_code(bin), .BCD_code(bout));

always@ (*) begin
    if(current_state == CAL) begin
        case(count - 1)
        2: bin = {1'b0, year_ip_in};
        3: bin = {8'b0, month_ip_in};
        4: bin = {7'b0, date_ip_in};
        5: bin = {7'b0, hour_ip_in};
        6: bin = {6'b0, minute_ip_in};
        7: bin = {6'b0, second_ip_in};
        default: bin = 0;
        endcase
    end
    else begin
        bin = 0;
    end
end

always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        year_ip_out <= 0;
        month_ip_out <= 0;
        date_ip_out <= 0;
        hour_ip_out <= 0;
        minute_ip_out <= 0;
        second_ip_out <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            year_ip_out <= 0;
            month_ip_out <= 0;
            date_ip_out <= 0;
            hour_ip_out <= 0;
            minute_ip_out <= 0;
            second_ip_out <= 0;
        end
        else if(current_state == CAL) begin
            case(count - 1)
            2: year_ip_out <= bout;
            3: month_ip_out <= bout[7:0];
            4: date_ip_out <= bout[7:0];
            5: hour_ip_out <= bout[7:0];
            6: minute_ip_out <= bout[7:0];
            7: second_ip_out <= bout[7:0];
            endcase
        end
    end
end

//================================================================
// Input Block
//================================================================
//in_time_reg
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_time_reg <= 0;
    end
    else begin
        if(in_valid) begin
            in_time_reg <= in_time;
        end
        else if(current_state == CAL) begin
            in_time_reg <= in_time_reg;
        end
    end
end

//================================================================
// Calculation
//================================================================
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
            count <= count;
        end
    end
end

//four_year_span
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        four_year_span <= 0;
    end
    else begin
        if(current_state == IDLE)
            four_year_span <= 0;
        else if(current_state == CAL) begin
            if(count == 0) begin
                if(in_time_reg >= 0 && in_time_reg < 126230400) four_year_span <= 0;
                else if(in_time_reg < 252460800)  four_year_span <= 1;
                else if(in_time_reg < 378691200)  four_year_span <= 2;
                else if(in_time_reg < 504921600)  four_year_span <= 3;
                else if(in_time_reg < 631152000)  four_year_span <= 4;
                else if(in_time_reg < 757382400)  four_year_span <= 5;
                else if(in_time_reg < 883612800)  four_year_span <= 6;
                else if(in_time_reg < 1009843200) four_year_span <= 7;
                else if(in_time_reg < 1136073600) four_year_span <= 8;
                else if(in_time_reg < 1262304000) four_year_span <= 9;
                else if(in_time_reg < 1388534400) four_year_span <= 10;
                else if(in_time_reg < 1514764800) four_year_span <= 11;
                else if(in_time_reg < 1640995200) four_year_span <= 12;
                else if(in_time_reg < 1767225600) four_year_span <= 13;
                else if(in_time_reg < 1893456000) four_year_span <= 14;
                else if(in_time_reg < 2019686400) four_year_span <= 15;
                else if(in_time_reg < 2145916800) four_year_span <= 16;
                else                              four_year_span <= 17;
            end
            else begin
                four_year_span <= four_year_span;
            end
        end
    end
end

//four_year
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        four_year <= 0;
    end
    else begin
        if(current_state == IDLE)
            four_year <= 0;
        else if(current_state == CAL) begin
            if(in_time_reg >= 0 && in_time_reg < 126230400) four_year <= in_time_reg;
            else if(in_time_reg < 252460800)  four_year <= in_time_reg - 126230400;
            else if(in_time_reg < 378691200)  four_year <= in_time_reg - 252460800;
            else if(in_time_reg < 504921600)  four_year <= in_time_reg - 378691200;
            else if(in_time_reg < 631152000)  four_year <= in_time_reg - 504921600;
            else if(in_time_reg < 757382400)  four_year <= in_time_reg - 631152000;
            else if(in_time_reg < 883612800)  four_year <= in_time_reg - 757382400;
            else if(in_time_reg < 1009843200) four_year <= in_time_reg - 883612800;
            else if(in_time_reg < 1136073600) four_year <= in_time_reg - 1009843200;
            else if(in_time_reg < 1262304000) four_year <= in_time_reg - 1136073600;
            else if(in_time_reg < 1388534400) four_year <= in_time_reg - 1262304000;
            else if(in_time_reg < 1514764800) four_year <= in_time_reg - 1388534400;
            else if(in_time_reg < 1640995200) four_year <= in_time_reg - 1514764800;
            else if(in_time_reg < 1767225600) four_year <= in_time_reg - 1640995200;
            else if(in_time_reg < 1893456000) four_year <= in_time_reg - 1767225600;
            else if(in_time_reg < 2019686400) four_year <= in_time_reg - 1893456000;
            else if(in_time_reg < 2145916800) four_year <= in_time_reg - 2019686400;
            else                              four_year <= in_time_reg - 2145916800;
        end
    end
end

//one year
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        one_year <= 0;
    end
    else begin
        if(current_state == IDLE)
            one_year <= 0;
        else if(current_state == CAL) begin
            if(four_year >= 0 && four_year < 31536000)
                one_year <= four_year;
            else if(four_year < 63072000)
                one_year <= four_year - 31536000;
            else if(four_year < 94694400)
                one_year <= four_year - 63072000;
            else
                one_year <= four_year - 94694400;
        end
    end
end

//leap_count
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        leap_count <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            leap_count <= 0;
        end
        else if (current_state == CAL) begin
            if(four_year >= 0 && four_year < 31536000)
                leap_count <= 0;
            else if(four_year < 63072000)
                leap_count <= 1;
            else if(four_year < 94694400)
                leap_count <= 2;
            else
                leap_count <= 3;
        end
    end
end

//year
always@ (posedge clk) begin

    if(current_state == IDLE) begin
        year_ip_in <= 0;
    end
    else if(current_state == CAL) begin
        if(count == 2)
            year_ip_in <= 1970 + four_year_span * 4 + leap_count;
    end

end

//month
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        month <= 0;
        month_ip_in <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            month <= 0;
            month_ip_in <= 0;
        end
        else if(current_state == CAL) begin
            if(count == 2) begin
                if(leap_count == 2) begin //leap year
                    if(one_year >= 0 && one_year < 2678400) begin//1
                        month <= one_year;
                        month_ip_in <= 1;
                    end
                    else if(one_year < 5184000) begin//2
                        month <= one_year - 2678400;
                        month_ip_in <= 2;
                    end
                    else if(one_year < 7862400) begin//3
                        month <= one_year - 5184000;
                        month_ip_in <= 3;
                    end
                    else if(one_year < 10454400) begin//4
                        month <= one_year - 7862400;
                        month_ip_in <= 4;
                    end
                    else if(one_year < 13132800) begin//5
                        month <= one_year - 10454400;
                        month_ip_in <= 5;
                    end
                    else if(one_year < 15724800) begin//6
                        month <= one_year - 13132800;
                        month_ip_in <= 6;
                    end
                    else if(one_year < 18403200) begin//7
                        month <= one_year - 15724800;
                        month_ip_in <= 7;
                    end
                    else if(one_year < 21081600) begin//8
                        month <= one_year - 18403200;
                        month_ip_in <= 8;
                    end
                    else if(one_year < 23673600) begin//9
                        month <= one_year - 21081600;
                        month_ip_in <= 9;
                    end
                    else if(one_year < 26352000) begin//10
                        month <= one_year - 23673600;
                        month_ip_in <= 10;
                    end
                    else if(one_year < 28944000) begin//11
                        month <= one_year - 26352000;
                        month_ip_in <= 11;
                    end
                    else  begin//12
                        month <= one_year - 28944000;
                        month_ip_in <= 12;
                    end
                end
                else begin //common year
                    if(one_year >= 0 && one_year < 2678400) begin//1
                        month <= one_year;
                        month_ip_in <= 1;
                    end
                    else if(one_year < 5097600) begin//2
                        month <= one_year - 2678400;
                        month_ip_in <= 2;
                    end
                    else if(one_year < 7776000) begin//3
                        month <= one_year - 5097600;
                        month_ip_in <= 3;
                    end
                    else if(one_year < 10368000) begin//4
                        month <= one_year - 7776000;
                        month_ip_in <= 4;
                    end
                    else if(one_year < 13046400) begin//5
                        month <= one_year - 10368000;
                        month_ip_in <= 5;
                    end
                    else if(one_year < 15638400) begin//6
                        month <= one_year - 13046400;
                        month_ip_in <= 6;
                    end
                    else if(one_year < 18316800) begin//7
                        month <= one_year - 15638400;
                        month_ip_in <= 7;
                    end
                    else if(one_year < 20995200) begin//8
                        month <= one_year - 18316800;
                        month_ip_in <= 8;
                    end
                    else if(one_year < 23587200) begin//9
                        month <= one_year - 20995200;
                        month_ip_in <= 9;
                    end
                    else if(one_year < 26265600) begin//10
                        month <= one_year - 23587200;
                        month_ip_in <= 10;
                    end
                    else if(one_year < 28857600) begin//11
                        month <= one_year - 26265600;
                        month_ip_in <= 11;
                    end
                    else begin//12
                        month <= one_year - 28857600;
                        month_ip_in <= 12;
                    end
                end
            end
        end
    end
end

//date
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        date <= 0;
        date_ip_in <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            date <= 0;
            date_ip_in <= 0;
        end
        else if(current_state == CAL) begin
            if(count == 3) begin
                if(month >= 0 && month < 86400) begin
                    date <= month;
                    date_ip_in <= 1;
                end
                else if(month < 172800) begin
                    date <= month - 86400;
                    date_ip_in <= 2;
                end
                else if(month < 259200) begin
                    date <= month - 172800;
                    date_ip_in <= 3;
                end
                else if(month < 345600) begin
                    date <= month - 259200;
                    date_ip_in <= 4;
                end
                else if(month < 432000) begin
                    date <= month - 345600;
                    date_ip_in <= 5;
                end
                else if(month < 518400) begin
                    date <= month - 432000;
                    date_ip_in <= 6;
                end
                else if(month < 604800) begin
                    date <= month - 518400;
                    date_ip_in <= 7;
                end
                else if(month < 691200) begin
                    date <= month - 604800;
                    date_ip_in <= 8;
                end
                else if(month < 777600) begin
                    date <= month - 691200;
                    date_ip_in <= 9;
                end
                else if(month < 864000) begin
                    date <= month - 777600;
                    date_ip_in <= 10;
                end
                else if(month < 950400) begin
                    date <= month - 864000;
                    date_ip_in <= 11;
                end
                else if(month < 1036800) begin
                    date <= month - 950400;
                    date_ip_in <= 12;
                end
                else if(month < 1123200) begin
                    date <= month - 1036800;
                    date_ip_in <= 13;
                end
                else if(month < 1209600) begin
                    date <= month - 1123200;
                    date_ip_in <= 14;
                end
                else if(month < 1296000) begin
                    date <= month - 1209600;
                    date_ip_in <= 15;
                end
                else if(month < 1382400) begin
                    date <= month - 1296000;
                    date_ip_in <= 16;
                end
                else if(month < 1468800) begin
                    date <= month - 1382400;
                    date_ip_in <= 17;
                end
                else if(month < 1555200) begin
                    date <= month - 1468800;
                    date_ip_in <= 18;
                end
                else if(month < 1641600) begin
                    date <= month - 1555200;
                    date_ip_in <= 19;
                end
                else if(month < 1728000) begin
                    date <= month - 1641600;
                    date_ip_in <= 20;
                end
                else if(month < 1814400) begin
                    date <= month - 1728000;
                    date_ip_in <= 21;
                end
                else if(month < 1900800) begin
                    date <= month - 1814400;
                    date_ip_in <= 22;
                end
                else if(month < 1987200) begin
                    date <= month - 1900800;
                    date_ip_in <= 23;
                end
                else if(month < 2073600) begin
                    date <= month - 1987200;
                    date_ip_in <= 24;
                end
                else if(month < 2160000) begin
                    date <= month - 2073600;
                    date_ip_in <= 25;
                end
                else if(month < 2246400) begin
                    date <= month - 2160000;
                    date_ip_in <= 26;
                end
                else if(month < 2332800) begin
                    date <= month - 2246400;
                    date_ip_in <= 27;
                end
                else if(month < 2419200) begin
                    date <= month - 2332800;
                    date_ip_in <= 28;
                end
                else if(month < 2505600) begin
                    date <= month - 2419200;
                    date_ip_in <= 29;
                end
                else if(month < 2592000) begin
                    date <= month - 2505600;
                    date_ip_in <= 30;
                end
                else begin
                    date <= month - 2592000;
                    date_ip_in <= 31;
                end
            end
        end
    end
end

//hour
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        hour <= 0;
        hour_ip_in <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            hour <= 0;
            hour_ip_in <= 0;
        end
        else if(current_state == CAL) begin
            if(date >= 0 && date < 3600) begin
                hour <= date;
                hour_ip_in <= 0;
            end
            else if(date < 7200) begin
                hour <= date - 3600;
                hour_ip_in <= 1;
            end
            else if(date < 10800) begin
                hour <= date - 7200;
                hour_ip_in <= 2;
            end
            else if(date < 14400) begin
                hour <= date - 10800;
                hour_ip_in <= 3;
            end
            else if(date < 18000) begin
                hour <= date - 14400;
                hour_ip_in <= 4;
            end
            else if(date < 21600) begin
                hour <= date - 18000;
                hour_ip_in <= 5;
            end
            else if(date < 25200) begin
                hour <= date - 21600;
                hour_ip_in <= 6;
            end
            else if(date < 28800) begin
                hour <= date - 25200;
                hour_ip_in <= 7;
            end
            else if(date < 32400) begin
                hour <= date - 28800;
                hour_ip_in <= 8;
            end
            else if(date < 36000) begin
                hour <= date - 32400;
                hour_ip_in <= 9;
            end
            else if(date < 39600) begin
                hour <= date - 36000;
                hour_ip_in <= 10;
            end
            else if(date < 43200) begin
                hour <= date - 39600;
                hour_ip_in <= 11;
            end
            else if(date < 46800) begin
                hour <= date - 43200;
                hour_ip_in <= 12;
            end
            else if(date < 50400) begin
                hour <= date - 46800;
                hour_ip_in <= 13;
            end
            else if(date < 54000) begin
                hour <= date - 50400;
                hour_ip_in <= 14;
            end
            else if(date < 57600) begin
                hour <= date - 54000;
                hour_ip_in <= 15;
            end
            else if(date < 61200) begin
                hour <= date - 57600;
                hour_ip_in <= 16;
            end
            else if(date < 64800) begin
                hour <= date - 61200;
                hour_ip_in <= 17;
            end
            else if(date < 68400) begin
                hour <= date - 64800;
                hour_ip_in <= 18;
            end
            else if(date < 72000) begin
                hour <= date - 68400;
                hour_ip_in <= 19;
            end
            else if(date < 75600) begin
                hour <= date - 72000;
                hour_ip_in <= 20;
            end
            else if(date < 79200) begin
                hour <= date - 75600;
                hour_ip_in <= 21;
            end
            else if(date < 82800) begin
                hour <= date - 79200;
                hour_ip_in <= 22;
            end
            else begin
                hour <= date - 82800;
                hour_ip_in <= 23;
            end
        end
    end
end

//minute && second
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        minute_ip_in <= 0;
        second_ip_in <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            minute_ip_in <= 0;
            second_ip_in <= 0;
        end
        else if(current_state == CAL) begin
            minute_ip_in <= hour / 'd60;
            second_ip_in <= hour % 'd60;
        end
    end
end

//week_day
always@ (*) begin
    if(current_state == CAL) begin
        if(count == 4) begin
            if(month_ip_in == 1 || month_ip_in == 2) begin
                out_day_reg = (date_ip_in + (month_ip_in + 12) * 2 + 3 * (month_ip_in + 13) / 5 + (year_ip_in - 1) + (year_ip_in - 1) / 4) % 7;
            end
            else begin
                out_day_reg = (date_ip_in + month_ip_in * 2 + 3 * (month_ip_in + 1) / 5 + year_ip_in + year_ip_in / 4 ) % 7;
            end
        end
        else begin
            out_day_reg = 0;
        end
    end
    else begin
        out_day_reg = 0;
    end
end

//================================================================
// Output Logic
//================================================================
//out_valid
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if(current_state == CAL) begin
            if(count >= 4 && count <= 17)
                out_valid <= 1;
            else
                out_valid <= 0;
        end
        else begin
            out_valid <= 0;
        end
    end
end

//out_day
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_day <= 0;
    end
    else begin
        if(current_state == CAL) begin
            if(count == 4) begin
                out_day <= out_day_reg;
            end
            else begin
                out_day <= out_day;
            end
        end
        else begin
            out_day <= 0;
        end
    end
end

//out_display
always@ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_display <= 0;
    end
    else begin
        if(current_state == CAL) begin
            case(count)
            4: out_display <= year_ip_out[15:12];
            5: out_display <= year_ip_out[11:8];
            6: out_display <= year_ip_out[7:4];
            7: out_display <= year_ip_out[3:0];
            8: out_display <= month_ip_out[7:4];
            9: out_display <= month_ip_out[3:0];
            10: out_display <= date_ip_out[7:4];
            11: out_display <= date_ip_out[3:0];
            12: out_display <= hour_ip_out[7:4];
            13: out_display <= hour_ip_out[3:0];
            14: out_display <= minute_ip_out[7:4];
            15: out_display <= minute_ip_out[3:0];
            16: out_display <= second_ip_out[7:4];
            17: out_display <= second_ip_out[3:0];
            default: out_display <= 0;
            endcase
        end
        else begin
            out_display <= 0;
        end
    end
end




endmodule