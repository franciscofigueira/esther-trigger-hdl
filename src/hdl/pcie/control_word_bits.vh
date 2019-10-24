///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: INSTITUTO DE PLASMAS E FUSAO NUCLEAR
// Engineer: BBC
//
// Create Date:   13:45:00 15/04/2016
// Project Name:
// Design Name:
// Module Name:  dma_fields
// Target Devices:
// Tool versions:  Vivado 2017.4
//
// Description:
// Verilog Header
// SHAPI registers - DMA device
//
//
// Copyright 2015 - 2017 IPFN-Instituto Superior Tecnico, Portugal
// Creation Date  2017-11-09
//
// Licensed under the EUPL, Version 1.2 or - as soon they
// will be approved by the European Commission - subsequent
// versions of the EUPL (the "Licence");
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
`ifndef _control_word_bits_vh_
`define _control_word_bits_vh_

//####### SHAPI REGISTERS #############//

//#### STANDARD DEVICE REGISTERS ######//
`define ENDIAN_DMA_BIT     		8 //Endianness of DMA data words  (0:little , 1: Big Endian)
//`define CHOP_ON_BIT          	10 // State of Chop, if equals 1 chop is ON if 0 it is OFF
//`define CHOP_DEFAULT_BIT    	11 // Value of Chop case CHOP_STATE is 0
//`define CHOP_RECONSTRUCT_BIT  	12 // State of Chop Recontruction, if equals 1 chop is ON if 0 it is OFF
//`define OFFSET_CALC = 13; //
//`define INT_CALC            = 14; // Output Integral Values
//`define DAC_SHFT_BITS       = 15; // DAC MUX command (4 bits)

//parameter ACQS = 5'd20; // Aquisitio Source: 0- shared ATCA clocks, 1-internal clocks
//parameter ACQT = 5'd21;
//parameter ACQK = 5'd22;

`define DMA_0_ON_BIT 	0
`define DMA_1_ON_BIT 	1
//`define FWUSTAR_BIT 19
`define STREAME_BIT     20 // Streaming enable
`define ACQE_BIT 		23
`define DMAE_BIT 		27
`define DMA_RST_BIT		28
`define DMAiE_BIT 		30 // DMA end Interrup Enable



//`define _BIT 19  //
//`define STREAME_BIT  19  // Streaming enable
//`define ACQS = 20; // Aquisitio Source: 0- shared ATCA clocks, 1-internal clocks

//`define ACQE_BIT  23
//`define STRG_BIT  24 // soft Trigger

//typedef struct _STATUS_FLDS {
  //u32 none:8, rsv0:8,
    //slotID:4, rsv2:2, MASTER:1, ERR0:1,  //rsv1:2, FSH:1, RST:1
    //rsv3:2,  FIFE:1, FIFF:1, rsv4:2, DMAC:1, ACQC:1; // msb
//} STATUS_FLDS;


//typedef struct _COMMAND_REG {
  //union{
    //u32 reg32;
    //[>  0, ..... 15
		//19 , ...31   */
    //struct  {u32 rsv0:8, BIG_ENDN:1, rsv00:1, CHOP_ON:1, CHOP_DEFAULT:1, CHOP_RECONSTRUCT:1, rsv01:6, //OFFSET_CALC:1, INTEGRAL_CALC:1, DAC_SHIFT:4,
	//STREAME:1, rsv1:3, ACQE:1, STRG:1, TRGS:1, rsv2:1, DMAE:1, rsv4:1, ERRiE:1, DMAiE:1, ACQiE:1;
    //} cmdFlds;
  //};
//} COMMAND_REG;


`endif // _control_word_bits_vh_
