module FD(input clk, INF.FD_inf inf);
import usertype::*;

/*
    input clk,
    input rst_n,
    input id_valid,
    input act_valid,
    input cus_valid,
    input res_valid,
    input food_valid,
    input D,
    input C_out_valid,
    input C_data_r,

    output out_valid,
    output err_msg,
    output complete,
    output out_info,
    output C_addr,
    output C_data_w,
    output C_in_valid,
    output C_r_wb,
*/

//===========================================================================
// parameter
//===========================================================================
//parameter i;

//===========================================================================
// logic
//===========================================================================
fsm current_state, next_state;
Action action_reg;
Delivery_man_id id_reg;
Ctm_Info ctm_info_reg;
Restaurant_id res_reg;
food_ID_servings food_reg;
D_man_Info d_man_info_reg1, d_man_info_reg2;
res_info res_info_reg1, res_info_reg2;
Error_Msg err_reg;

//flag
logic action_flag, id_flag, res_flag, cus_flag, food_flag;
logic dram_flag;
logic [1:0] take_flag;
logic dram_busy, dram_busy_reg;
logic C_out_valid_flag;

//===========================================================================
// finite state machine
//===========================================================================
//current_state
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

//next_state
always_comb begin
    case(current_state)
    IDLE: begin
        if(inf.act_valid) begin
            next_state = READ_DRAM;
        end
        else begin
            next_state = IDLE;
        end
    end
    READ_DRAM: begin
        if(dram_busy) begin
            next_state = WAIT_READ;
        end
        else if(action_reg == Order && (!res_flag && food_flag)) begin
            next_state = CAL;
        end
        else begin
            next_state = READ_DRAM;
        end
    end
    WAIT_READ: begin
        if(action_reg != Take) begin
            if(inf.C_out_valid && dram_flag) begin
                next_state = CAL;
            end
            else begin
                next_state = WAIT_READ;
            end
        end
        else if((/*action_reg == Take &&*/ id_reg == ctm_info_reg.res_ID)) begin
            if(inf.C_out_valid && dram_flag) begin
                next_state = CAL;
            end
            else begin
                next_state = WAIT_READ;
            end
        end
        else begin //read twice
            if(inf.C_out_valid && dram_flag && take_flag == 2) begin
                next_state = CAL;
            end
            else if(inf.C_out_valid && dram_flag) begin
                next_state = READ_DRAM;
            end
            else begin
                next_state = WAIT_READ;
            end
        end
    end
    CAL: begin //compute err
        //next_state = WRITE_DRAM;
        if(err_reg == No_Err) begin
            next_state = WRITE_DRAM;
        end
        else begin
            next_state = OUTPUT;
        end
    end
    WRITE_DRAM: begin
        if(dram_busy) begin
            next_state = WAIT_WRITE;
        end
        else begin
            next_state = WRITE_DRAM;
        end
    end
    WAIT_WRITE: begin
        if(action_reg != Take) begin
            if(inf.C_out_valid /*&& dram_flag*/) begin
                next_state = OUTPUT;
            end
            else begin
                next_state = WAIT_WRITE;
            end
        end
        else if((action_reg == Take && id_reg == ctm_info_reg.res_ID)) begin
            if(inf.C_out_valid /*&& dram_flag*/) begin
                next_state = OUTPUT;
            end
            else begin
                next_state = WAIT_WRITE;
            end
        end
        else begin //write twice
            if(inf.C_out_valid /*&& dram_flag*/ && take_flag == 1) begin
                next_state = OUTPUT;
            end
            else if(inf.C_out_valid /*&& dram_flag*/) begin
                next_state = WRITE_DRAM;
            end
            else begin
                next_state = WAIT_WRITE;
            end
        end
    end
    OUTPUT: begin
        next_state = IDLE;
    end
    default: next_state = current_state;
    endcase
end

//===========================================================================
// flag
//===========================================================================
//dram_flag
always_comb begin
    if(current_state == READ_DRAM || current_state == WAIT_READ) begin
        case(action_reg)
        Take: begin
            dram_flag = /*action_flag &*/ cus_flag;
        end
        Deliver ,Cancel: begin
            dram_flag = /*action_flag &*/ id_flag;
        end
        Order: begin
            dram_flag = /*action_flag &*/ res_flag;
        end
        default: dram_flag = 0;
        endcase
    end
    else begin
        dram_flag = 0;
    end

end

//take_flag
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        take_flag <= 0;
    end
    else begin
        if(current_state == IDLE) begin
            take_flag <= 0;
        end
        else if(action_reg == Take && current_state == READ_DRAM) begin
            if(inf.C_in_valid) begin
                take_flag <= take_flag + 1;
            end
        end
        else if(action_reg == Take && current_state == WAIT_WRITE) begin
            if(inf.C_out_valid) begin
                take_flag <= take_flag - 1;
            end
        end
    end
end

//action_flag
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        action_flag <= 0;
    end
    else begin
        if(inf.act_valid) begin
            action_flag <= 1;
        end
        // else if(current_state == CAL) begin
        //     action_flag <= 0;
        // end
    end
end

//id_flag
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        id_flag <= 0;
    end
    else begin
        if(inf.id_valid) begin
            id_flag <= 1;
        end
        else if(inf.C_out_valid) begin
            id_flag <= 0;
        end
    end
end

//res_flag
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        res_flag <= 0;
    end
    else begin
        if(inf.res_valid && action_reg != Cancel) begin
            res_flag <= 1;
        end
        else if(current_state == OUTPUT) begin
            res_flag <= 0;
        end
    end
end

//cus_flag
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        cus_flag <= 0;
    end
    else begin
        if(inf.cus_valid) begin
            cus_flag <= 1;
        end
        else if(current_state == OUTPUT) begin
            cus_flag <= 0;
        end
    end
end

//food_flag
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        food_flag <= 0;
    end
    else begin
        if(inf.food_valid) begin
            food_flag <= 1;
        end
        else if(current_state == OUTPUT) begin
            food_flag <= 0;
        end
    end
end

//dram_busy_reg
always_ff@ (posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        dram_busy_reg <= 0;
    end
    else begin
        if(inf.C_in_valid) begin
            dram_busy_reg <= 1;
        end
        else if(inf.C_out_valid) begin
            dram_busy_reg <= 0;
        end
    end
end
assign dram_busy = (dram_busy_reg || inf.C_in_valid) && !inf.C_out_valid;

//===========================================================================
// input block
//===========================================================================
//action_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        action_reg <= No_action;
    end
    else begin
        if(inf.act_valid) begin
            action_reg <= inf.D.d_act[0];
        end
        else if(current_state == OUTPUT) begin
            action_reg <= No_action;
        end
    end
end

//id_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        id_reg <= 0;
    end
    else begin
        if(inf.id_valid) begin
            id_reg <= inf.D.d_id[0];
        end
        // else if(current_state == OUTPUT) begin
        //     id_reg <= 0;
        // end
    end
end

//ctm_info_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        ctm_info_reg <= 0;
    end
    else begin
        if(inf.cus_valid) begin
            ctm_info_reg <= inf.D.d_ctm_info[0];
        end
    end
end

//res_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        res_reg <= 0;
    end
    else begin
        if(inf.res_valid) begin
            res_reg <= inf.D.d_res_id[0];
        end
    end
end

//food_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        food_reg <= 0;
    end
    else begin
        if(inf.food_valid) begin
            food_reg <= inf.D.d_food_ID_ser[0];
        end
    end
end

//read delivery man info
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        d_man_info_reg1 <= 0;
        res_info_reg1 <= 0;
    end
    else begin
        if(inf.C_out_valid && inf.C_r_wb && (id_flag || res_flag)) begin
            {d_man_info_reg1.ctm_info2[7:0], d_man_info_reg1.ctm_info2[15:8]} <= inf.C_data_r[63:48];
            {d_man_info_reg1.ctm_info1[7:0], d_man_info_reg1.ctm_info1[15:8]} <= inf.C_data_r[47:32];
            res_info_reg1.ser_FOOD3 <= inf.C_data_r[31:24];
            res_info_reg1.ser_FOOD2 <= inf.C_data_r[23:16];
            res_info_reg1.ser_FOOD1 <= inf.C_data_r[15:8];
            res_info_reg1.limit_num_orders <= inf.C_data_r[7:0];
        end
        //else if(action_reg == Take && id_reg == ctm_info_reg.res_ID && !id_flag && (current_state == READ_DRAM || current_state == WAIT_READ)) begin
        else if(action_reg == Take && id_reg == ctm_info_reg.res_ID && !id_flag && current_state == READ_DRAM) begin
            res_info_reg1 <= res_info_reg2;
        end
        else if(current_state == CAL && err_reg == No_Err) begin
            case(action_reg)
            Take: begin
                case(ctm_info_reg.food_ID)
                FOOD1: begin
                    if(ctm_info_reg.ctm_status == VIP) begin //vip
                        if(d_man_info_reg1.ctm_info1.ctm_status == VIP && d_man_info_reg1.ctm_info2.ctm_status == None) begin
                            d_man_info_reg1.ctm_info2 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD1 <= res_info_reg1.ser_FOOD1 - ctm_info_reg.ser_food;
                        end
                        else if(d_man_info_reg1.ctm_info1.ctm_status == Normal && d_man_info_reg1.ctm_info2.ctm_status == None) begin
                            d_man_info_reg1.ctm_info2 <= d_man_info_reg1.ctm_info1;
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD1 <= res_info_reg1.ser_FOOD1 - ctm_info_reg.ser_food;
                        end
                        else begin
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD1 <= res_info_reg1.ser_FOOD1 - ctm_info_reg.ser_food;
                        end
                    end
                    else begin //normal
                        if(d_man_info_reg1.ctm_info1.ctm_status != None) begin
                            d_man_info_reg1.ctm_info2 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD1 <= res_info_reg1.ser_FOOD1 - ctm_info_reg.ser_food;
                        end
                        else begin
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD1 <= res_info_reg1.ser_FOOD1 - ctm_info_reg.ser_food;
                        end
                    end
                end
                FOOD2: begin
                    if(ctm_info_reg.ctm_status == VIP) begin //vip
                        if(d_man_info_reg1.ctm_info1.ctm_status == VIP && d_man_info_reg1.ctm_info2.ctm_status == None) begin
                            d_man_info_reg1.ctm_info2 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD2 <= res_info_reg1.ser_FOOD2 - ctm_info_reg.ser_food;
                        end
                        else if(d_man_info_reg1.ctm_info1.ctm_status == Normal && d_man_info_reg1.ctm_info2.ctm_status == None) begin
                            d_man_info_reg1.ctm_info2 <= d_man_info_reg1.ctm_info1;
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD2 <= res_info_reg1.ser_FOOD2 - ctm_info_reg.ser_food;
                        end
                        else begin
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD2 <= res_info_reg1.ser_FOOD2 - ctm_info_reg.ser_food;
                        end
                    end
                    else begin //normal
                        if(d_man_info_reg1.ctm_info1.ctm_status != None) begin
                            d_man_info_reg1.ctm_info2 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD2 <= res_info_reg1.ser_FOOD2 - ctm_info_reg.ser_food;
                        end
                        else begin
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD2 <= res_info_reg1.ser_FOOD2 - ctm_info_reg.ser_food;
                        end
                    end
                end
                FOOD3: begin
                    if(ctm_info_reg.ctm_status == VIP) begin //vip
                        if(d_man_info_reg1.ctm_info1.ctm_status == VIP && d_man_info_reg1.ctm_info2.ctm_status == None) begin
                            d_man_info_reg1.ctm_info2 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD3 <= res_info_reg1.ser_FOOD3 - ctm_info_reg.ser_food;
                        end
                        else if(d_man_info_reg1.ctm_info1.ctm_status == Normal && d_man_info_reg1.ctm_info2.ctm_status == None) begin
                            d_man_info_reg1.ctm_info2 <= d_man_info_reg1.ctm_info1;
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD3 <= res_info_reg1.ser_FOOD3 - ctm_info_reg.ser_food;
                        end
                        else begin
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD3 <= res_info_reg1.ser_FOOD3 - ctm_info_reg.ser_food;
                        end
                    end
                    else begin //normal
                        if(d_man_info_reg1.ctm_info1.ctm_status != None) begin
                            d_man_info_reg1.ctm_info2 <= ctm_info_reg;
                            //res_info_reg1.ser_FOOD3 <= res_info_reg1.ser_FOOD3 - ctm_info_reg.ser_food;
                        end
                        else begin
                            d_man_info_reg1.ctm_info1 <= ctm_info_reg;
                            d_man_info_reg1.ctm_info2 <= d_man_info_reg1.ctm_info2;
                            //res_info_reg1.ser_FOOD3 <= res_info_reg1.ser_FOOD3 - ctm_info_reg.ser_food;
                        end
                    end
                end
                endcase
            end
            Deliver: begin
                d_man_info_reg1.ctm_info1 <= d_man_info_reg1.ctm_info2;
                d_man_info_reg1.ctm_info2 <= 0;
            end
            Order: begin
                case(food_reg.d_food_ID)
                FOOD1: res_info_reg1.ser_FOOD1 <= res_info_reg1.ser_FOOD1 + food_reg.d_ser_food;
                FOOD2: res_info_reg1.ser_FOOD2 <= res_info_reg1.ser_FOOD2 + food_reg.d_ser_food;
                FOOD3: res_info_reg1.ser_FOOD3 <= res_info_reg1.ser_FOOD3 + food_reg.d_ser_food;
                endcase
            end
            Cancel: begin
                if(d_man_info_reg1.ctm_info1.ctm_status != None && d_man_info_reg1.ctm_info2.ctm_status != None) begin
                    if(d_man_info_reg1.ctm_info1.res_ID == res_reg && d_man_info_reg1.ctm_info1.food_ID == food_reg.d_food_ID && d_man_info_reg1.ctm_info2.res_ID == res_reg && d_man_info_reg1.ctm_info2.food_ID == food_reg.d_food_ID) begin
                        //cancel both
                        d_man_info_reg1 <= 0;
                    end
                    else if(d_man_info_reg1.ctm_info1.res_ID == res_reg && d_man_info_reg1.ctm_info1.food_ID == food_reg.d_food_ID) begin
                        //cancel customer 1
                        d_man_info_reg1.ctm_info1 <= d_man_info_reg1.ctm_info2;
                        d_man_info_reg1.ctm_info2 <= 0;
                    end
                    else if(d_man_info_reg1.ctm_info2.res_ID == res_reg && d_man_info_reg1.ctm_info2.food_ID == food_reg.d_food_ID) begin
                        //cancel customer 2
                        d_man_info_reg1.ctm_info1 <= d_man_info_reg1.ctm_info1;
                        d_man_info_reg1.ctm_info2 <= 0;
                    end
                end
                else if(d_man_info_reg1.ctm_info1.ctm_status != None && d_man_info_reg1.ctm_info1.res_ID == res_reg && d_man_info_reg1.ctm_info1.food_ID == food_reg.d_food_ID) begin
                        //cancel customer 1
                        // d_man_info_reg1.ctm_info1 <= 0;
                        // d_man_info_reg1.ctm_info2 <= 0;
                        d_man_info_reg1 <= 0;
                end
                else if(d_man_info_reg1.ctm_info2.ctm_status != None && d_man_info_reg1.ctm_info2.res_ID == res_reg && d_man_info_reg1.ctm_info2.food_ID == food_reg.d_food_ID) begin
                        //cancel customer 2
                        // d_man_info_reg1.ctm_info1 <= 0;
                        // d_man_info_reg1.ctm_info2 <= 0;
                        d_man_info_reg1 <= 0;
                end
            end
            endcase
        end
    end
end

//second reg
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        d_man_info_reg2 <= 0;
        res_info_reg2 <= 0;
    end
    else begin
        if(action_reg == Take) begin
            if(id_reg == ctm_info_reg.res_ID && (current_state == READ_DRAM || current_state == WAIT_READ)) begin
                if(inf.C_out_valid && inf.C_r_wb) begin
                    //{d_man_info_reg2.ctm_info2[7:0], d_man_info_reg2.ctm_info2[15:8]} <= inf.C_data_r[63:48];
                    //{d_man_info_reg2.ctm_info1[7:0], d_man_info_reg2.ctm_info1[15:8]} <= inf.C_data_r[47:32];
                    res_info_reg2.ser_FOOD3 <= inf.C_data_r[31:24];
                    res_info_reg2.ser_FOOD2 <= inf.C_data_r[23:16];
                    res_info_reg2.ser_FOOD1 <= inf.C_data_r[15:8];
                    res_info_reg2.limit_num_orders <= inf.C_data_r[7:0];
                end
            end
            else if(id_reg != ctm_info_reg.res_ID && !id_flag && (current_state == READ_DRAM || current_state == WAIT_READ)) begin
                if(inf.C_out_valid && inf.C_r_wb) begin
                    {d_man_info_reg2.ctm_info2[7:0], d_man_info_reg2.ctm_info2[15:8]} <= inf.C_data_r[63:48];
                    {d_man_info_reg2.ctm_info1[7:0], d_man_info_reg2.ctm_info1[15:8]} <= inf.C_data_r[47:32];
                    res_info_reg2.ser_FOOD3 <= inf.C_data_r[31:24];
                    res_info_reg2.ser_FOOD2 <= inf.C_data_r[23:16];
                    res_info_reg2.ser_FOOD1 <= inf.C_data_r[15:8];
                    res_info_reg2.limit_num_orders <= inf.C_data_r[7:0];  
                end
            end
            else if(current_state == CAL && err_reg == No_Err) begin
                case(ctm_info_reg.food_ID)
                FOOD1: res_info_reg2.ser_FOOD1 <= res_info_reg2.ser_FOOD1 - ctm_info_reg.ser_food;
                FOOD2: res_info_reg2.ser_FOOD2 <= res_info_reg2.ser_FOOD2 - ctm_info_reg.ser_food;
                FOOD3: res_info_reg2.ser_FOOD3 <= res_info_reg2.ser_FOOD3 - ctm_info_reg.ser_food;
                endcase
            end
        end
        
        // else begin
        //     d_man_info_reg2 <= 0;
        //     res_info_reg2 <= 0;
        // end
    end
end

//===========================================================================
// err
//===========================================================================
//err_reg
always_comb begin
    case(action_reg)
    Take: begin
        if(d_man_info_reg1.ctm_info1.ctm_status != None && d_man_info_reg1.ctm_info2.ctm_status != None) begin
            err_reg = D_man_busy;
        end
        else if(ctm_info_reg.food_ID == FOOD1 && ctm_info_reg.ser_food > res_info_reg2.ser_FOOD1) begin
            err_reg = No_Food;
        end
        else if(ctm_info_reg.food_ID == FOOD2 && ctm_info_reg.ser_food > res_info_reg2.ser_FOOD2) begin
            err_reg = No_Food;
        end
        else if(ctm_info_reg.food_ID == FOOD3 && ctm_info_reg.ser_food > res_info_reg2.ser_FOOD3) begin
            err_reg = No_Food;
        end
        else begin
            err_reg = No_Err;
        end
    end
    Deliver: begin
        if(d_man_info_reg1.ctm_info1.ctm_status == None) begin
            err_reg = No_customers;
        end
        else begin
            err_reg = No_Err;
        end
    end
    Order: begin
        //if(res_info_reg1.ser_FOOD1 + res_info_reg1.ser_FOOD2 + res_info_reg1.ser_FOOD3 + food_reg.d_ser_food > res_info_reg1.limit_num_orders) begin
        if(res_info_reg1.limit_num_orders - res_info_reg1.ser_FOOD1 - res_info_reg1.ser_FOOD2 - res_info_reg1.ser_FOOD3 < food_reg.d_ser_food) begin
            err_reg = Res_busy;
        end
        else begin
            err_reg = No_Err;
        end
    end
    Cancel: begin
        if(d_man_info_reg1.ctm_info1.ctm_status == None && d_man_info_reg1.ctm_info2.ctm_status == None) begin
            err_reg = Wrong_cancel;
        end
        //Wrong_res_ID
        else if(d_man_info_reg1.ctm_info1.res_ID != res_reg && d_man_info_reg1.ctm_info2.res_ID != res_reg) begin
            err_reg = Wrong_res_ID;
        end
        else if(d_man_info_reg1.ctm_info1.ctm_status != None && d_man_info_reg1.ctm_info2.ctm_status == None && d_man_info_reg1.ctm_info1.res_ID != res_reg) begin //corner case
            err_reg = Wrong_res_ID;
        end
        else if(d_man_info_reg1.ctm_info1.ctm_status == None && d_man_info_reg1.ctm_info2.ctm_status != None && d_man_info_reg1.ctm_info2.res_ID != res_reg) begin //corner case
            err_reg = Wrong_res_ID;
        end
        //Wrong_food_ID
        else if(d_man_info_reg1.ctm_info1.res_ID == res_reg && d_man_info_reg1.ctm_info2.res_ID == res_reg) begin
            if(d_man_info_reg1.ctm_info1.food_ID != food_reg.d_food_ID && d_man_info_reg1.ctm_info2.food_ID != food_reg.d_food_ID) begin
                err_reg = Wrong_food_ID;
            end
            else begin
                err_reg = No_Err;
            end
        end
        else if((d_man_info_reg1.ctm_info1.res_ID == res_reg && d_man_info_reg1.ctm_info1.food_ID != food_reg.d_food_ID) || (d_man_info_reg1.ctm_info2.res_ID == res_reg && d_man_info_reg1.ctm_info2.food_ID != food_reg.d_food_ID)) begin
            err_reg = Wrong_food_ID;
        end
        // else if(d_man_info_reg1.ctm_info1.food_ID != food_reg.d_food_ID && d_man_info_reg1.ctm_info2.food_ID != food_reg.d_food_ID) begin
        //     err_reg = Wrong_food_ID;
        // end
        else begin
            err_reg = No_Err;
        end
    end
    default: err_reg = No_Err;
    endcase
end

//===========================================================================
// dram output 
//===========================================================================
//C_in_valid
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_in_valid <= 0;
    end
    else begin
        if(current_state == READ_DRAM && inf.C_in_valid) begin
            inf.C_in_valid <= 0;
        end
        else if(current_state == READ_DRAM) begin
            case(action_reg)
            Take: begin
                if((inf.id_valid || inf.cus_valid)) begin
                    inf.C_in_valid <= 1;
                end
                else if(take_flag) begin
                    inf.C_in_valid <= 1;
                end
            end
            Deliver, Cancel: begin
                if(inf.id_valid) begin
                    inf.C_in_valid <= 1;
                end
            end
            Order: begin
                if(inf.res_valid) begin
                    inf.C_in_valid <= 1;
                end
            end
            endcase

        end
        else if(next_state == WRITE_DRAM && inf.C_in_valid) begin
            inf.C_in_valid <= 0;
        end
        else if(next_state == WRITE_DRAM /*&& err_reg == No_Err*/) begin
            case(action_reg)
            Take: begin
                if(take_flag == 1) begin
                    inf.C_in_valid <= 1;
                end
                else if(take_flag == 2) begin
                    inf.C_in_valid <= 1;
                end
            end
            Deliver, Order, Cancel: inf.C_in_valid <= 1;
            endcase

        end
        else begin
            inf.C_in_valid <= 0;
        end
    end
end

//C_r_wb
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_r_wb <= 0;
    end
    else begin
        if(next_state == READ_DRAM) begin
            inf.C_r_wb <= 1; //1 for read
        end
        else if(next_state == WRITE_DRAM || next_state == WAIT_WRITE) begin
            inf.C_r_wb <= 0; //0 for write
        end
        else begin
            inf.C_r_wb <= 1;
        end
    end
end

//C_addr
always_comb begin
    if(current_state == READ_DRAM) begin
        // if(id_flag) begin
        //     inf.C_addr = id_reg;
        // end
        // else if(res_flag) begin
        //     inf.C_addr = res_reg;
        // end
        // else begin
        //     inf.C_addr = 0;
        // end
        case(action_reg)
        Take: begin
            if(id_reg == ctm_info_reg.res_ID) begin
                inf.C_addr = id_reg;
            end
            else begin
                case(take_flag)
                0: inf.C_addr = id_reg;
                1: inf.C_addr = ctm_info_reg.res_ID;
                default: inf.C_addr = 0;
                endcase
            end
        end
        Deliver, Cancel: inf.C_addr = id_reg;
        Order: inf.C_addr = res_reg;
        default: inf.C_addr = 0;
        endcase
    end
    else if(current_state == WRITE_DRAM) begin
        // if(id_flag) begin
        //     inf.C_addr = id_reg;
        // end
        // else if(res_flag) begin
        //     inf.C_addr = res_reg;
        // end
        // else begin
        //     inf.C_addr = 0;
        // end
        case(action_reg)
        Take: begin
            if(id_reg == ctm_info_reg.res_ID) begin
                inf.C_addr = id_reg;
            end
            else begin
                case(take_flag)
                2: inf.C_addr = id_reg;
                1: inf.C_addr = ctm_info_reg.res_ID;
                default: inf.C_addr = 0;
                endcase
            end
        end
        Deliver, Cancel: inf.C_addr = id_reg;
        Order: inf.C_addr = res_reg;
        default: inf.C_addr = 0;
        endcase
    end
    else begin
        inf.C_addr = 0;
    end
end

//C_data_w
always_comb begin
    if(action_reg != Take) begin
        inf.C_data_w[63:48] = {d_man_info_reg1.ctm_info2[7:0], d_man_info_reg1.ctm_info2[15:8]};
        inf.C_data_w[47:32] = {d_man_info_reg1.ctm_info1[7:0], d_man_info_reg1.ctm_info1[15:8]};
        inf.C_data_w[31:24] = res_info_reg1.ser_FOOD3;
        inf.C_data_w[23:16] = res_info_reg1.ser_FOOD2;
        inf.C_data_w[15:8] = res_info_reg1.ser_FOOD1;
        inf.C_data_w[7:0] = res_info_reg1.limit_num_orders;
    end
    else begin //take
        if(id_reg == ctm_info_reg.res_ID) begin //same id
            inf.C_data_w[63:48] = {d_man_info_reg1.ctm_info2[7:0], d_man_info_reg1.ctm_info2[15:8]};
            inf.C_data_w[47:32] = {d_man_info_reg1.ctm_info1[7:0], d_man_info_reg1.ctm_info1[15:8]};
            inf.C_data_w[31:24] = res_info_reg2.ser_FOOD3;
            inf.C_data_w[23:16] = res_info_reg2.ser_FOOD2;
            inf.C_data_w[15:8] = res_info_reg2.ser_FOOD1;
            inf.C_data_w[7:0] = res_info_reg2.limit_num_orders;
        end
        else begin
            if(take_flag == 2) begin //first write
                inf.C_data_w[63:48] = {d_man_info_reg1.ctm_info2[7:0], d_man_info_reg1.ctm_info2[15:8]};
                inf.C_data_w[47:32] = {d_man_info_reg1.ctm_info1[7:0], d_man_info_reg1.ctm_info1[15:8]};
                inf.C_data_w[31:24] = res_info_reg1.ser_FOOD3;
                inf.C_data_w[23:16] = res_info_reg1.ser_FOOD2;
                inf.C_data_w[15:8] = res_info_reg1.ser_FOOD1;
                inf.C_data_w[7:0] = res_info_reg1.limit_num_orders;
            end
            else if(take_flag == 1) begin //second write
                inf.C_data_w[63:48] = {d_man_info_reg2.ctm_info2[7:0], d_man_info_reg2.ctm_info2[15:8]};
                inf.C_data_w[47:32] = {d_man_info_reg2.ctm_info1[7:0], d_man_info_reg2.ctm_info1[15:8]};
                inf.C_data_w[31:24] = res_info_reg2.ser_FOOD3;
                inf.C_data_w[23:16] = res_info_reg2.ser_FOOD2;
                inf.C_data_w[15:8] = res_info_reg2.ser_FOOD1;
                inf.C_data_w[7:0] = res_info_reg2.limit_num_orders;   
            end
            else begin
                inf.C_data_w = 0;
            end
        end
    end
end

//===========================================================================
// output 
//===========================================================================
//out_valid
always_comb begin
    if(current_state == OUTPUT) begin
        inf.out_valid = 1;
    end
    else begin
        inf.out_valid = 0;
    end
end

//out_info
always_comb begin
    if(inf.out_valid && inf.complete) begin
        case(action_reg)
        Take:            inf.out_info = {d_man_info_reg1, res_info_reg2};
        Deliver, Cancel: inf.out_info = {d_man_info_reg1, 32'd0};
        Order:           inf.out_info = {32'd0, res_info_reg1};
        default:         inf.out_info = 0;
        endcase
    end
    else begin
        inf.out_info = 0;
    end
end

//complete
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.complete <= 0;
    end
    else begin
        if(current_state == CAL) begin
            if(err_reg == No_Err) begin
                inf.complete <= 1;
            end
            else begin
                inf.complete <= 0;
            end
        end
        else begin
            inf.complete <= 1;
        end
    end
end

//err_msg
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.err_msg <= No_Err;
    end
    else begin
        if(current_state == CAL) begin
            inf.err_msg <= err_reg;
        end
        else begin
            inf.err_msg <= No_Err;
        end
    end
end


// logic debug;
// //debug
// always_comb begin
//     if(inf.C_addr == 'd163) begin
//         debug = 1;
//     end
//     else begin
//         debug = 0;
//     end
// end

// logic [20:0] act_count;
// always_ff@(posedge clk or negedge inf.rst_n) begin
//     if(!inf.rst_n) begin
//         act_count <= 0;
//     end 
//     else begin
//         if(inf.act_valid) begin
//             act_count <= act_count + 1;
//         end
//     end
// end

endmodule