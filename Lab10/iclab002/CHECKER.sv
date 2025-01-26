module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//declare other cover group

//spec1
covergroup CG1 @(posedge clk iff inf.id_valid);
    option.per_instance = 1;
    coverpoint inf.D.d_id[0]{
        option.at_least = 1;
        option.auto_bin_max = 256; //0-255
    }
endgroup

//spec2
covergroup CG2 @(posedge clk iff inf.act_valid);
    option.per_instance = 1;
    coverpoint inf.D.d_act[0]{
        option.at_least = 10;
        //transition bins
        bins t_bin [] = (Take, Deliver, Order, Cancel => Take, Deliver, Order, Cancel);
    }
endgroup

//spec 3
covergroup CG3 @(negedge clk iff inf.out_valid);
    option.per_instance = 1;
    coverpoint inf.complete{
        option.at_least = 200;
        option.auto_bin_max = 2; //0,1
    }
endgroup

//spec 4
covergroup CG4 @(negedge clk iff inf.out_valid);
    option.per_instance = 1;
    coverpoint inf.err_msg{
        option.at_least = 20;
        //{D_man_busy, No_Food, No_customers, Res_busy, Wrong_cancel, Wrong_res_ID, Wrong_food_ID}
        bins err_D_man_busy = {D_man_busy};
        bins err_No_Food = {No_Food};
        bins err_No_customers = {No_customers};
        bins err_Res_busy = {Res_busy};
        bins err_Wrong_cancel = {Wrong_cancel};
        bins err_Wrong_res_ID = {Wrong_res_ID};
        bins err_Wrong_food_ID = {Wrong_food_ID};
    }
endgroup

//instance
CG1 cover_instance_1 = new();
CG2 cover_instance_2 = new();
CG3 cover_instance_3 = new();
CG4 cover_instance_4 = new();


//************************************ below assertion is to check your pattern *****************************************
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal;
//  end
wire #(0.5) rst_reg = inf.rst_n;
logic valid_combine;
logic valid_without_act;
Action action_reg;
logic last_valid;
//write other assertions
//====================================================================================================
// Assertion 1 (All outputs signals (including FD.sv and bridge.sv) should be zero after reset.)
//====================================================================================================
assertion_1: assert property (p_reset)
else begin
    $display("Assertion 1 is violated");
    $fatal;
end

property p_reset;
    @(negedge inf.rst_n) inf.rst_n === 1 |=> (@(negedge rst_reg) (inf.out_valid === 0 && inf.err_msg === 0 && inf.out_info === 0 && inf.complete === 0 &&
                          inf.C_addr === 0 && inf.C_data_w === 0 && inf.C_in_valid === 0 && inf.C_r_wb === 0 && //FD output
                          inf.C_out_valid === 0 && inf.C_data_r === 0 && inf.R_READY === 0 && inf.AR_ADDR === 0 && inf.AR_VALID === 0 &&
                          inf.W_VALID === 0 && inf.B_READY === 0 && inf.AW_ADDR === 0 && inf.AW_VALID === 0 && inf.W_DATA === 0 //bridge output
                        ));
endproperty: p_reset

//====================================================================================================
// Assertion 2 (If action is completed, err_msg should be 4’b0.)
//====================================================================================================
assertion_2: assert property (p_err_msg)
else begin
    $display("Assertion 2 is violated");
    $fatal;
end

property p_err_msg;
    @(negedge clk) (inf.out_valid === 1 && inf.complete === 1 |-> inf.err_msg === 4'b0);
endproperty: p_err_msg

//====================================================================================================
// Assertion 3 (If action is not completed, out_info should be 64’b0.)
//====================================================================================================
assertion_3: assert property (p_out_info)
else begin
    $display("Assertion 3 is violated");
    $fatal;
end

property p_out_info;
    @(negedge clk) (inf.out_valid === 1 && inf.complete === 0 |-> inf.out_info === 64'b0);
endproperty: p_out_info

//====================================================================================================
// Assertion 4 (The gap between each input valid is at least 1 cycle and at most 5 cycles.)
//====================================================================================================
assertion_4: assert property (p_gap_min and p_gap_max and p_take_0 and p_order_0 and p_cancel_0 and p_cancel_1)
else begin
    $display("Assertion 4 is violated");
    $fatal;
end

assign valid_combine = inf.act_valid || inf.id_valid || inf.cus_valid || inf.res_valid || inf.food_valid;
assign valid_without_act = inf.id_valid || inf.cus_valid || inf.res_valid || inf.food_valid;

property p_gap_min;
    @(posedge clk) valid_combine === 1 |=> valid_combine === 0;
endproperty: p_gap_min

property p_gap_max;
    @(posedge clk) inf.act_valid === 1 |=> ##[1:5] valid_without_act === 1;
endproperty: p_gap_max

// property p_max;
//     @(posedge clk) valid_without_act === 1 |=> ##[1:5] valid_without_act === 1;
// endproperty: p_max

// property p_gap_take;
//     @(posedge clk) action_reg === Take && (inf.act_valid === 1 || inf.id_valid === 1) |=> ##[1:5] inf.cus_valid === 1;
// endproperty: p_gap_take

// property p_gap_deliver;
//     @(posedge clk) inf.D.d_act[0] === Deliver && inf.act_valid === 1 |=> ##[1:5] inf.id_valid === 1;
// endproperty: p_gap_deliver

// property p_gap_order;
//     @(posedge clk) action_reg === Order && (inf.act_valid === 1 || inf.res_valid === 1) |=> ##[1:5] inf.food_valid === 1;
// endproperty: p_gap_order

// property p_gap_cancel;
//     @(posedge clk) action_reg === Cancel &&  (inf.res_valid === 1 || inf.food_valid === 1) |=> ##[1:5] inf.id_valid === 1;
// endproperty: p_gap_cancel

property p_take_0;
    @(posedge clk) (action_reg === Take && inf.id_valid === 1) |=> ##[1:5] inf.cus_valid === 1;
endproperty: p_take_0

property p_order_0;
    @(posedge clk) (action_reg === Order && inf.res_valid) |=> ##[1:5] inf.food_valid === 1;
endproperty: p_order_0

property p_cancel_0;
    @(posedge clk) (action_reg === Cancel && inf.res_valid) |=> ##[1:5] inf.food_valid === 1;
endproperty: p_cancel_0

property p_cancel_1;
    @(posedge clk) (action_reg === Cancel && inf.food_valid) |=> ##[1:5] inf.id_valid === 1;
endproperty: p_cancel_1


always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        last_valid <= 0;
    end
    else begin
        if(inf.act_valid) begin
            last_valid <= 1;
        end
        else if(action_reg == Take && inf.cus_valid) begin
            last_valid <= 0;
        end
        else if((action_reg == Deliver || action_reg == Cancel) && inf.id_valid) begin
            last_valid <= 0;
        end
        else if(action_reg == Order && inf.food_valid) begin
            last_valid <= 0;
        end
    end
end

//====================================================================================================
// Assertion 5 (All input valid signals won’t overlap with each other.)
//====================================================================================================
assertion_5: assert property (p_act_valid and p_id_valid and p_cus_valid and p_res_valid and p_food_valid)
else begin
    $display("Assertion 5 is violated");
    $fatal;
end

property p_act_valid;
    @(posedge clk) (inf.act_valid === 1 |-> inf.id_valid === 0 && inf.cus_valid === 0 && inf.res_valid === 0 && inf.food_valid === 0);
endproperty: p_act_valid

property p_id_valid;
    @(posedge clk) (inf.id_valid === 1 |-> inf.act_valid === 0 && inf.cus_valid === 0 && inf.res_valid === 0 && inf.food_valid === 0);
endproperty: p_id_valid

property p_cus_valid;
    @(posedge clk) (inf.cus_valid === 1 |-> inf.id_valid === 0 && inf.act_valid === 0 && inf.res_valid === 0 && inf.food_valid === 0);
endproperty: p_cus_valid

property p_res_valid;
    @(posedge clk) (inf.res_valid === 1 |-> inf.id_valid === 0 && inf.cus_valid === 0 && inf.act_valid === 0 && inf.food_valid === 0);
endproperty: p_res_valid

property p_food_valid;
    @(posedge clk) (inf.food_valid === 1 |-> inf.id_valid === 0 && inf.cus_valid === 0 && inf.res_valid === 0 && inf.act_valid === 0);
endproperty: p_food_valid

//====================================================================================================
// Assertion 6 (Out_valid can only be high for exactly one cycle.)
//====================================================================================================
assertion_6: assert property (p_out_valid)
else begin
    $display("Assertion 6 is violated");
    $fatal;
end

property p_out_valid;
    @(negedge clk) (inf.out_valid === 1 |=> inf.out_valid === 0);
endproperty: p_out_valid

//====================================================================================================
// Assertion 7 (Next operation will be valid 2-10 cycles after out_valid fall.)
//====================================================================================================
assertion_7: assert property (p_delay_out_to_next and p_delay_next)
else begin
    $display("Assertion 7 is violated");
    $fatal;
end

property p_delay_out_to_next;
    @(negedge clk) (inf.out_valid |=> @(posedge clk) inf.act_valid === 0 [*2]);
endproperty: p_delay_out_to_next

property p_delay_next;
    @(negedge clk) (inf.out_valid |=> @(posedge clk) ##[2:10] inf.act_valid === 1);
endproperty: p_delay_next
//====================================================================================================
// Assertion 8 (Latency should be less than 1200 cycles for each operation.)
//====================================================================================================
assertion_8: assert property (p_latency)
else begin
    $display("Assertion 8 is violated");
    $fatal;
end

property p_latency;
    @(posedge clk) (inf.id_valid && (action_reg === Deliver || action_reg === Cancel)) ||
                (inf.cus_valid && action_reg === Take) ||
                (inf.food_valid && action_reg === Order) |=> @(negedge clk) ## [1:1199] inf.out_valid === 1;
endproperty: p_latency

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        action_reg <= No_action;
    end
    else if(inf.act_valid) begin
        action_reg <= inf.D.d_act[0];
    end
end

endmodule