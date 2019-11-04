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

`define ENDIAN_DMA_BIT     		8 //Endianness of DMA data words  (0:little , 1: Big Endian)
//`define OFFSET_CALC = 13; //

//`define DMA_0_ON_BIT 	0
//`define DMA_1_ON_BIT 	1
//`define FWUSTAR_BIT 19
//`define STREAME_BIT     20 // Streaming enable
`define ACQE_BIT 		23
`define STRG_BIT        24 // soft Trigger
`define DMAE_BIT 		27
`define DMA_RST_BIT		28
`define DMAiE_BIT 		30 // DMA end Interrupt Enable

`endif // _control_word_bits_vh_
