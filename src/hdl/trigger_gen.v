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
    input adc_clk,
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
    
    input trig_reset,
    input  [1:0]   trig_level_addr,
    input  trig_level_wrt,
    input signed [15:0]   trig_level_data,
    //input signed [13:0]   trig_level_a,
    //input signed [13:0]   trig_level_b,
    output reg [15:0]  pulse_delay,
    output trigger0,
    output trigger1
    );
/*********** Function Declarations ***************/

function signed [ADC_DATA_WIDTH:0] adc_channel_mean_f;  // 17 bit for headroom
	 input [ADC_DATA_WIDTH-1:0] adc_data_first;
	 input [ADC_DATA_WIDTH-1:0] adc_data_second;
	 
     reg signed [ADC_DATA_WIDTH:0] adc_ext_1st; 
     reg signed [ADC_DATA_WIDTH:0] adc_ext_2nd; 
	   begin 	
            adc_ext_1st = $signed({adc_data_first[ADC_DATA_WIDTH-1], adc_data_first}); // sign extend
            adc_ext_2nd = $signed({adc_data_second[ADC_DATA_WIDTH-1], adc_data_second}); 
            adc_channel_mean_f = adc_ext_1st + adc_ext_2nd;
	  end 
  endfunction

function  trigger_rising_eval_f;
	input signed [ADC_DATA_WIDTH:0] adc_channel_mean;
	input signed [ADC_DATA_WIDTH-1:0] trig_lvl;
    
    reg signed [ADC_DATA_WIDTH:0] trig_lvl_ext; 

	   begin 
	       trig_lvl_ext = $signed({trig_lvl, 1'b0}); // Mult * 2 with sign 
           trigger_rising_eval_f =(adc_channel_mean > trig_lvl_ext)? 1'b1: 1'b0;
       end 
endfunction

function  trigger_falling_eval_f;
	input signed [ADC_DATA_WIDTH:0] adc_channel_mean;
	input signed [ADC_DATA_WIDTH-1:0] trig_lvl;
	
	reg signed [ADC_DATA_WIDTH +1:0] trig_lvl_ext; 

	   begin 	
         trig_lvl_ext = $signed({trig_lvl, 1'b0}); // Mult * 2  with  sign extend
         trigger_falling_eval_f =(adc_channel_mean < trig_lvl_ext)? 1'b1: 1'b0;
       end 
endfunction

/*********** End Function Declarations ***************/

/************ Trigger Logic ************/
	/* ADC Data comes in pairs. Compute mean, this case or simply add */
	reg signed [17:0] adc_mean_a;
	always @(posedge adc_clk) begin
         if (adc_enable_a)  // Use adc_valid_a ?
            adc_mean_a <= adc_channel_mean_f(adc_data_a[15:0], adc_data_a[31:16]); // check order (not really necessary, its a mean...)
	end

	reg  trigger0_r;
    assign trigger0 = trigger0_r; 
    
	reg signed [17:0] adc_mean_b;
	always @(posedge adc_clk) begin
         if (adc_enable_b)  // Use adc_valid_b ?
            adc_mean_b <= adc_channel_mean_f(adc_data_b[15:0], adc_data_b[31:16]); // check order (not really necessary, its a mean...)
	end
	
	reg  trigger1_r = 0;
    assign trigger1 = trigger1_r; 

    reg  signed [15:0]  trig_level_a_reg=0;       
    reg  signed [15:0]  trig_level_b_reg=0;       

	 localparam IDLE    = 3'b000;
     localparam READY   = 3'b001;
     localparam PULSE0  = 3'b010;
     localparam PULSE1  = 3'b011;
     localparam TRIGGER = 3'b100;
     
     localparam WAIT_WIDTH = 24;
     
     reg [WAIT_WIDTH-1:0] wait_cnt = 0; // {WAIT_WIDTH{1'b1}}
 
    // (* mark_debug = "true" *) 
    reg [2:0] state = IDLE;
     
    always @(posedge adc_clk)
       if (trig_reset) begin
          state <= IDLE;
          trigger0_r  <=  0; 
          trigger1_r  <=  0; 
          wait_cnt <= 24'h7A120; //500000 * 4ns Initial Idle Time  = 2 ms 
          pulse_delay  <=  0; 
      
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
                if (trigger_rising_eval_f(adc_mean_a, trig_level_a_reg)) begin 
                   state <= PULSE0;
                end   
                trigger0_r  <=  1'b1; 
                trigger1_r  <=  0; 
                wait_cnt <= 0;
             end
             PULSE0 : begin // Got first pulse. Waiting Second
                //if (trigger_eval_f(adc_mean_b, {trig_level_b, 4'h0})) begin
                trigger0_r <=  1'b0; 
                if (trigger_falling_eval_f(adc_mean_b, trig_level_b_reg)) begin // Testing  negative edge of input b
                    state <= PULSE1;
                    pulse_delay  <=  wait_cnt[15:0]; 
                end 
                wait_cnt   <=  wait_cnt + 8'd20; // Multiply delay by 20
             end
             PULSE1 : begin   // Got second pulse. Waiting calculated delay
                trigger1_r <=  1'b1; 
                wait_cnt <= wait_cnt - 1;
                if (wait_cnt == {WAIT_WIDTH{1'b0}})
                   state <= TRIGGER;
             end
             TRIGGER : begin // End Trigger
                trigger1_r <=  1'b0; 
 //                    state <= IDLE;
             end
             default :  
                     state <= IDLE;
          endcase

// Write Level Registers
   always @(posedge adc_clk)
        if (trig_level_wrt)
                 case (trig_level_addr)
 //                   2'b00:  
                    2'b01: trig_level_a_reg  <=  trig_level_data; 
                    2'b10: trig_level_b_reg  <=  trig_level_data; 
//                    2'b11:
                    default : ;  
                 endcase
                           
	
endmodule