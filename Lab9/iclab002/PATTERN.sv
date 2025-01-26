`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PATNUM = 10000;
parameter BASE = 65536;



//================================================================
// wire & registers
//================================================================
logic [7:0] golden_DRAM[((BASE+256*8)-1):BASE+0];
integer i;
integer p;
integer gg;
integer pat_count;
integer latency;
integer total_latency;


//================================================================
// class random
//================================================================
class random_deliver_id;
    randc logic [7:0] del_id;
    constraint range{
        del_id inside{[0:255]}; //256 men
    }
endclass

class random_action;
    randc Action action;
    constraint range{
        action inside{Take, Deliver, Order, Cancel};
    }
endclass

class random_restaurant_id;
    randc logic [7:0] res_id;
    constraint range{
        res_id inside{[0:255]}; //256 restaurants
        //base on the random restaurant id, find restaurant info in DRAM
    }
endclass

class random_customer_status;
    randc Customer_status cus_status;
    constraint range{
        cus_status inside{Normal, VIP};
    }
endclass

class random_food_id;
    randc Food_id f_id;
    constraint range{
        f_id inside{FOOD1, FOOD2, FOOD3};
    }
endclass

//generate gap
class random_gap;
    rand logic [2:0] gap;
    constraint range{
        gap inside{[1:5]};
    }
endclass

class random_servings_of_foods;
    randc logic [3:0] serving;
    constraint range{
        serving inside{[0:15]};
    }
endclass

//for if needed condition: Take->same delivery man, Order->same restaurant ID
class random_take_order;
    rand logic if_needed;
    constraint range{
        if_needed inside{[0:1]};
    }
endclass

//================================================================
// golden
//================================================================
Ctm_Info golden_ctm_info;
D_man_Info golden_d_man_info;
res_info golden_res_info;
food_ID_servings golden_food_id_servings;
Error_Msg golden_error_msg;
Action golden_action;
Action previous_action;
Customer_status golden_customer_status;
Food_id golden_food_id;
logic [7:0] golden_del_id;
logic [7:0] golden_res_id;
logic [3:0] golden_serving;
logic golden_complete;
logic [63:0] golden_out_info;

random_deliver_id r_del_id = new();
random_action r_action = new();
random_restaurant_id r_res_id = new();
random_customer_status r_cus_status = new();
random_food_id r_food_id = new();
random_gap r_gap = new();
random_servings_of_foods r_serving = new();
random_take_order r_if_needed = new();

//================================================================
// initial
//================================================================
initial begin
    $readmemh(DRAM_p_r, golden_DRAM);

    reset_task;
    @(negedge clk);
    delay_task;
    for(pat_count = 0; pat_count < PATNUM; pat_count = pat_count + 1) begin
        r_action.randomize();
        golden_action = r_action.action;
        //previous_action = golden_action; //record last action
        golden_error_msg = No_Err;
        golden_out_info = 0;

        case(golden_action)
        Take: take_task;
        Deliver: deliver_task;
        Order: order_task;
        Cancel: cancel_task;
        endcase

        previous_action = golden_action; //record last action
        wait_out_valid_task;
        check_answer_task;
        check_out_valid_task;

        total_latency = total_latency + latency;
        $display("\033[0;34mPASS PATTERN NO.%5d, \033[m \033[0;32m Cycles: %2d\033[m, action = %s", pat_count, latency, golden_action.name());
        delay_task;
    end

    YOU_PASS_task;
    $finish;
end

//================================================================
// function
//================================================================
//read delivery man info from dram
function D_man_Info read_del_man_info(Delivery_man_id id);
    D_man_Info temp;
    temp.ctm_info1 = {golden_DRAM[BASE + id * 8 + 4], golden_DRAM[BASE + id * 8 + 4 + 1]};
    temp.ctm_info2 = {golden_DRAM[BASE + id * 8 + 4 + 2], golden_DRAM[BASE + id * 8 + 4 + 3]};
    return temp;
endfunction

//read restaurant info from dram
function res_info read_res_info(Restaurant_id id);
    res_info temp;
    temp.limit_num_orders = golden_DRAM[BASE + id * 8];
    temp.ser_FOOD1 = golden_DRAM[BASE + id * 8 + 1];
    temp.ser_FOOD2 = golden_DRAM[BASE + id * 8 + 2];
    temp.ser_FOOD3 = golden_DRAM[BASE + id * 8 + 3];
    return temp;
endfunction

//write new delivery man info to dram
function void write_del_man_info(Delivery_man_id id, D_man_Info new_info);
    {golden_DRAM[BASE + id * 8 + 4], golden_DRAM[BASE + id * 8 + 4 + 1]} = new_info.ctm_info1;
    {golden_DRAM[BASE + id * 8 + 4 + 2], golden_DRAM[BASE + id * 8 + 4 + 3]} = new_info.ctm_info2;
endfunction

//write new restaurant info to dram
function void write_res_info(Restaurant_id id, res_info new_info);
    golden_DRAM[BASE + id * 8] = new_info.limit_num_orders; //limit won't change
    golden_DRAM[BASE + id * 8 + 1] = new_info.ser_FOOD1;
    golden_DRAM[BASE + id * 8 + 2] = new_info.ser_FOOD2;
    golden_DRAM[BASE + id * 8 + 3] = new_info.ser_FOOD3;
endfunction

//================================================================
// task
//================================================================
//reset task
task reset_task;
begin
    #(2);
    inf.rst_n = 0;
    inf.id_valid = 'd0;
    inf.act_valid = 'd0;
    inf.cus_valid = 'd0;
    inf.res_valid = 'd0;
    inf.food_valid = 'd0;
    inf.D = 'dx;
    total_latency = 0;
    previous_action = No_action;
    #(5);

    if(inf.err_msg !== 0 || inf.complete !== 0 || inf.out_valid !== 0 || inf.out_info !== 0) begin
        $display("************************************************************");
        $display("*                            FAIL!                         *");
        $display("*   Output signal should be 0 after initial RESET at %t    *", $time);
        $display("************************************************************");
        fail_task;
    end

    #(5);
    inf.rst_n = 1;
end
endtask

//delay_task
task delay_task;
begin
    gg = $urandom_range(2, 10);
    repeat(gg)@(negedge clk);
end
endtask

//-----------------------------------------------
// generate task
//-----------------------------------------------
//gen_id_task
task gen_id_task;
begin
    r_gap.randomize();
    repeat(r_gap.gap) @(negedge clk);
    inf.id_valid = 'b1;

    r_del_id.randomize();
    golden_del_id = r_del_id.del_id;
    inf.D = golden_del_id;

    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*               out_valid should not overlap with id_valid at  %t        *", $time);
        $display("**************************************************************************");
        fail_task;
    end

    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;
end
endtask

//gen_customer_task
task gen_customer_task;
begin
    r_gap.randomize();
    repeat(r_gap.gap) @(negedge clk);
    inf.cus_valid = 'b1;

    r_cus_status.randomize(); //customer status
    golden_customer_status = r_cus_status.cus_status;
    r_res_id.randomize(); //restaurant id
    golden_res_id = r_res_id.res_id;
    r_food_id.randomize(); //food id
    golden_food_id = r_food_id.f_id;
    r_serving.randomize(); //serving of foods
    golden_serving = r_serving.serving;

    inf.D = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
    golden_ctm_info = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};

    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*               out_valid should not overlap with cus_valid at  %t       *", $time);
        $display("**************************************************************************");
        fail_task;
    end

    @(negedge clk);
    inf.cus_valid = 'd0;
    inf.D = 'dx;
end
endtask

//gen_restaurant_task
task gen_restaurant_task;
begin
    r_gap.randomize();
    repeat(r_gap.gap) @(negedge clk);
    inf.res_valid = 'd1;

    r_res_id.randomize();
    golden_res_id = r_res_id.res_id;
    inf.D = golden_res_id;

    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*            out_valid should not overlap with res_valid at  %t          *", $time);
        $display("**************************************************************************");
        fail_task;
    end

    @(negedge clk);
    inf.res_valid = 'd0;
    inf.D = 'dx;
end
endtask

//gen_food_task
task gen_food_task;
begin
    r_gap.randomize();
    repeat(r_gap.gap) @(negedge clk);
    inf.food_valid = 'd1;

    r_food_id.randomize();
    golden_food_id = r_food_id.f_id;
    r_serving.randomize();
    golden_serving = r_serving.serving;
    inf.D = {golden_food_id, golden_serving};

    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*           out_valid should not overlap with food_valid at  %t          *", $time);
        $display("**************************************************************************");
        fail_task;
    end

    @(negedge clk);
    inf.food_valid = 'd0;
    inf.D = 'dx;
end
endtask

//-----------------------------------------------
// action task
//-----------------------------------------------
//take_task
task take_task;
begin
    //set act_valid
    inf.act_valid = 'd1;
    inf.D = Take;
    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*            out_valid should not overlap with act_valid at  %t          *", $time);
        $display("**************************************************************************");
        fail_task;
    end
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //0: same delivery man
    //1: different delivery man
    r_if_needed.randomize();
    p = r_if_needed.if_needed;
    if(previous_action == Take && p == 0) begin //delivery man can be the same one
        r_gap.randomize();
        repeat(r_gap.gap) @(negedge clk); // no id_valid
        gen_customer_task; //set cus_valid
        golden_res_info = read_res_info(golden_res_id);

        check_take_task;
    end
    else begin //normal case
        gen_id_task; //set id_valid
        gen_customer_task; //set cus_valid
        golden_d_man_info = read_del_man_info(golden_del_id);
        golden_res_info = read_res_info(golden_res_id);

        check_take_task;
    end
end
endtask

//deliver_task
task deliver_task;
begin
    //set act_valid
    inf.act_valid = 'd1;
    inf.D = Deliver;
    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*            out_valid should not overlap with act_valid at  %t          *", $time);
        $display("**************************************************************************");
        fail_task;
    end
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //set id_valid
    gen_id_task;
    golden_d_man_info = read_del_man_info(golden_del_id);
    if(golden_d_man_info.ctm_info1.ctm_status === None) begin //no customer
        golden_error_msg = No_customers;
        golden_out_info = 0;
    end
    else begin
        golden_d_man_info.ctm_info1 = golden_d_man_info.ctm_info2;
        golden_d_man_info.ctm_info2 = 0;
        golden_out_info = {golden_d_man_info, 32'd0};
        golden_error_msg = No_Err;
        write_del_man_info(golden_del_id, golden_d_man_info);
    end
end
endtask

//order_task
task order_task;
begin
    //set act_valid
    inf.act_valid = 'd1;
    inf.D = Order;
    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*            out_valid should not overlap with act_valid at  %t          *", $time);
        $display("**************************************************************************");
        fail_task;
    end
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //0: same restaurant
    //1: different restaurant
    r_if_needed.randomize();
    p = r_if_needed.if_needed;
    if(previous_action == Order && p == 0) begin //if needed
        r_gap.randomize();
        repeat(r_gap.gap) @(negedge clk); // no res_valid
        gen_food_task;
        //read_res_info(golden_res_id);

        check_order_task;
    end
    else begin //normal case
        gen_restaurant_task; //set res_valid
        gen_food_task; //set food_valid
        golden_res_info = read_res_info(golden_res_id);

        check_order_task;
    end
end
endtask

//cancel_task
task cancel_task;
begin
    //set act_valid
    inf.act_valid = 'd1;
    inf.D = Cancel;
    if(inf.out_valid !== 0) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*            out_valid should not overlap with act_valid at  %t          *", $time);
        $display("**************************************************************************");
        fail_task;
    end
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    gen_restaurant_task;
    gen_food_task;
    gen_id_task;
    golden_d_man_info = read_del_man_info(golden_del_id);

    if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
        golden_error_msg = Wrong_cancel;
        golden_out_info = 0;
    end
    else if(golden_d_man_info.ctm_info1.res_ID !== golden_res_id && golden_d_man_info.ctm_info2.res_ID !== golden_res_id) begin
        golden_error_msg = Wrong_res_ID;
        golden_out_info = 0;
    end
    else if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None && golden_d_man_info.ctm_info1.res_ID != golden_res_id) begin
        golden_error_msg = Wrong_res_ID;
        golden_out_info = 0;
    end
    else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None && golden_d_man_info.ctm_info2.res_ID != golden_res_id) begin
        golden_error_msg = Wrong_res_ID;
        golden_out_info = 0;
    end
    else if(golden_d_man_info.ctm_info1.food_ID !== golden_food_id && golden_d_man_info.ctm_info2.food_ID !== golden_food_id) begin
        golden_error_msg = Wrong_food_ID;
        golden_out_info = 0;
    end
    else if((golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID !== golden_food_id) || (golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info2.food_ID !== golden_food_id)) begin
        golden_error_msg = Wrong_food_ID;
        golden_out_info = 0;
    end
    else begin //no error
        if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
            if(golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID === golden_food_id && golden_d_man_info.ctm_info2.food_ID === golden_food_id) begin
                //cancel both
                golden_d_man_info = 0;
                golden_error_msg = No_Err;
                golden_out_info = {golden_d_man_info, 32'd0};
                write_del_man_info(golden_del_id, golden_d_man_info);
            end
            else if(golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID === golden_food_id) begin
                //cancel customer 1
                golden_d_man_info.ctm_info1 = golden_d_man_info.ctm_info2;
                golden_d_man_info.ctm_info2 = 0;
                golden_error_msg = No_Err;
                golden_out_info = {golden_d_man_info, 32'd0};
                write_del_man_info(golden_del_id, golden_d_man_info);
            end
            else if(golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info2.food_ID === golden_food_id) begin
                //cancel customer 2
                golden_d_man_info.ctm_info2 = 0;
                golden_error_msg = No_Err;
                golden_out_info = {golden_d_man_info, 32'd0};
                write_del_man_info(golden_del_id, golden_d_man_info);
            end
        end
        else if(golden_d_man_info.ctm_info1.ctm_status === None || golden_d_man_info.ctm_info2.ctm_status === None) begin //one customer missing
            golden_d_man_info = 0;
            golden_error_msg = No_Err;
            golden_out_info = {golden_d_man_info, 32'd0};
            write_del_man_info(golden_del_id, golden_d_man_info);
        end
    end
end
endtask

//check_take_task
task check_take_task;
begin
    //delivery man busy
    if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
        golden_error_msg = D_man_busy;
        golden_out_info = 0;
    end
    // no food
    else if(golden_food_id == FOOD1 && golden_serving > golden_res_info.ser_FOOD1) begin
        golden_error_msg = No_Food;
        golden_out_info = 0;
    end
    else if(golden_food_id == FOOD2 && golden_serving > golden_res_info.ser_FOOD2) begin
        golden_error_msg = No_Food;
        golden_out_info = 0;
    end
    else if(golden_food_id == FOOD3 && golden_serving > golden_res_info.ser_FOOD3) begin
        golden_error_msg = No_Food;
        golden_out_info = 0;
    end
    else begin //no error
        case(golden_food_id) //serving of food decrease
        FOOD1: begin
            if(golden_customer_status === VIP) begin
                if(golden_d_man_info.ctm_info1.ctm_status === VIP && golden_d_man_info.ctm_info2.ctm_status === None) begin //put at customer 2
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === Normal && golden_d_man_info.ctm_info2.ctm_status === None) begin //switch to customer 1
                    golden_d_man_info.ctm_info2 = golden_d_man_info.ctm_info1;
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else begin //put at customer 1
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
            else begin //golden_customer_status === normal
                if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
        end
        FOOD2: begin
            if(golden_customer_status === VIP) begin
                if(golden_d_man_info.ctm_info1.ctm_status === VIP && golden_d_man_info.ctm_info2.ctm_status === None) begin //put at customer 2
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === Normal && golden_d_man_info.ctm_info2.ctm_status === None) begin //switch to customer 1
                    golden_d_man_info.ctm_info2 = golden_d_man_info.ctm_info1;
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else begin //put at customer 1
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
            else begin //golden_customer_status === normal
                if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
        end
        FOOD3: begin
            if(golden_customer_status === VIP) begin
                if(golden_d_man_info.ctm_info1.ctm_status === VIP && golden_d_man_info.ctm_info2.ctm_status === None) begin //put at customer 2
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === Normal && golden_d_man_info.ctm_info2.ctm_status === None) begin //switch to customer 1
                    golden_d_man_info.ctm_info2 = golden_d_man_info.ctm_info1;
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else begin //put at customer 1
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
            else begin //golden_customer_status === normal
                if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_error_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
        end
        endcase
    end
end
endtask

//check_order_task
task check_order_task;
begin
    if(golden_res_info.ser_FOOD1 + golden_res_info.ser_FOOD2 + golden_res_info.ser_FOOD3 + golden_serving > golden_res_info.limit_num_orders) begin //restaurant busy
        golden_error_msg = Res_busy;
        golden_out_info = 0;
    end
    else begin //no error
        case(golden_food_id)
        FOOD1: begin
            golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 + golden_serving;
            golden_out_info = {32'd0, golden_res_info};
            golden_error_msg = No_Err;
            write_res_info(golden_res_id, golden_res_info);
        end
        FOOD2: begin
            golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 + golden_serving;
            golden_out_info = {32'd0, golden_res_info};
            golden_error_msg = No_Err;
            write_res_info(golden_res_id, golden_res_info);
        end
        FOOD3: begin
            golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 + golden_serving;
            golden_out_info = {32'd0, golden_res_info};
            golden_error_msg = No_Err;
            write_res_info(golden_res_id, golden_res_info);
        end
        endcase
    end
end
endtask

//-----------------------------------------------
// output task
//-----------------------------------------------
//wait_out_valid_task
task wait_out_valid_task;
begin
    latency = 0;
    while(inf.out_valid !== 1) begin
        latency = latency + 1;
        if(latency === 1200) begin
            $display("**************************************************************************");
            $display("*                             FAIL !                                     *");
            $display("* latency should be less than 1200 cycles for each operation. at %t      *", $time);
            $display("**************************************************************************");
            fail_task;
        end
        @(negedge clk);

    end
end
endtask

//check_answer_task
task check_answer_task;
begin

    if(golden_error_msg !== No_Err && golden_error_msg !== inf.err_msg) begin
        $display("**************************************************************************");
        $display("*                             FAIL !                                     *");
        $display("*                    Wrong Error Message at  %t                          *", $time);
        $display("*                    Action: %5s                                         *", golden_action.name());
        $display("*                    Golden: %5s Yours: %5s                              *", golden_error_msg.name(), inf.err_msg.name());
        $display("*                    Golden: %5x Yours: %5x                              *", golden_error_msg, inf.err_msg);
        $display("**************************************************************************");
        fail_task;
    end
    if(golden_error_msg !== No_Err && (inf.out_info !== 0 || inf.complete !== 0)) begin
        $display("**************************************************************************");
        $display("*                             FAIL!                                      *");
        $display("*      When error occurs, out_info and complete should be all zero at %t *", $time);
        $display("**************************************************************************");
        fail_task;
    end
    if(golden_error_msg == No_Err && (inf.complete === 'd0 || inf.err_msg !== No_Err)) begin
        $display("**************************************************************************");
        $display("*                             FAIL!                                      *");
        $display("*                    %s should be No Error at %t                         *", golden_action.name(), $time);
        $display("**************************************************************************");
        fail_task;
    end
    if(golden_error_msg == No_Err && golden_out_info !== inf.out_info) begin
        $display("**************************************************************************");
        $display("*                             FAIL!                                      *");
        $display("*                        Wrong out_info at %t                            *", $time);
        $display("*                        Golden out_info: %8h                            *", golden_out_info);
        $display("*                        Your out_info:   %8h                            *", inf.out_info);
        $display("**************************************************************************");
        fail_task;

    end
    @(negedge clk);

end
endtask

//check_out_valid_task
task check_out_valid_task;
begin
    if(inf.out_valid === 'd1) begin
        //if(out_valid_count > 1) begin
            $display("**************************************************************************");
            $display("*                             FAIL !                                     *");
            $display("*               out_valid should be only 1 cycle at %t                   *", $time);
            $display("**************************************************************************");
            fail_task;
        //end
    end

end
endtask



task YOU_PASS_task;
    $display("                                                             \033[33m`-                                                                            ");
    $display("                                                             /NN.                                                                           ");
    $display("                                                            sMMM+                                                                           ");
    $display(" .``                                                       sMMMMy                                                                           ");
    $display(" oNNmhs+:-`                                               oMMMMMh                                                                           ");
    $display("  /mMMMMMNNd/:-`                                         :+smMMMh                                                                           ");
    $display("   .sNMMMMMN::://:-`                                    .o--:sNMy                                                                           ");
    $display("     -yNMMMM:----::/:-.                                 o:----/mo                                                                           ");
    $display("       -yNMMo--------://:.                             -+------+/                                                                           ");
    $display("         .omd/::--------://:`                          o-------o.                                                                           ");
    $display("           `/+o+//::-------:+:`                       .+-------y                                                                            ");
    $display("              .:+++//::------:+/.---------.`          +:------/+                                                                            ");
    $display("                 `-/+++/::----:/:::::::::::://:-.     o------:s.          \033[37m:::::----.           -::::.          `-:////:-`     `.:////:-.    \033[33m");
    $display("                    `.:///+/------------------:::/:- `o-----:/o          \033[37m.NNNNNNNNNNds-       -NNNNNd`       -smNMMMMMMNy   .smNNMMMMMNh    \033[33m");
    $display("                         :+:----------------------::/:s-----/s.          \033[37m.MMMMo++sdMMMN-     `mMMmMMMs      -NMMMh+///oys  `mMMMdo///oyy    \033[33m");
    $display("                        :/---------------------------:++:--/++           \033[37m.MMMM.   `mMMMy     yMMM:dMMM/     +MMMM:      `  :MMMM+`     `    \033[33m");
    $display("                       :/---///:-----------------------::-/+o`           \033[37m.MMMM.   -NMMMo    +MMMs -NMMm.    .mMMMNdo:.     `dMMMNds/-`      \033[33m");
    $display("                      -+--/dNs-o/------------------------:+o`            \033[37m.MMMMyyyhNMMNy`   -NMMm`  sMMMh     .odNMMMMNd+`   `+dNMMMMNdo.    \033[33m");
    $display("                     .o---yMMdsdo------------------------:s`             \033[37m.MMMMNmmmdho-    `dMMMdooosMMMM+      `./sdNMMMd.    `.:ohNMMMm-   \033[33m");
    $display("                    -yo:--/hmmds:----------------//:------o              \033[37m.MMMM:...`       sMMMMMMMMMMMMMN-  ``     `:MMMM+ ``      -NMMMs   \033[33m");
    $display("                   /yssy----:::-------o+-------/h/-hy:---:+              \033[37m.MMMM.          /MMMN:------hMMMd` +dy+:::/yMMMN- :my+:::/sMMMM/   \033[33m");
    $display("                  :ysssh:------//////++/-------sMdyNMo---o.              \033[37m.MMMM.         .mMMMs       .NMMMs /NMMMMMMMMmh:  -NMMMMMMMMNh/    \033[33m");
    $display("                  ossssh:-------ddddmmmds/:----:hmNNh:---o               \033[37m`::::`         .::::`        -:::: `-:/++++/-.     .:/++++/-.      \033[33m");
    $display("                  /yssyo--------dhhyyhhdmmhy+:---://----+-                                                                                  ");
    $display("                  `yss+---------hoo++oosydms----------::s    `.....-.                                                                       ");
    $display("                   :+-----------y+++++++oho--------:+sssy.://:::://+o.                                                                      ");
    $display("                    //----------y++++++os/--------+yssssy/:--------:/s-                                                                     ");
    $display("             `..:::::s+//:::----+s+++ooo:--------+yssssy:-----------++                                                                      ");
    $display("           `://::------::///+/:--+soo+:----------ssssys/---------:o+s.``                                                                    ");
    $display("          .+:----------------/++/:---------------:sys+----------:o/////////::::-...`                                                        ");
    $display("          o---------------------oo::----------::/+//---------::o+--------------:/ohdhyo/-.``                                                ");
    $display("          o---------------------/s+////:----:://:---------::/+h/------------------:oNMMMMNmhs+:.`                                           ");
    $display("          -+:::::--------------:s+-:::-----------------:://++:s--::------------::://sMMMMMMMMMMNds/`                                        ");
    $display("           .+++/////////////+++s/:------------------:://+++- :+--////::------/ydmNNMMMMMMMMMMMMMMmo`                                        ");
    $display("             ./+oo+++oooo++/:---------------------:///++/-   o--:///////::----sNMMMMMMMMMMMMMMMmo.                                          ");
    $display("                o::::::--------------------------:/+++:`    .o--////////////:--+mMMMMMMMMMMMMmo`                                            ");
    $display("               :+--------------------------------/so.       +:-:////+++++///++//+mMMMMMMMMMmo`                                              ");
    $display("              .s----------------------------------+: ````` `s--////o:.-:/+syddmNMMMMMMMMMmo`                                                ");
    $display("              o:----------------------------------s. :s+/////--//+o-       `-:+shmNNMMMNs.                                                  ");
    $display("             //-----------------------------------s` .s///:---:/+o.               `-/+o.                                                    ");
    $display("            .o------------------------------------o.  y///+//:/+o`                                                                          ");
    $display("            o-------------------------------------:/  o+//s//+++`                                                                           ");
    $display("           //--------------------------------------s+/o+//s`                                                                                ");
    $display("          -+---------------------------------------:y++///s                                                                                 ");
    $display("          o-----------------------------------------oo/+++o                                                                                 ");
    $display("         `s-----------------------------------------:s   ``                                                                                 ");
    $display("          o-:::::------------------:::::-------------o.                                                                                     ");
    $display("          .+//////////::::::://///////////////:::----o`                                                                                     ");
    $display("          `:soo+///////////+++oooooo+/////////////:-//                                                                                      ");
    $display("       -/os/--:++/+ooo:::---..:://+ooooo++///////++so-`                                                                                     ");
    $display("      syyooo+o++//::-                 ``-::/yoooo+/:::+s/.                                                                                  ");
    $display("       `..``                                `-::::///:++sys:                                                                                ");
    $display("                                                    `.:::/o+  \033[37m                                                                              ");
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("                 \033[0;38;5;219mTOTAL LATENCY IS: %d\033[m",total_latency);
    $display("********************************************************************");
    $finish;
endtask

task fail_task;
    $display("\033[33m	                                                         .:                                                                                         ");
    $display("                                                   .:                                                                                                 ");
    $display("                                                  --`                                                                                                 ");
    $display("                                                `--`                                                                                                  ");
    $display("                 `-.                            -..        .-//-                                                                                      ");
    $display("                  `.:.`                        -.-     `:+yhddddo.                                                                                    ");
    $display("                    `-:-`             `       .-.`   -ohdddddddddh:                                                                                   ");
    $display("                      `---`       `.://:-.    :`- `:ydddddhhsshdddh-                       \033[31m.yhhhhhhhhhs       /yyyyy`       .yhhy`   +yhyo           \033[33m");
    $display("                        `--.     ./////:-::` `-.--yddddhs+//::/hdddy`                      \033[31m-MMMMNNNNNNh      -NMMMMMs       .MMMM.   sMMMh           \033[33m");
    $display("                          .-..   ////:-..-// :.:oddddho:----:::+dddd+                      \033[31m-MMMM-......     `dMMmhMMM/      .MMMM.   sMMMh           \033[33m");
    $display("                           `-.-` ///::::/::/:/`odddho:-------:::sdddh`                     \033[31m-MMMM.           sMMM/.NMMN.     .MMMM.   sMMMh           \033[33m");
    $display("             `:/+++//:--.``  .--..+----::://o:`osss/-.--------::/dddd/             ..`     \033[31m-MMMMysssss.    /MMMh  oMMMh     .MMMM.   sMMMh           \033[33m");
    $display("             oddddddddddhhhyo///.-/:-::--//+o-`:``````...------::dddds          `.-.`      \033[31m-MMMMMMMMMM-   .NMMN-``.mMMM+    .MMMM.   sMMMh           \033[33m");
    $display("            .ddddhhhhhddddddddddo.//::--:///+/`.````````..``...-:ddddh       `.-.`         \033[31m-MMMM:.....`  `hMMMMmmmmNMMMN-   .MMMM.   sMMMh           \033[33m");
    $display("            /dddd//::///+syhhdy+:-`-/--/////+o```````.-.......``./yddd`   `.--.`           \033[31m-MMMM.        oMMMmhhhhhhdMMMd`  .MMMM.   sMMMh```````    \033[33m");
    $display("            /dddd:/------:://-.`````-/+////+o:`````..``     `.-.``./ym.`..--`              \033[31m-MMMM.       :NMMM:      .NMMMs  .MMMM.   sMMMNmmmmmms    \033[33m");
    $display("            :dddd//--------.`````````.:/+++/.`````.` `.-      `-:.``.o:---`                \033[31m.dddd`       yddds        /dddh. .dddd`   +ddddddddddo    \033[33m");
    $display("            .ddddo/-----..`........`````..```````..  .-o`       `:.`.--/-      ``````````` \033[31m ````        ````          ````   ````     ``````````     \033[33m");
    $display("             ydddh/:---..--.````.`.-.````````````-   `yd:        `:.`...:` `................`                                                         ");
    $display("             :dddds:--..:.     `.:  .-``````````.:    +ys         :-````.:...```````````````..`                                                       ");
    $display("              sdddds:.`/`      ``s.  `-`````````-/.   .sy`      .:.``````-`````..-.-:-.````..`-                                                       ");
    $display("              `ydddd-`.:       `sh+   /:``````````..`` +y`   `.--````````-..---..``.+::-.-``--:                                                       ");
    $display("               .yddh``-.        oys`  /.``````````````.-:.`.-..`..```````/--.`      /:::-:..--`                                                       ");
    $display("                .sdo``:`        .sy. .:``````````````````````````.:```...+.``       -::::-`.`                                                         ");
    $display(" ````.........```.++``-:`        :y:.-``````````````....``.......-.```..::::----.```  ``                                                              ");
    $display("`...````..`....----:.``...````  ``::.``````.-:/+oosssyyy:`.yyh-..`````.:` ````...-----..`                                                             ");
    $display("                 `.+.``````........````.:+syhdddddddddddhoyddh.``````--              `..--.`                                                          ");
    $display("            ``.....--```````.```````.../ddddddhhyyyyyyyhhhddds````.--`             ````   ``                                                          ");
    $display("         `.-..``````-.`````.-.`.../ss/.oddhhyssssooooooossyyd:``.-:.         `-//::/++/:::.`                                                          ");
    $display("       `..```````...-::`````.-....+hddhhhyssoo+++//////++osss.-:-.           /++++o++//s+++/                                                          ");
    $display("     `-.```````-:-....-/-``````````:hddhsso++/////////////+oo+:`             +++::/o:::s+::o            \033[31m     `-/++++:-`                              \033[33m");
    $display("    `:````````./`  `.----:..````````.oysso+///////////////++:::.             :++//+++/+++/+-            \033[31m   :ymMMMMMMMMms-                            \033[33m");
    $display("    :.`-`..```./.`----.`  .----..`````-oo+////////////////o:-.`-.            `+++++++++++/.             \033[31m `yMMMNho++odMMMNo                           \033[33m");
    $display("    ..`:..-.`.-:-::.`        `..-:::::--/+++////////////++:-.```-`            +++++++++o:               \033[31m hMMMm-      /MMMMo  .ssss`/yh+.syyyyyyyyss. \033[33m");
    $display("     `.-::-:..-:-.`                 ```.+::/++//++++++++:..``````:`          -++++++++oo                \033[31m:MMMM:        yMMMN  -MMMMdMNNs-mNNNNNMMMMd` \033[33m");
    $display("        `   `--`                        /``...-::///::-.`````````.: `......` ++++++++oy-                \033[31m+MMMM`        +MMMN` -MMMMh:--. ````:mMMNs`  \033[33m");
    $display("           --`                          /`````````````````````````/-.``````.::-::::::/+                 \033[31m:MMMM:        yMMMm  -MMMM`       `oNMMd:    \033[33m");
    $display("          .`                            :```````````````````````--.`````````..````.``/-                 \033[31m dMMMm:`    `+MMMN/  -MMMN       :dMMNs`     \033[33m");
    $display("                                        :``````````````````````-.``.....````.```-::-.+                  \033[31m `yNMMMdsooymMMMm/   -MMMN     `sMMMMy/////` \033[33m");
    $display("                                        :.````````````````````````-:::-::.`````-:::::+::-.`             \033[31m   -smNMMMMMNNd+`    -NNNN     hNNNNNNNNNNN- \033[33m");
    $display("                                `......../```````````````````````-:/:   `--.```.://.o++++++/.           \033[31m      .:///:-`       `----     ------------` \033[33m");
    $display("                              `:.``````````````````````````````.-:-`      `/````..`+sssso++++:                                                        ");
    $display("                              :`````.---...`````````````````.--:-`         :-````./ysoooss++++.                                                       ");
    $display("                              -.````-:/.`.--:--....````...--:/-`            /-..-+oo+++++o++++.                                                       ");
    $display("             `:++/:.`          -.```.::      `.--:::::://:::::.              -:/o++++++++s++++                                                        ");
    $display("           `-+++++++++////:::/-.:.```.:-.`              :::::-.-`               -+++++++o++++.                                                        ");
    $display("           /++osoooo+++++++++:`````````.-::.             .::::.`-.`              `/oooo+++++.                                                         ");
    $display("           ++oysssosyssssooo/.........---:::               -:::.``.....`     `.:/+++++++++:                                                           ");
    $display("           -+syoooyssssssyo/::/+++++/+::::-`                 -::.``````....../++++++++++:`                                                            ");
    $display("             .:///-....---.-..-.----..`                        `.--.``````````++++++/:.                                                               ");
    $display("                                                                   `........-:+/:-.`                                                            \033[37m      ");
    $finish;
endtask

endprogram