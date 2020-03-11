`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2018 03:15:44 PM
// Design Name: 
// Module Name: trigger_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//
// Copyright 2018 IPFN-Instituto Superior Tecnico, Portugal
// Creation Date   04/30/2018 03:15:44 PM 
//
// Licensed under the EUPL, Version 1.2 or - as soon they
// will be approved by the European Commission - subsequent
// versions of the EUPL (the "Licence");
//
// You may not use this work except in compliance with the
// Licence.
// You may obtain a copy of the Licence at:
//
// https://joinup.ec.europa.eu/software/page/eupl
//
// Unless required by applicable law or agreed to in
// writing, software distributed under the Licence is
// distributed on an "AS IS" basis,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied.
// See the Licence for the specific language governing
// permissions and limitations under the Licence.
//
// 
//////////////////////////////////////////////////////////////////////////////////


module trigger_gen #(
  parameter     ADC_DATA_WIDTH = 16)  // ADC is 14 bit, but data is 16
  (
    input clk,      // 125 Mhz , two samples per clock
    input [31:0] adc_data_a,
    input adc_enable_a,
    input adc_valid_a,
    input [31:0] adc_data_b,
    input adc_enable_b,
    input adc_valid_b,
    input [31:0] adc_data_c,
    input adc_enable_c,
    input adc_valid_c,
    input [31:0] adc_data_d,
    input adc_enable_d,
    input adc_valid_d,
    
    input trig_enable,  // Enable/Reset State Machine
    input  [47:0] trig_level_arr, // 3 trigger levels
    //input  [1:0]   trig_level_addr,
    //input  trig_level_wrt, // registers write enable
    //input  [15:0] trig_level_data,

    output [15:0] pulse_delay,  // Diference Pulse_0 -> Pulse_1 
    output trigger0,
    output trigger1
    );
/*********** Function Declarations ***************/

function signed [ADC_DATA_WIDTH:0] adc_channel_mean_f;  // 17 bit for sum headroom
	 input [ADC_DATA_WIDTH-1:0] adc_data_first;
	 input [ADC_DATA_WIDTH-1:0] adc_data_second;
	 
     reg signed [ADC_DATA_WIDTH:0] adc_ext_1st; 
     reg signed [ADC_DATA_WIDTH:0] adc_ext_2nd; 
	   begin 	
            adc_ext_1st = $signed({adc_data_first[ADC_DATA_WIDTH-1],  adc_data_first}); // sign extend
            adc_ext_2nd = $signed({adc_data_second[ADC_DATA_WIDTH-1], adc_data_second}); 
            adc_channel_mean_f = adc_ext_1st + adc_ext_2nd;
	  end 
  endfunction

function  trigger_rising_eval_f;
	input signed [ADC_DATA_WIDTH:0] adc_channel_mean;
	input signed [ADC_DATA_WIDTH-1:0] trig_lvl;
    
    reg signed [ADC_DATA_WIDTH:0] trig_lvl_ext; 
	begin 
       trig_lvl_ext          = $signed({trig_lvl, 1'b0}); // Mult * 2 with sign 
       trigger_rising_eval_f =(adc_channel_mean > trig_lvl_ext)? 1'b1: 1'b0;
    end 
endfunction

function  trigger_falling_eval_f;
	input signed [ADC_DATA_WIDTH:0] adc_channel_mean;
	input signed [ADC_DATA_WIDTH-1:0] trig_lvl;
	
	reg signed [ADC_DATA_WIDTH:0] trig_lvl_ext; 
	begin 	
        trig_lvl_ext = $signed({trig_lvl, 1'b0}); // Mult * 2  with  sign extend
        trigger_falling_eval_f =(adc_channel_mean < trig_lvl_ext)? 1'b1: 1'b0;
    end 
endfunction


parameter delay=100;
function timing_calculation;
     input [31:0] timer1;
     input [31:0] timer2;
     input [31:0] count;
     
       reg [31:0] avg_time;
       begin
         avg_time=(timer1+timer2)>>1;
      
         timing_calculation=((avg_time-delay) >= count)?1'b1:1'b0;
     end
     
 endfunction     
/*********** End Function Declarations ***************/

/************ Trigger Logic ************/
	/* ADC Data comes in pairs. Compute mean, or this case simply add */
	reg signed [ADC_DATA_WIDTH:0] adc_mean_a, adc_mean_b, adc_mean_c, adc_mean_d ;
	always @(posedge clk) begin
         if (adc_enable_a)  // Use adc_valid_a ?
            adc_mean_a <= adc_channel_mean_f(adc_data_a[15:0], adc_data_a[31:16]); // check order (not really necessary, its a mean...)
         if (adc_enable_b)  // Use adc_valid_b ?
            adc_mean_b <= adc_channel_mean_f(adc_data_b[15:0], adc_data_b[31:16]); 
         if (adc_enable_c)  
            adc_mean_c <= adc_channel_mean_f(adc_data_c[15:0], adc_data_c[31:16]); 
         if (adc_enable_d)  
            adc_mean_d <= adc_channel_mean_f(adc_data_d[15:0], adc_data_d[31:16]); 
	end

	reg  trigger0_r;
    assign trigger0 = trigger0_r; 
    
	reg  trigger1_r = 0;
    assign trigger1 = trigger1_r; 
/*
    reg  signed [15:0]  trig_level_a_reg=0;       
    reg  signed [15:0]  trig_level_b_reg=0;       
    reg  signed [15:0]  trig_level_c_reg=0;   
 */   
    wire  signed [15:0]  trig_level_a = trig_level_arr[15:0]; 
    wire  signed [15:0]  trig_level_b = trig_level_arr[31:16]; 
    wire  signed [15:0]  trig_level_c = trig_level_arr[47:32];         
    
     reg [15:0] pulse_delay_r;
     assign pulse_delay = pulse_delay_r;
    
	 localparam IDLE    = 3'b000;
     localparam READY   = 3'b001;
     localparam PULSE0  = 3'b010;
     localparam PULSE1  = 3'b011;
     localparam PULSE2  = 3'b100;
     localparam TRIGGER = 3'b101;
     
     localparam WAIT_WIDTH = 24;
     
     reg [WAIT_WIDTH-1:0] wait_cnt = 0; // {WAIT_WIDTH{1'b1}}
 
    // (* mark_debug = "true" *) 
    reg [2:0] state = IDLE;
  /*   
    always @(posedge clk)
       if (!trig_enable) begin
          state <= IDLE;
          trigger0_r  <=  0; 
          trigger1_r  <=  0; 
          wait_cnt <= 24'd37000; //* 8ns Initial Idle Time  = 0.3 ms , Max 16777215 134 ms
          pulse_delay_r  <=  16'hFFFF; 
      
       end
       else
          case (state)
             IDLE: begin        // Sleeping 
                trigger0_r  <=  0; 
                trigger1_r  <=  0; 
                wait_cnt <= wait_cnt - 1;
                if (wait_cnt == {WAIT_WIDTH{1'b0}})
                   state <= READY;
             end
             READY: begin // Armed: Waiting first pulse
                if (trigger_rising_eval_f(adc_mean_a, trig_level_a)) begin 
                   state <= PULSE0;
                   trigger0_r  <=  1'b1; 
                end   
    //            trigger1_r  <=  0; 
                wait_cnt <= 0;
             end
             PULSE0 : begin // Got first pulse. Waiting Second
      //          trigger0_r <=  1'b0; 
//                if (trigger_falling_eval_f(adc_mean_b, trig_level_b_reg)) begin // Testing  negative edge of input b
               
                if (trigger_falling_eval_f(adc_mean_a, trig_level_b)) begin // Testing  negative edge of input b
                    state <= PULSE1;
                    pulse_delay_r  <=  wait_cnt[15:0]; // Save waiting Time
                end
                else 
                    wait_cnt   <=  wait_cnt + 8'd5; // increase 5 time units
             end
             PULSE1 : begin   // Waiting Third Pulse 
                if (trigger_rising_eval_f(adc_mean_a, trig_level_c)) begin 
                    trigger1_r <=  1'b1; 
                    state <= PULSE2;
                end   
             end
             PULSE2 : begin   // Got Third pulse. Waiting calculated delay
                if (wait_cnt == {WAIT_WIDTH{1'b0}}) begin
                   trigger1_r <=  1'b0; 
                   state <= TRIGGER;
                end
                else
                    wait_cnt <= wait_cnt - 1;
             end
             TRIGGER : begin // End Trigger
                trigger0_r <=  1'b1; 
 //                    state <= IDLE;
             end
             default :  
                     state <= IDLE;
          endcase
*/

reg [31:0] wait_cnt2=0,counter=0;

 always @(posedge clk)
       if (!trig_enable) begin
          state <= IDLE;
          trigger0_r  <=  0; 
          trigger1_r  <=  0; 
          wait_cnt <= 24'd37000; //* 8ns Initial Idle Time  = 0.3 ms , Max 16777215 134 ms
          pulse_delay_r  <=  16'hFFFF; 
      
       end
       else
          case (state)
             IDLE: begin        // Sleeping 
                trigger0_r  <=  0; 
                trigger1_r  <=  0; 
                wait_cnt <= wait_cnt - 1;
                if (wait_cnt == {WAIT_WIDTH{1'b0}})
                   state <= READY;
             end
             READY: begin // Armed: Waiting first pulse
                if (trigger_rising_eval_f(adc_mean_a, trig_level_a)) begin 
                   state <= PULSE0;
                   trigger0_r  <=  1'b1; 
                end   
    //            trigger1_r  <=  0; 
                wait_cnt <= 0;
             end
             PULSE0 : begin // Got first pulse. Waiting Second
      //          trigger0_r <=  1'b0; 
//                if (trigger_falling_eval_f(adc_mean_b, trig_level_b_reg)) begin // Testing  negative edge of input b
               
                if (trigger_rising_eval_f(adc_mean_b, trig_level_a))begin // Testing  negative edge of input b
                    state <= PULSE1;
                    pulse_delay_r  <=  wait_cnt[15:0];  // Save waiting Time
                    wait_cnt2 <= 'b0;
                end
                else 
                    wait_cnt   <=  wait_cnt + 8'd5; // increase 5 time units
             end
             PULSE1 : begin   // Waiting Third Pulse 
                if (trigger_rising_eval_f(adc_mean_c, trig_level_c)) begin 
                    trigger1_r <=  1'b0; 
                    state <= PULSE2;
                    counter<='b0;
                    
                end  
               wait_cnt2<=wait_cnt2+8'd5;
             
                 
             end
             PULSE2 : begin   // Got Third pulse. Waiting calculated delay
                if (wait_cnt == counter) begin
                   trigger1_r <=  1'b0; 
                   state <= TRIGGER;
                end
                else
                    counter<=counter+8'd5;
             end
             TRIGGER : begin // End Trigger
                trigger0_r <=  1'b1; 
                trigger1_r <=  1'b1;
 //                    state <= IDLE;
             end
             default :  
                     state <= IDLE;
          endcase

/*
// Write Trigger Level Registers
   always @(posedge clk)
        if (trig_level_wrt)
                 case (trig_level_addr)
 //                   2'b00:  
                    2'b01: trig_level_a_reg  <=  trig_level_data; 
                    2'b10: trig_level_b_reg  <=  trig_level_data; 
                    2'b11: trig_level_c_reg  <=  trig_level_data; 
                    //                    2'b11:
                    default : ;  
                 endcase
    */                       
	
endmodule