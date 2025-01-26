module bridge(input clk, INF.bridge_inf inf);
/*
    input C_addr,
    input C_data_w,
    input C_in_valid,
    input C_r_wb,
    input AR_READY,
    input R_VALID,
    input R_DATA,
    input AW_READY,
    input W_READY,
    input B_VALID,
    input B_RESP,

    output C_out_valid,
    output C_data_r,
    output AR_VALID,
    output AR_ADDR,
    output R_READY,
    output AW_VALID,
    output AW_ADDR,
    output W_VALID,
    output W_DATA,
    output B_READY
*/

//================================================================
// logic
//================================================================

//================================================================
// connect to design
//================================================================
//C_data_r
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_data_r <= 0;
    end
    else begin
        if(inf.R_VALID) begin
            inf.C_data_r <= inf.R_DATA;
        end
        else begin
            inf.C_data_r <= 0;
        end
    end
end

//C_out_valid
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_out_valid <= 0;
    end
    else begin
        if(inf.R_VALID || inf.B_VALID) begin
            inf.C_out_valid <= 1;
        end
        else begin
            inf.C_out_valid <= 0;
        end
    end
end

//================================================================
// read
//================================================================
//always_comb inf.R_READY = 1;
//R_READY
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.R_READY <= 0;
    end
    else inf.R_READY <= 1;
end

//AR_ADDR
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AR_ADDR <= 0;
    end
    else begin
        if(inf.C_in_valid && inf.C_r_wb) begin
            inf.AR_ADDR[15:0] <= inf.C_addr << 3;
            inf.AR_ADDR[16] <= 'd1;
        end
    end
end

//AR_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AR_VALID <= 0;
    end
    else begin
        if(inf.C_in_valid && inf.C_r_wb) begin
            inf.AR_VALID <= 1;
        end
        else if(inf.AR_READY) begin
            inf.AR_VALID <= 0;
        end
    end
end

//================================================================
// write
//================================================================
//always_comb inf.W_VALID = 1;
//always_comb inf.B_READY = 1;

//W_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.W_VALID <= 0;
    end
    else inf.W_VALID <= 1;
end

//B_READY
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.B_READY <= 0;
    end
    else inf.B_READY <= 1;
end

//AW_ADDR
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AW_ADDR <= 0;
    end
    else begin
        if(inf.C_in_valid && !inf.C_r_wb) begin
            inf.AW_ADDR[15:0] <= inf.C_addr << 3;
            inf.AW_ADDR[16] <= 'd1;
        end
    end
end

//AW_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AW_VALID <= 0;
    end
    else begin
        if(inf.C_in_valid && !inf.C_r_wb) begin
            inf.AW_VALID <= 1;
        end
        else if(inf.AW_READY) begin
            inf.AW_VALID <= 0;
        end
    end
end

//W_DATA
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.W_DATA <= 0;
    end
    else begin
        if(inf.C_in_valid && !inf.C_r_wb) begin
            inf.W_DATA <= inf.C_data_w;
        end
    end
end

endmodule