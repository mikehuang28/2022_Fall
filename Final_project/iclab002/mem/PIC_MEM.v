//
//      CONFIDENTIAL AND PROPRIETARY SOFTWARE/DATA OF ARTISAN COMPONENTS, INC.
//      
//      Copyright (c) 2022 Artisan Components, Inc.  All Rights Reserved.
//      
//      Use of this Software/Data is subject to the terms and conditions of
//      the applicable license agreement between Artisan Components, Inc. and
//      UMC.  In addition, this Software/Data
//      is protected by copyright law and international treaties.
//      
//      The copyright notice(s) in this Software/Data does not indicate actual
//      or intended publication of this Software/Data.
//
//      Verilog model for Synchronous Single-Port Ram
//
//      Instance Name:  PIC_MEM
//      Words:          256
//      Word Width:     32
//      Pipeline:       No
//
//      Creation Date:  2022-12-29 08:32:17Z
//      Version: 	2001Q4V0
//
//      Verified With: Cadence Verilog-XL
//
//      Modeling Assumptions: This model supports full gate level simulation
//          including proper x-handling and timing check behavior.  Unit
//          delay timing is included in the model. Back-annotation of SDF
//          (v2.1) is supported.  SDF can be created utilyzing the delay
//          calculation views provided with this generator and supported
//          delay calculators.  All buses are modeled [MSB:LSB].  All 
//          ports are padded with Verilog primitives.
//
//      Modeling Limitations: The output hold function has been deleted
//          completely from this model.  Most Verilog simulators are 
//          incapable of scheduling more than 1 event on the rising 
//          edge of clock.  Therefore, it is impossible to model
//          the output hold (to x) action correctly.  It is necessary
//          to run static path timing tools using Artisan supplied
//          timing models to insure that the output hold time is
//          sufficient enough to not violate hold time constraints
//          of downstream flip-flops.
//
//      Known Bugs: None.
//
//      Known Work Arounds: N/A
//
`timescale 1 ns/10 ps
`celldefine
module PIC_MEM (
   Q,
   CLK,
   CEN,
   WEN,
   A,
   D,
   OEN
);
   parameter		   BITS = 32;
   parameter		   word_depth = 256;
   parameter		   addr_width = 8;
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};
	
   output [31:0] Q;
   input CLK;
   input CEN;
   input WEN;
   input [7:0] A;
   input [31:0] D;
   input OEN;

   reg [BITS-1:0]	   mem [word_depth-1:0];

   reg			   NOT_CEN;
   reg			   NOT_WEN;

   reg			   NOT_A0;
   reg			   NOT_A1;
   reg			   NOT_A2;
   reg			   NOT_A3;
   reg			   NOT_A4;
   reg			   NOT_A5;
   reg			   NOT_A6;
   reg			   NOT_A7;
   reg [addr_width-1:0]	   NOT_A;
   reg			   NOT_D0;
   reg			   NOT_D1;
   reg			   NOT_D2;
   reg			   NOT_D3;
   reg			   NOT_D4;
   reg			   NOT_D5;
   reg			   NOT_D6;
   reg			   NOT_D7;
   reg			   NOT_D8;
   reg			   NOT_D9;
   reg			   NOT_D10;
   reg			   NOT_D11;
   reg			   NOT_D12;
   reg			   NOT_D13;
   reg			   NOT_D14;
   reg			   NOT_D15;
   reg			   NOT_D16;
   reg			   NOT_D17;
   reg			   NOT_D18;
   reg			   NOT_D19;
   reg			   NOT_D20;
   reg			   NOT_D21;
   reg			   NOT_D22;
   reg			   NOT_D23;
   reg			   NOT_D24;
   reg			   NOT_D25;
   reg			   NOT_D26;
   reg			   NOT_D27;
   reg			   NOT_D28;
   reg			   NOT_D29;
   reg			   NOT_D30;
   reg			   NOT_D31;
   reg [BITS-1:0]	   NOT_D;
   reg			   NOT_CLK_PER;
   reg			   NOT_CLK_MINH;
   reg			   NOT_CLK_MINL;

   reg			   LAST_NOT_CEN;
   reg			   LAST_NOT_WEN;
   reg [addr_width-1:0]	   LAST_NOT_A;
   reg [BITS-1:0]	   LAST_NOT_D;
   reg			   LAST_NOT_CLK_PER;
   reg			   LAST_NOT_CLK_MINH;
   reg			   LAST_NOT_CLK_MINL;


   wire [BITS-1:0]   _Q;
   wire			   _OENi;
   wire [addr_width-1:0]   _A;
   wire			   _CLK;
   wire			   _CEN;
   wire			   _OEN;
   wire                    _WEN;

   wire [BITS-1:0]   _D;
   wire                    re_flag;
   wire                    re_data_flag;


   reg			   LATCHED_CEN;
   reg	                  LATCHED_WEN;
   reg [addr_width-1:0]	   LATCHED_A;
   reg [BITS-1:0]	   LATCHED_D;

   reg			   CENi;
   reg           	   WENi;
   reg [addr_width-1:0]	   Ai;
   reg [BITS-1:0]	   Di;
   reg [BITS-1:0]	   Qi;
   reg [BITS-1:0]	   LAST_Qi;



   reg			   LAST_CLK;





   task update_notifier_buses;
   begin
      NOT_A = {
               NOT_A7,
               NOT_A6,
               NOT_A5,
               NOT_A4,
               NOT_A3,
               NOT_A2,
               NOT_A1,
               NOT_A0};
      NOT_D = {
               NOT_D31,
               NOT_D30,
               NOT_D29,
               NOT_D28,
               NOT_D27,
               NOT_D26,
               NOT_D25,
               NOT_D24,
               NOT_D23,
               NOT_D22,
               NOT_D21,
               NOT_D20,
               NOT_D19,
               NOT_D18,
               NOT_D17,
               NOT_D16,
               NOT_D15,
               NOT_D14,
               NOT_D13,
               NOT_D12,
               NOT_D11,
               NOT_D10,
               NOT_D9,
               NOT_D8,
               NOT_D7,
               NOT_D6,
               NOT_D5,
               NOT_D4,
               NOT_D3,
               NOT_D2,
               NOT_D1,
               NOT_D0};
   end
   endtask

   task mem_cycle;
   begin
      casez({WENi,CENi})

	2'b10: begin
	   read_mem(1,0);
	end
	2'b00: begin
	   write_mem(Ai,Di);
	   read_mem(0,0);
	end
	2'b?1: ;
	2'b1x: begin
	   read_mem(0,1);
	end
	2'bx0: begin
	   write_mem_x(Ai);
	   read_mem(0,1);
	end
	2'b0x,
	2'bxx: begin
	   write_mem_x(Ai);
	   read_mem(0,1);
	end
      endcase
   end
   endtask
      

   task update_last_notifiers;
   begin
      LAST_NOT_A = NOT_A;
      LAST_NOT_D = NOT_D;
      LAST_NOT_WEN = NOT_WEN;
      LAST_NOT_CEN = NOT_CEN;
      LAST_NOT_CLK_PER = NOT_CLK_PER;
      LAST_NOT_CLK_MINH = NOT_CLK_MINH;
      LAST_NOT_CLK_MINL = NOT_CLK_MINL;
   end
   endtask

   task latch_inputs;
   begin
      LATCHED_A = _A ;
      LATCHED_D = _D ;
      LATCHED_WEN = _WEN ;
      LATCHED_CEN = _CEN ;
      LAST_Qi = Qi;
   end
   endtask


   task update_logic;
   begin
      CENi = LATCHED_CEN;
      WENi = LATCHED_WEN;
      Ai = LATCHED_A;
      Di = LATCHED_D;
   end
   endtask



   task x_inputs;
      integer n;
   begin
      for (n=0; n<addr_width; n=n+1)
	 begin
	    LATCHED_A[n] = (NOT_A[n]!==LAST_NOT_A[n]) ? 1'bx : LATCHED_A[n] ;
	 end
      for (n=0; n<BITS; n=n+1)
	 begin
	    LATCHED_D[n] = (NOT_D[n]!==LAST_NOT_D[n]) ? 1'bx : LATCHED_D[n] ;
	 end
      LATCHED_WEN = (NOT_WEN!==LAST_NOT_WEN) ? 1'bx : LATCHED_WEN ;

      LATCHED_CEN = (NOT_CEN!==LAST_NOT_CEN) ? 1'bx : LATCHED_CEN ;
   end
   endtask

   task read_mem;
      input r_wb;
      input xflag;
   begin
      if (r_wb)
	 begin
	    if (valid_address(Ai))
	       begin
                     Qi=mem[Ai];
	       end
	    else
	       begin
		  Qi=wordx;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
		  Qi=wordx;
	       end
	    else
	       begin
	          Qi=Di;
	       end
	 end
   end
   endtask

   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
 
   begin
      casez({valid_address(a)})
	1'b0: 
		x_mem;
	1'b1: mem[a]=d;
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
   begin
      casez({valid_address(a)})
	1'b0: 
		x_mem;
	1'b1: mem[a]=wordx;
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask

   task process_violations;
   begin
      if ((NOT_CLK_PER!==LAST_NOT_CLK_PER) ||
	  (NOT_CLK_MINH!==LAST_NOT_CLK_MINH) ||
	  (NOT_CLK_MINL!==LAST_NOT_CLK_MINL))
	 begin
	    if (CENi !== 1'b1)
               begin
		  x_mem;
		  read_mem(0,1);
	       end
	 end
      else
	 begin
	    update_notifier_buses;
	    x_inputs;
	    update_logic;
	    mem_cycle;
	 end
      update_last_notifiers;
   end
   endtask

   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction


   bufif0 (Q[0], _Q[0], _OENi);
   bufif0 (Q[1], _Q[1], _OENi);
   bufif0 (Q[2], _Q[2], _OENi);
   bufif0 (Q[3], _Q[3], _OENi);
   bufif0 (Q[4], _Q[4], _OENi);
   bufif0 (Q[5], _Q[5], _OENi);
   bufif0 (Q[6], _Q[6], _OENi);
   bufif0 (Q[7], _Q[7], _OENi);
   bufif0 (Q[8], _Q[8], _OENi);
   bufif0 (Q[9], _Q[9], _OENi);
   bufif0 (Q[10], _Q[10], _OENi);
   bufif0 (Q[11], _Q[11], _OENi);
   bufif0 (Q[12], _Q[12], _OENi);
   bufif0 (Q[13], _Q[13], _OENi);
   bufif0 (Q[14], _Q[14], _OENi);
   bufif0 (Q[15], _Q[15], _OENi);
   bufif0 (Q[16], _Q[16], _OENi);
   bufif0 (Q[17], _Q[17], _OENi);
   bufif0 (Q[18], _Q[18], _OENi);
   bufif0 (Q[19], _Q[19], _OENi);
   bufif0 (Q[20], _Q[20], _OENi);
   bufif0 (Q[21], _Q[21], _OENi);
   bufif0 (Q[22], _Q[22], _OENi);
   bufif0 (Q[23], _Q[23], _OENi);
   bufif0 (Q[24], _Q[24], _OENi);
   bufif0 (Q[25], _Q[25], _OENi);
   bufif0 (Q[26], _Q[26], _OENi);
   bufif0 (Q[27], _Q[27], _OENi);
   bufif0 (Q[28], _Q[28], _OENi);
   bufif0 (Q[29], _Q[29], _OENi);
   bufif0 (Q[30], _Q[30], _OENi);
   bufif0 (Q[31], _Q[31], _OENi);
   buf (_D[0], D[0]);
   buf (_D[1], D[1]);
   buf (_D[2], D[2]);
   buf (_D[3], D[3]);
   buf (_D[4], D[4]);
   buf (_D[5], D[5]);
   buf (_D[6], D[6]);
   buf (_D[7], D[7]);
   buf (_D[8], D[8]);
   buf (_D[9], D[9]);
   buf (_D[10], D[10]);
   buf (_D[11], D[11]);
   buf (_D[12], D[12]);
   buf (_D[13], D[13]);
   buf (_D[14], D[14]);
   buf (_D[15], D[15]);
   buf (_D[16], D[16]);
   buf (_D[17], D[17]);
   buf (_D[18], D[18]);
   buf (_D[19], D[19]);
   buf (_D[20], D[20]);
   buf (_D[21], D[21]);
   buf (_D[22], D[22]);
   buf (_D[23], D[23]);
   buf (_D[24], D[24]);
   buf (_D[25], D[25]);
   buf (_D[26], D[26]);
   buf (_D[27], D[27]);
   buf (_D[28], D[28]);
   buf (_D[29], D[29]);
   buf (_D[30], D[30]);
   buf (_D[31], D[31]);
   buf (_A[0], A[0]);
   buf (_A[1], A[1]);
   buf (_A[2], A[2]);
   buf (_A[3], A[3]);
   buf (_A[4], A[4]);
   buf (_A[5], A[5]);
   buf (_A[6], A[6]);
   buf (_A[7], A[7]);
   buf (_CLK, CLK);
   buf (_WEN, WEN);
   buf (_OEN, OEN);
   buf (_CEN, CEN);


   assign _OENi = _OEN;
   assign _Q = Qi;
   assign re_flag = !(_CEN);
   assign re_data_flag = !(_CEN || _WEN);


   always @(
	    NOT_A0 or
	    NOT_A1 or
	    NOT_A2 or
	    NOT_A3 or
	    NOT_A4 or
	    NOT_A5 or
	    NOT_A6 or
	    NOT_A7 or
	    NOT_D0 or
	    NOT_D1 or
	    NOT_D2 or
	    NOT_D3 or
	    NOT_D4 or
	    NOT_D5 or
	    NOT_D6 or
	    NOT_D7 or
	    NOT_D8 or
	    NOT_D9 or
	    NOT_D10 or
	    NOT_D11 or
	    NOT_D12 or
	    NOT_D13 or
	    NOT_D14 or
	    NOT_D15 or
	    NOT_D16 or
	    NOT_D17 or
	    NOT_D18 or
	    NOT_D19 or
	    NOT_D20 or
	    NOT_D21 or
	    NOT_D22 or
	    NOT_D23 or
	    NOT_D24 or
	    NOT_D25 or
	    NOT_D26 or
	    NOT_D27 or
	    NOT_D28 or
	    NOT_D29 or
	    NOT_D30 or
	    NOT_D31 or
	    NOT_WEN or
	    NOT_CEN or
	    NOT_CLK_PER or
	    NOT_CLK_MINH or
	    NOT_CLK_MINL
	    )
      begin
         process_violations;
      end

   always @( _CLK )
      begin
         casez({LAST_CLK,_CLK})
	   2'b01: begin
	      latch_inputs;
	      update_logic;
	      mem_cycle;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_mem(0,1);
	   end
	   
	 endcase
	 LAST_CLK = _CLK;
      end

   specify
      $setuphold(posedge CLK,posedge CEN, 1.000, 0.500, NOT_CEN);
      $setuphold(posedge CLK,negedge CEN, 1.000, 0.500, NOT_CEN);
      $setuphold(posedge CLK &&& re_flag,posedge WEN, 1.000, 0.500, NOT_WEN);
      $setuphold(posedge CLK &&& re_flag,negedge WEN, 1.000, 0.500, NOT_WEN);
      $setuphold(posedge CLK &&& re_flag,posedge A[0], 1.000, 0.500, NOT_A0);
      $setuphold(posedge CLK &&& re_flag,negedge A[0], 1.000, 0.500, NOT_A0);
      $setuphold(posedge CLK &&& re_flag,posedge A[1], 1.000, 0.500, NOT_A1);
      $setuphold(posedge CLK &&& re_flag,negedge A[1], 1.000, 0.500, NOT_A1);
      $setuphold(posedge CLK &&& re_flag,posedge A[2], 1.000, 0.500, NOT_A2);
      $setuphold(posedge CLK &&& re_flag,negedge A[2], 1.000, 0.500, NOT_A2);
      $setuphold(posedge CLK &&& re_flag,posedge A[3], 1.000, 0.500, NOT_A3);
      $setuphold(posedge CLK &&& re_flag,negedge A[3], 1.000, 0.500, NOT_A3);
      $setuphold(posedge CLK &&& re_flag,posedge A[4], 1.000, 0.500, NOT_A4);
      $setuphold(posedge CLK &&& re_flag,negedge A[4], 1.000, 0.500, NOT_A4);
      $setuphold(posedge CLK &&& re_flag,posedge A[5], 1.000, 0.500, NOT_A5);
      $setuphold(posedge CLK &&& re_flag,negedge A[5], 1.000, 0.500, NOT_A5);
      $setuphold(posedge CLK &&& re_flag,posedge A[6], 1.000, 0.500, NOT_A6);
      $setuphold(posedge CLK &&& re_flag,negedge A[6], 1.000, 0.500, NOT_A6);
      $setuphold(posedge CLK &&& re_flag,posedge A[7], 1.000, 0.500, NOT_A7);
      $setuphold(posedge CLK &&& re_flag,negedge A[7], 1.000, 0.500, NOT_A7);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[0], 1.000, 0.500, NOT_D0);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[0], 1.000, 0.500, NOT_D0);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[1], 1.000, 0.500, NOT_D1);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[1], 1.000, 0.500, NOT_D1);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[2], 1.000, 0.500, NOT_D2);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[2], 1.000, 0.500, NOT_D2);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[3], 1.000, 0.500, NOT_D3);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[3], 1.000, 0.500, NOT_D3);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[4], 1.000, 0.500, NOT_D4);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[4], 1.000, 0.500, NOT_D4);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[5], 1.000, 0.500, NOT_D5);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[5], 1.000, 0.500, NOT_D5);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[6], 1.000, 0.500, NOT_D6);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[6], 1.000, 0.500, NOT_D6);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[7], 1.000, 0.500, NOT_D7);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[7], 1.000, 0.500, NOT_D7);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[8], 1.000, 0.500, NOT_D8);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[8], 1.000, 0.500, NOT_D8);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[9], 1.000, 0.500, NOT_D9);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[9], 1.000, 0.500, NOT_D9);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[10], 1.000, 0.500, NOT_D10);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[10], 1.000, 0.500, NOT_D10);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[11], 1.000, 0.500, NOT_D11);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[11], 1.000, 0.500, NOT_D11);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[12], 1.000, 0.500, NOT_D12);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[12], 1.000, 0.500, NOT_D12);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[13], 1.000, 0.500, NOT_D13);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[13], 1.000, 0.500, NOT_D13);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[14], 1.000, 0.500, NOT_D14);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[14], 1.000, 0.500, NOT_D14);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[15], 1.000, 0.500, NOT_D15);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[15], 1.000, 0.500, NOT_D15);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[16], 1.000, 0.500, NOT_D16);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[16], 1.000, 0.500, NOT_D16);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[17], 1.000, 0.500, NOT_D17);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[17], 1.000, 0.500, NOT_D17);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[18], 1.000, 0.500, NOT_D18);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[18], 1.000, 0.500, NOT_D18);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[19], 1.000, 0.500, NOT_D19);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[19], 1.000, 0.500, NOT_D19);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[20], 1.000, 0.500, NOT_D20);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[20], 1.000, 0.500, NOT_D20);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[21], 1.000, 0.500, NOT_D21);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[21], 1.000, 0.500, NOT_D21);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[22], 1.000, 0.500, NOT_D22);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[22], 1.000, 0.500, NOT_D22);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[23], 1.000, 0.500, NOT_D23);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[23], 1.000, 0.500, NOT_D23);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[24], 1.000, 0.500, NOT_D24);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[24], 1.000, 0.500, NOT_D24);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[25], 1.000, 0.500, NOT_D25);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[25], 1.000, 0.500, NOT_D25);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[26], 1.000, 0.500, NOT_D26);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[26], 1.000, 0.500, NOT_D26);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[27], 1.000, 0.500, NOT_D27);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[27], 1.000, 0.500, NOT_D27);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[28], 1.000, 0.500, NOT_D28);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[28], 1.000, 0.500, NOT_D28);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[29], 1.000, 0.500, NOT_D29);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[29], 1.000, 0.500, NOT_D29);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[30], 1.000, 0.500, NOT_D30);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[30], 1.000, 0.500, NOT_D30);
      $setuphold(posedge CLK &&& re_data_flag,posedge D[31], 1.000, 0.500, NOT_D31);
      $setuphold(posedge CLK &&& re_data_flag,negedge D[31], 1.000, 0.500, NOT_D31);

      $period(posedge CLK, 3.000, NOT_CLK_PER);
      $width(posedge CLK, 1.000, 0, NOT_CLK_MINH);
      $width(negedge CLK, 1.000, 0, NOT_CLK_MINL);

      (posedge CLK => (Q[0]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[1]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[2]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[3]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[4]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[5]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[6]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[7]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[8]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[9]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[10]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[11]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[12]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[13]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[14]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[15]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[16]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[17]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[18]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[19]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[20]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[21]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[22]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[23]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[24]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[25]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[26]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[27]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[28]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[29]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[30]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge CLK => (Q[31]:1'bx))=(1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (posedge OEN => (Q[0]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[1]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[2]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[3]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[4]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[5]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[6]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[7]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[8]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[9]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[10]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[11]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[12]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[13]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[14]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[15]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[16]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[17]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[18]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[19]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[20]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[21]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[22]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[23]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[24]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[25]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[26]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[27]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[28]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[29]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[30]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
      (posedge OEN => (Q[31]:1'bx))=(1.000, 1.000, 1.000, 1.000, 1.000, 1.000);
   endspecify

endmodule
`endcelldefine
