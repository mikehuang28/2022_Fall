//############################################################################
//
// Lab10 PATTERN.v
//
//############################################################################

`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

//PATNUM minimum = 10000;
//parameter PATNUM = 20000;

/*
    Action number:
    0: No action
    1: Take
    2: Deliver
    4: Order
    8: Cancel
    11: Take if needed
    44: Order if needed
*/

//================================================================
// wire & registers
//================================================================
parameter BASE = 65536;
logic [7:0] golden_DRAM[((BASE+256*8)-1):BASE+0];
integer i;
integer p;
integer previous_p;
integer previous_id;
integer previous_res;
integer s;
integer gg;
integer pat_count;
integer latency;
integer total_latency;
integer print_action_num;
integer take_count, deliver_count, order_count, cancel_count;

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
    rand Action action;
    constraint range{
        action inside{Take, Deliver, Order, Cancel};
        //action inside{Order};
    }
endclass

class random_action_coverage;
    randc Action action_coverage;
    constraint range{
        action_coverage inside{Take, Deliver, Cancel};
        //action inside{Order};
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
        serving inside{[1:15]};
    }
endclass

class random_same_id;
    rand logic same;
    constraint range{
        same inside{[0:1]};
    }
endclass

//for if needed condition: Take->same delivery man, Order->same restaurant ID
class random_take_order;
    randc logic if_needed;
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
Error_Msg golden_err_msg;
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
random_same_id r_same = new();
random_action_coverage r_action_coverage = new();

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
// initial
//================================================================
/*
    instead of random test, this lab needs direct test to improve pattern coverage
    thus, random action should be modified
*/
//Action action_test [] = {Take, Deliver, Cancel, Order, Order, Cancel, Take, Take, Order, Deliver, Deliver, Order, Take, Cancel, Cancel, Deliver};
Action action_test [] = {Take, Deliver, Cancel, Order, Cancel, Take, Order, Deliver, Order, Take, Cancel, Deliver};

initial begin
    $readmemh(DRAM_p_r, golden_DRAM);
    reset_task;
    delay_task;
    //for spec 1
    for(pat_count = 0; pat_count < 256; pat_count = pat_count + 1) begin
        // r_action_coverage.randomize();
        // golden_action = r_action_coverage.action_coverage;
        golden_err_msg = No_Err;
        golden_out_info = 0;
        if(pat_count < 50) begin
            // golden_err_msg = No_Err;
            // golden_out_info = 0;
            golden_action = Cancel;
            coverage_cancel_task;
            wait_out_valid_task;
            check_answer_task;
            check_out_valid_task;
            delay_task;
        end
        else if(pat_count < 190) begin
            // golden_err_msg = No_Err;
            // golden_out_info = 0;
            golden_action = Deliver;
            coverage_deliver_task;
            wait_out_valid_task;
            check_answer_task;
            check_out_valid_task;
            delay_task;
        end
        else if(pat_count < 250)begin
            // golden_err_msg = No_Err;
            // golden_out_info = 0;
            golden_action = Take;
            coverage_take_task;
            wait_out_valid_task;
            check_answer_task;
            check_out_valid_task;
            delay_task;
        end
        //no_food
        else if(pat_count == 250) begin
            for(i = 0; i < 3; i = i + 1) begin
                // golden_err_msg = No_Err;
                // golden_out_info = 0;
                golden_action = Take;
                take_no_food_task_3;
                wait_out_valid_task;
                check_answer_task;
                check_out_valid_task;
                delay_task;
            end
        end
        else if(pat_count == 251) begin
            for(i = 0; i < 3; i = i + 1) begin
                // golden_err_msg = No_Err;
                // golden_out_info = 0;
                golden_action = Take;
                take_no_food_task_2;
                wait_out_valid_task;
                check_answer_task;
                check_out_valid_task;
                delay_task;
            end
        end
        else if(pat_count == 252) begin
            for(i = 0; i < 3; i = i + 1) begin
                // golden_err_msg = No_Err;
                // golden_out_info = 0;
                golden_action = Take;
                take_no_food_task_3;
                wait_out_valid_task;
                check_answer_task;
                check_out_valid_task;
                delay_task;
            end
        end
        //wrong_food_id
        else if(pat_count == 253) begin
            for(i = 0; i < 7; i = i + 1) begin
                // golden_err_msg = No_Err;
                // golden_out_info = 0;
                golden_action = Cancel;
                cancel_wrong_food_id_task_3;
                wait_out_valid_task;
                check_answer_task;
                check_out_valid_task;
                delay_task;
            end
        end
        else if(pat_count == 254) begin
            for(i = 0; i < 7; i = i + 1) begin
                // golden_err_msg = No_Err;
                // golden_out_info = 0;
                golden_action = Cancel;
                cancel_wrong_food_id_task_2;
                wait_out_valid_task;
                check_answer_task;
                check_out_valid_task;
                delay_task;
            end
        end
        else /*if(pat_count == 255)*/begin
            for(i = 0; i < 6; i = i + 1) begin
                // golden_err_msg = No_Err;
                // golden_out_info = 0;
                golden_action = Cancel;
                cancel_wrong_food_id_task_1;
                wait_out_valid_task;
                check_answer_task;
                check_out_valid_task;
                delay_task;
            end
        end
    end
    for(pat_count = 0; pat_count < 20; pat_count = pat_count + 1) begin //Res_busy
        golden_err_msg = No_Err;
        golden_out_info = 0;
        golden_action = Order;
        // $display("----------------------------------------------------------------------------------");
        // $display("\033[0;33mTask: %s\033[m",golden_action.name());
        //if(pat_count < 20) begin
        coverage_order_task;
        //end
        // else begin
        //     order_task;
        // end
        wait_out_valid_task;
        check_answer_task;
        check_out_valid_task;
        total_latency = total_latency + latency;
        //$display("\033[0;34mPASS PATTERN NO.%5d, \033[m\033[0;32mCycles: %4d\033[m, \033[0;35mAction = %8s\033[m ", pat_count, latency, golden_action.name());
        delay_task;
    end
    //for spec 2
    for(pat_count = 0; pat_count < action_test.size() * 10; pat_count = pat_count + 1) begin
        // r_action.randomize();
        // golden_action = r_action.action;
        golden_err_msg = No_Err;
        golden_out_info = 0;
        golden_action = action_test[pat_count % action_test.size()];
        //golden_id
        // $display("----------------------------------------------------------------------------------");
        // $display("\033[0;33mTask: %s\033[m",golden_action.name());
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
        // $display("\033[0;34mPASS PATTERN NO.%5d, \033[m\033[0;32mCycles: %2d\033[m, \033[0;38;5;219mAction = %8s\033[m , \033[33mAction Number = %2d\033[37m ", pat_count, latency, golden_action.name(), print_action_num);
        //$display("\033[0;34mPASS PATTERN NO.%5d, \033[m\033[0;32mCycles: %4d\033[m, \033[0;35mAction = %8s\033[m  ", pat_count, latency, golden_action.name());
        delay_task;
    end
    for(pat_count = 0; pat_count < 6; pat_count = pat_count + 1) begin
        golden_err_msg = No_Err;
        golden_out_info = 0;
        golden_action = Take;
        take_task;
        previous_action = golden_action; //record last action
        wait_out_valid_task;
        check_answer_task;
        check_out_valid_task;
        //$display("\033[0;34mPASS PATTERN NO.%5d, \033[m\033[0;32mCycles: %2d\033[m, \033[0;38;5;219mAction = %8s\033[m , \033[33mAction Number = %2d\033[37m ", pat_count, latency, golden_action.name(), print_action_num);
        delay_task;
    end
    for(pat_count = 0; pat_count < 6; pat_count = pat_count + 1) begin
        golden_err_msg = No_Err;
        golden_out_info = 0;
        golden_action = Order;
        order_task;
        previous_action = golden_action; //record last action
        wait_out_valid_task;
        check_answer_task;
        check_out_valid_task;
        //$display("\033[0;34mPASS PATTERN NO.%5d, \033[m\033[0;32mCycles: %2d\033[m, \033[0;38;5;219mAction = %8s\033[m , \033[33mAction Number = %2d\033[37m ", pat_count, latency, golden_action.name(), print_action_num);
        delay_task;
    end
    YOU_PASS_task;
    $finish;
end

//================================================================
// task
//================================================================
//reset task
task reset_task;
begin
    inf.rst_n = 1;
    #(1);
    inf.rst_n = 0;
    inf.id_valid = 'd0;
    inf.act_valid = 'd0;
    inf.cus_valid = 'd0;
    inf.res_valid = 'd0;
    inf.food_valid = 'd0;
    inf.D = 'dx;
    total_latency = 0;
    previous_action = No_action;

    #(1);

    // if(inf.err_msg !== 0 || inf.complete !== 0 || inf.out_valid !== 0 || inf.out_info !== 0) begin
    //     $display("************************************************************");
    //     $display("*                            FAIL!                         *");
    //     $display("*   Output signal should be 0 after initial RESET at %t    *", $time);
    //     $display("************************************************************");
    //     fail_task;
    // end

    #(1);
    inf.rst_n = 1;
end
endtask

//delay_task
task delay_task;
begin
    //gg = $urandom_range(2, 10);
    //repeat(12)@(negedge clk);
    @(negedge clk);
end
endtask

//-----------------------------------------------
// special task for coverage
//-----------------------------------------------
//cancel_wrong_food_id_task_1
task cancel_wrong_food_id_task_1;
begin
    //act
    inf.act_valid = 'd1;
    inf.D = Cancel;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;
    //restaurant
    //repeat(6)@(negedge clk);
    @(negedge clk);
    inf.res_valid = 'b1;
    golden_res_id = 'd70;
    inf.D = golden_res_id;
    @(negedge clk);
    inf.res_valid = 'b0;
    inf.D = 'dx;
    //food
    @(negedge clk);
    inf.food_valid = 'b1;
    golden_food_id = FOOD3;
    golden_serving = 'd10;
    inf.D = {golden_food_id, golden_serving};
    @(negedge clk);
    inf.food_valid = 'b0;
    inf.D = 'dx;
    //id
    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = 255;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    check_cancel_task;
end
endtask

//cancel_wrong_food_id_task_2
task cancel_wrong_food_id_task_2;
begin
    //act
    inf.act_valid = 'd1;
    inf.D = Cancel;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;
    //restaurant
    @(negedge clk);
    inf.res_valid = 'b1;
    golden_res_id = 'd171;
    inf.D = golden_res_id;
    @(negedge clk);
    inf.res_valid = 'b0;
    inf.D = 'dx;
    //food
    @(negedge clk);
    inf.food_valid = 'b1;
    golden_food_id = FOOD3;
    golden_serving = 'd10;
    inf.D = {golden_food_id, golden_serving};
    @(negedge clk);
    inf.food_valid = 'b0;
    inf.D = 'dx;
    //id
    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = 254;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    check_cancel_task;
end
endtask

//cancel_wrong_food_id_task_3
task cancel_wrong_food_id_task_3;
begin
    //act
    inf.act_valid = 'd1;
    inf.D = Cancel;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;
    //restaurant
    @(negedge clk);
    inf.res_valid = 'b1;
    golden_res_id = 'd70;
    inf.D = golden_res_id;
    @(negedge clk);
    inf.res_valid = 'b0;
    inf.D = 'dx;
    //food
    @(negedge clk);
    inf.food_valid = 'b1;
    golden_food_id = FOOD3;
    golden_serving = 'd10;
    inf.D = {golden_food_id, golden_serving};
    @(negedge clk);
    inf.food_valid = 'b0;
    inf.D = 'dx;
    //id
    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = 253;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    check_cancel_task;
end
endtask

//coverage_cancel_task
task coverage_cancel_task;
begin
    inf.act_valid = 'd1;
    inf.D = Cancel;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;
    gen_restaurant_task;
    gen_food_task;

    //manually control delivery man id
    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = pat_count;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    check_cancel_task;
end
endtask

//take_no_food_task_1
task take_no_food_task_1;
begin
    inf.act_valid = 'd1;
    inf.D = Take;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = pat_count;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    @(negedge clk);
    inf.cus_valid = 'b1;
    r_cus_status.randomize(); //customer status
    golden_customer_status = r_cus_status.cus_status;
    //r_food_id.randomize(); //food id
    golden_res_id = pat_count;
    golden_food_id = FOOD1;
    golden_serving = 'd15;
    inf.D = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
    @(negedge clk);
    inf.cus_valid = 'd0;
    inf.D = 'dx;

    golden_d_man_info = read_del_man_info(golden_del_id);
    golden_res_info = read_res_info(golden_res_id);
    check_take_task;

end
endtask

//take_no_food_task_2
task take_no_food_task_2;
begin
    inf.act_valid = 'd1;
    inf.D = Take;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = pat_count;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    @(negedge clk);
    inf.cus_valid = 'b1;
    r_cus_status.randomize(); //customer status
    golden_customer_status = r_cus_status.cus_status;
    //r_food_id.randomize(); //food id
    golden_res_id = pat_count;
    golden_food_id = FOOD2;
    golden_serving = 'd15;
    inf.D = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
    @(negedge clk);
    inf.cus_valid = 'd0;
    inf.D = 'dx;

    golden_d_man_info = read_del_man_info(golden_del_id);
    golden_res_info = read_res_info(golden_res_id);
    check_take_task;

end
endtask

//take_no_food_task_3
task take_no_food_task_3;
begin
    inf.act_valid = 'd1;
    inf.D = Take;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = pat_count;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    @(negedge clk);
    inf.cus_valid = 'b1;
    r_cus_status.randomize(); //customer status
    golden_customer_status = r_cus_status.cus_status;
    //r_food_id.randomize(); //food id
    golden_res_id = pat_count;
    golden_food_id = FOOD3;
    golden_serving = 'd15;
    inf.D = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
    @(negedge clk);
    inf.cus_valid = 'd0;
    inf.D = 'dx;

    golden_d_man_info = read_del_man_info(golden_del_id);
    golden_res_info = read_res_info(golden_res_id);
    check_take_task;

end
endtask

//coverage_take_task
task coverage_take_task;
begin
    inf.act_valid = 'd1;
    inf.D = Take;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = pat_count;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;
    //gen_customer_task;
    @(negedge clk);
    inf.cus_valid = 'b1;
    r_cus_status.randomize(); //customer status
    golden_customer_status = r_cus_status.cus_status;
    //r_food_id.randomize(); //food id
    golden_res_id = pat_count;
    golden_food_id = FOOD1;
    golden_serving = 'd15;

    inf.D = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
    @(negedge clk);
    inf.cus_valid = 'd0;
    inf.D = 'dx;

    golden_d_man_info = read_del_man_info(golden_del_id);
    golden_res_info = read_res_info(golden_res_id);
    check_take_task;
end
endtask

//coverage_deliver_task
task coverage_deliver_task;
begin
    //set act_valid
    inf.act_valid = 'd1;
    inf.D = Deliver;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //set id_valid
    //gen_id_task;
    @(negedge clk);
    inf.id_valid = 'b1;
    golden_del_id = pat_count;
    inf.D = golden_del_id;
    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;

    golden_d_man_info = read_del_man_info(golden_del_id);
    if(golden_d_man_info.ctm_info1.ctm_status === None) begin //no customer
        golden_err_msg = No_customers;
        golden_out_info = 0;
    end
    else begin
        golden_d_man_info.ctm_info1 = golden_d_man_info.ctm_info2;
        golden_d_man_info.ctm_info2 = 0;
        golden_out_info = {golden_d_man_info, 32'd0};
        golden_err_msg = No_Err;
        write_del_man_info(golden_del_id, golden_d_man_info);
    end
end
endtask

//coverage_order_task
task coverage_order_task;
begin
    //set act_valid
    inf.act_valid = 'd1;
    inf.D = Order;
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //gen_restaurant_task;
    @(negedge clk);
    inf.res_valid = 'd1;
    golden_res_id = 'd0;
    inf.D = golden_res_id;
    @(negedge clk);
    inf.res_valid = 'd0;
    inf.D = 'dx;
    //manually control food serving
    @(negedge clk);
    inf.food_valid = 'd1;
    r_food_id.randomize();
    golden_food_id = r_food_id.f_id;
    golden_serving = 'd15;
    inf.D = {golden_food_id, golden_serving};
    @(negedge clk);
    inf.food_valid = 'd0;
    inf.D = 'dx;
    golden_res_info = read_res_info(golden_res_id);
    check_order_task;
end
endtask

//-----------------------------------------------
// generate task
//-----------------------------------------------
//gen_id_task
task gen_id_task;
begin
    //r_gap.randomize();
    /*repeat(r_gap.gap)*/ @(negedge clk);
    inf.id_valid = 'b1;

    r_del_id.randomize();
    golden_del_id = r_del_id.del_id;
    inf.D = golden_del_id;

    @(negedge clk);
    inf.id_valid = 'd0;
    inf.D = 'dx;
end
endtask

//gen_customer_task
task gen_customer_task;
begin
    //r_gap.randomize();
    /*repeat(r_gap.gap)*/ @(negedge clk);
    inf.cus_valid = 'b1;

    //determine whether res_id = d_man_id or not
    r_same.randomize();
    s = r_same.same;
    if(s == 0) begin
        golden_res_id = golden_del_id;
    end
    else begin
        r_res_id.randomize(); //restaurant id
        golden_res_id = r_res_id.res_id;
    end

    r_cus_status.randomize(); //customer status
    golden_customer_status = r_cus_status.cus_status;
    r_food_id.randomize(); //food id
    golden_food_id = r_food_id.f_id;
    r_serving.randomize(); //serving of foods
    golden_serving = r_serving.serving;

    inf.D = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
    //golden_ctm_info = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};

    @(negedge clk);
    inf.cus_valid = 'd0;
    inf.D = 'dx;
end
endtask

//gen_restaurant_task
task gen_restaurant_task;
begin
    //r_gap.randomize();
    /*repeat(r_gap.gap)*/ @(negedge clk);
    inf.res_valid = 'd1;

    r_res_id.randomize();
    golden_res_id = r_res_id.res_id;
    inf.D = golden_res_id;

    @(negedge clk);
    inf.res_valid = 'd0;
    inf.D = 'dx;
end
endtask

//gen_food_task
task gen_food_task;
begin
    //r_gap.randomize();
    /*repeat(r_gap.gap)*/ @(negedge clk);
    inf.food_valid = 'd1;

    r_food_id.randomize();
    golden_food_id = r_food_id.f_id;
    r_serving.randomize();
    golden_serving = r_serving.serving;
    inf.D = {golden_food_id, golden_serving};

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
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //0: same delivery man
    //1: different delivery man
    r_if_needed.randomize();
    p = r_if_needed.if_needed;
    if(previous_action == Take && p == 0 /*&& previous_p == 1*/) begin //no id_valid
        previous_p = 0;
        print_action_num = 11;
        @(negedge clk); // no id_valid
        gen_customer_task; //set cus_valid
        golden_d_man_info = read_del_man_info(golden_del_id);
        golden_res_info = read_res_info(golden_res_id);

        check_take_task;
    end
    else begin //normal case
        previous_p = 1;
        print_action_num = 1;
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
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //set id_valid
    print_action_num = 2;
    gen_id_task;
    golden_d_man_info = read_del_man_info(golden_del_id);
    if(golden_d_man_info.ctm_info1.ctm_status === None) begin //no customer
        golden_err_msg = No_customers;
        golden_out_info = 0;
    end
    else begin
        golden_d_man_info.ctm_info1 = golden_d_man_info.ctm_info2;
        golden_d_man_info.ctm_info2 = 0;
        golden_out_info = {golden_d_man_info, 32'd0};
        golden_err_msg = No_Err;
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
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    //0: same restaurant
    //1: different restaurant
    r_if_needed.randomize();
    p = r_if_needed.if_needed;
    if(previous_action == Order && p == 0 /*&& previous_p == 1*/) begin //if needed
        previous_p = 0;
        print_action_num = 44;
        @(negedge clk);
        gen_food_task;
        golden_res_info = read_res_info(golden_res_id);
        check_order_task;
    end
    else begin //normal case
        previous_p = 1;
        print_action_num = 4;
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
    @(negedge clk);
    inf.act_valid = 'd0;
    inf.D = 'dx;

    print_action_num = 8;
    gen_restaurant_task;
    gen_food_task;
    gen_id_task;

    check_cancel_task;
end
endtask

//check_cancel_task
task check_cancel_task;
begin
    golden_d_man_info = read_del_man_info(golden_del_id);
    //Wrong_cancel
    if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
        golden_err_msg = Wrong_cancel;
        golden_out_info = 0;
    end
    //Wrong_res_ID
    else if(golden_d_man_info.ctm_info1.res_ID !== golden_res_id && golden_d_man_info.ctm_info2.res_ID !== golden_res_id) begin
        golden_err_msg = Wrong_res_ID;
        golden_out_info = 0;
    end
    // else if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None && golden_d_man_info.ctm_info1.res_ID != golden_res_id) begin
    //     golden_err_msg = Wrong_res_ID;
    //     golden_out_info = 0;
    // end
    // else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None && golden_d_man_info.ctm_info2.res_ID != golden_res_id) begin
    //     golden_err_msg = Wrong_res_ID;
    //     golden_out_info = 0;
    // end
    //Wrong_food_ID
    else if(golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID !== golden_food_id && golden_d_man_info.ctm_info2.food_ID !== golden_food_id) begin

        golden_err_msg = Wrong_food_ID;
        golden_out_info = 0;

    end
    else if((golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID !== golden_food_id) || (golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info2.food_ID !== golden_food_id)) begin
        if(golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID == golden_food_id /*&& golden_d_man_info.ctm_info1.ctm_status !== None*/) begin
            //cancel customer 1
            golden_d_man_info.ctm_info1 = golden_d_man_info.ctm_info2;
            golden_d_man_info.ctm_info2 = 0;
            golden_err_msg = No_Err;
            golden_out_info = {golden_d_man_info, 32'd0};
            write_del_man_info(golden_del_id, golden_d_man_info);
        end
        else if(golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info2.food_ID == golden_food_id /*&& golden_d_man_info.ctm_info2.ctm_status !== None*/) begin
            //cancel customer 2
            golden_d_man_info.ctm_info2 = 0;
            golden_err_msg = No_Err;
            golden_out_info = {golden_d_man_info, 32'd0};
            write_del_man_info(golden_del_id, golden_d_man_info);
        end
        else begin
            golden_err_msg = Wrong_food_ID;
            golden_out_info = 0;
        end
    end
    else begin //no err
        if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
            if(golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info2.res_ID === golden_res_id) begin
                if(golden_d_man_info.ctm_info1.food_ID === golden_food_id && golden_d_man_info.ctm_info2.food_ID === golden_food_id) begin
                    //cancel both
                    golden_d_man_info.ctm_info1 = 0;
                    golden_d_man_info.ctm_info2 = 0;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, 32'd0};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                end
            end
            else if(golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID === golden_food_id) begin
                //cancel customer 1
                golden_d_man_info.ctm_info1 = golden_d_man_info.ctm_info2;
                golden_d_man_info.ctm_info2 = 0;
                golden_err_msg = No_Err;
                golden_out_info = {golden_d_man_info, 32'd0};
                write_del_man_info(golden_del_id, golden_d_man_info);
            end
            else if(golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info2.food_ID === golden_food_id) begin
                //cancel customer 2
                golden_d_man_info.ctm_info2 = 0;
                golden_err_msg = No_Err;
                golden_out_info = {golden_d_man_info, 32'd0};
                write_del_man_info(golden_del_id, golden_d_man_info);
            end
        end
        else if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info1.res_ID === golden_res_id && golden_d_man_info.ctm_info1.food_ID === golden_food_id) begin
            golden_d_man_info = 0;
            golden_err_msg = No_Err;
            golden_out_info = {golden_d_man_info, 32'd0};
            write_del_man_info(golden_del_id, golden_d_man_info);
        end
        else if(golden_d_man_info.ctm_info2.ctm_status !== None && golden_d_man_info.ctm_info2.res_ID === golden_res_id && golden_d_man_info.ctm_info2.food_ID === golden_food_id) begin
            golden_d_man_info = 0;
            golden_err_msg = No_Err;
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
        golden_err_msg = D_man_busy;
        golden_out_info = 0;
    end
    // no food
    else if(golden_food_id == FOOD1 && golden_serving > golden_res_info.ser_FOOD1) begin
        golden_err_msg = No_Food;
        golden_out_info = 0;
    end
    else if(golden_food_id == FOOD2 && golden_serving > golden_res_info.ser_FOOD2) begin
        golden_err_msg = No_Food;
        golden_out_info = 0;
    end
    else if(golden_food_id == FOOD3 && golden_serving > golden_res_info.ser_FOOD3) begin
        golden_err_msg = No_Food;
        golden_out_info = 0;
    end
    else begin //no err
        case(golden_food_id) //serving of food decrease
        FOOD1: begin
            if(golden_customer_status === VIP) begin
                if(golden_d_man_info.ctm_info1.ctm_status === VIP && golden_d_man_info.ctm_info2.ctm_status === None) begin //put at customer 2
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === Normal && golden_d_man_info.ctm_info2.ctm_status === None) begin //switch to customer 1
                    golden_d_man_info.ctm_info2 = golden_d_man_info.ctm_info1;
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else begin //put at customer 1
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
            else begin //golden_customer_status === normal
                if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 - golden_serving;
                    golden_err_msg = No_Err;
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
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === Normal && golden_d_man_info.ctm_info2.ctm_status === None) begin //switch to customer 1
                    golden_d_man_info.ctm_info2 = golden_d_man_info.ctm_info1;
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else begin //put at customer 1
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
            else begin //golden_customer_status === normal
                if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 - golden_serving;
                    golden_err_msg = No_Err;
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
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === Normal && golden_d_man_info.ctm_info2.ctm_status === None) begin //switch to customer 1
                    golden_d_man_info.ctm_info2 = golden_d_man_info.ctm_info1;
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else begin //put at customer 1
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
            end
            else begin //golden_customer_status === normal
                if(golden_d_man_info.ctm_info1.ctm_status !== None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info2 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status !== None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_err_msg = No_Err;
                    golden_out_info = {golden_d_man_info, golden_res_info};
                    write_del_man_info(golden_del_id, golden_d_man_info);
                    write_res_info(golden_res_id, golden_res_info);
                end
                else if(golden_d_man_info.ctm_info1.ctm_status === None && golden_d_man_info.ctm_info2.ctm_status === None) begin
                    golden_d_man_info.ctm_info1 = {golden_customer_status, golden_res_id, golden_food_id, golden_serving};
                    golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 - golden_serving;
                    golden_err_msg = No_Err;
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
    //restaurant busy
    if(golden_res_info.limit_num_orders - golden_res_info.ser_FOOD1 - golden_res_info.ser_FOOD2 - golden_res_info.ser_FOOD3 < golden_serving) begin
        golden_err_msg = Res_busy;
        golden_out_info = 0;
    end
    else begin //no err
        case(golden_food_id)
        FOOD1: begin
            golden_res_info.ser_FOOD1 = golden_res_info.ser_FOOD1 + golden_serving;
            golden_out_info = {32'd0, golden_res_info};
            golden_err_msg = No_Err;
            write_res_info(golden_res_id, golden_res_info);
        end
        FOOD2: begin
            golden_res_info.ser_FOOD2 = golden_res_info.ser_FOOD2 + golden_serving;
            golden_out_info = {32'd0, golden_res_info};
            golden_err_msg = No_Err;
            write_res_info(golden_res_id, golden_res_info);
        end
        FOOD3: begin
            golden_res_info.ser_FOOD3 = golden_res_info.ser_FOOD3 + golden_serving;
            golden_out_info = {32'd0, golden_res_info};
            golden_err_msg = No_Err;
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
        // if(latency === 1200) begin
        //     $display("**************************************************************************");
        //     $display("*                             FAIL !                                     *");
        //     $display("* latency should be less than 1200 cycles for each operation. at %t      *", $time);
        //     $display("**************************************************************************");
        //     fail_task;
        // end
        @(negedge clk);

    end
end
endtask


//check_answer_task
task check_answer_task;
begin
    while(inf.out_valid === 1) begin
        if(golden_err_msg !== No_Err && golden_err_msg !== inf.err_msg) begin
            // $display("**************************************************************************");
            // $display("*                             FAIL !                                     *");
            // $display("*                    Wrong Err Message at  %t                            *", $time);
            // $display("*                    Action: %5s                                         *", golden_action.name());
            // $display("*                    Golden: %5s Yours: %5s                              *", golden_err_msg.name(), inf.err_msg.name());
            // $display("*                    Golden: %5x Yours: %5x                              *", golden_err_msg, inf.err_msg);
            // $display("**************************************************************************");
            fail_task;
        end
        if(golden_err_msg !== No_Err && (inf.out_info !== 'd0 || inf.complete !== 'd0)) begin
            // $display("**************************************************************************");
            // $display("*                             FAIL!                                      *");
            // $display("*      When err occurs, out_info and complete should be all zero at %t   *", $time);
            // $display("**************************************************************************");
            fail_task;
        end
        if(golden_err_msg == No_Err && (inf.complete === 'd0 || inf.err_msg !== No_Err)) begin
            // $display("**************************************************************************");
            // $display("*                             FAIL!                                      *");
            // $display("*                    %s should be No Err at %t                           *", golden_action.name(), $time);
            // $display("**************************************************************************");
            fail_task;
        end
        if(golden_err_msg == No_Err && golden_out_info !== inf.out_info) begin
            // $display("**************************************************************************");
            // $display("*                             FAIL!                                      *");
            // $display("*                        Wrong out_info at %t                            *", $time);
            // $display("*                        Action: %5s                                     *", golden_action.name());
            // $display("*                        Golden out_info: %8h                            *", golden_out_info);
            // $display("*                        Your out_info:   %8h                            *", inf.out_info);
            // $display("**************************************************************************");
            fail_task;
        end
        @(negedge clk);
    end
end
endtask

//check_out_valid_task
task check_out_valid_task;
begin
    if(inf.out_valid === 'd1) begin
        // $display("**************************************************************************");
        // $display("*                             FAIL!                                      *");
        // $display("*        out_valid should be exactly one cycle.   at %t                  *",$time);
        // $display("*************************************************************************");
        // fail_task;
    end
end
endtask


task YOU_PASS_task;
    // $display("Pass!");
    // $display("**************************************************************************");
    // $display("*                             PASS!                                      *");
    // $display("**************************************************************************");
    // $finish;
endtask

task fail_task;
    $display("Wrong Answer");
    $finish;
endtask

endprogram