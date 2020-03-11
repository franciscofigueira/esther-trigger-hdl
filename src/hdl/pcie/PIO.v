//-----------------------------------------------------------------------------
//
// (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable  output 		[63:0]  trigger_level,
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage  output 		[63:0]  trigger_level,
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Series-7 Integrated Block for PCI Express
// File       : PIO.v
// Version    : 3.3
//
// Description:  Programmed I/O module. Design implements 8 KBytes of programmable  output 		[63:0]  trigger_level,
//--              memory space. Host processor can access this memory space using
//--              Memory Read 32 and Memory Write 32 TLPs. Design accepts
//--              1 Double Word (DW) payload length on Memory Write 32 TLP and
//--              responds to 1 DW length Memory Read 32 TLPs with a Completion
//--              with Data TLP (1DW payload).
//--
//--------------------------------------------------------------------------------

`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module PIO #(
  parameter C_DATA_WIDTH = 64,            // RX/TX interface data width

  // Do not override parameters below this line
  parameter KEEP_WIDTH = C_DATA_WIDTH / 8,              // TSTRB width
  parameter TCQ        = 1
)(
  input                         user_clk,
  input                         user_reset,
  input                         user_lnk_up,

  // AXIS
  input                         s_axis_tx_tready,
  output  [C_DATA_WIDTH-1:0]    s_axis_tx_tdata,
  output  [KEEP_WIDTH-1:0]      s_axis_tx_tkeep,
  output                        s_axis_tx_tlast,
  output                        s_axis_tx_tvalid,
  output                        tx_src_dsc,

  input  [C_DATA_WIDTH-1:0]     m_axis_rx_tdata,
  input  [KEEP_WIDTH-1:0]       m_axis_rx_tkeep,
  input                         m_axis_rx_tlast,
  input                         m_axis_rx_tvalid,
  output                        m_axis_rx_tready,
  input    [21:0]               m_axis_rx_tuser,


  input                         cfg_to_turnoff,
  output                        cfg_turnoff_ok,

  output                          cfg_interrupt,

  input [15:0]                  cfg_completer_id,

  // DMA extension
  input  [5:0]                  tx_buf_av,
  input                         cfg_interrupt_rdy,

  input  		[23:0] trigger_status,
  output 		[31:0]  control_reg,
  output 		[63:0]  trigger_level,
 // ADC Interface
   input   [63:0] adc_data,
   input   adc_data_en,
   input   adc_data_clk,
   
   output pio_reset,
   input [7:0] dma_status,
     input cfg_interrupt_n,
   input [7:0] dma_tlp_payload_size,
   input [31:0] dma_host_addr_tx,
   input [C_DATA_WIDTH-1:0] dma_data,
   input dma_tlp_req,
   
   output s_axis_tx_tvalid_n,
     output cfg_interrupt_rdy_n,
     output fifo_rd_en,
     output dma_tlp_compl_done,
     output [5:0] tx_buf_av_n,
     
      output [10:0] rd_addr,
      output [3:0] rd_be,
      output [10:0] wr_addr,
      output [7:0] wr_be,
      output [31:0] wr_data,
      output wr_en,
      
       input [31:0] rd_data,
       input wr_busy
); // synthesis syn_hier = "hard"


  // Local wires



  wire          req_compl;
  wire          compl_done;
  reg           pio_reset_n;

  always @(posedge user_clk) begin
    if (user_reset)
        pio_reset_n <= #TCQ 1'b0;
    else
        pio_reset_n <= #TCQ user_lnk_up;
  end

assign pio_reset=pio_reset_n;
  //
  // PIO instance
  //

  PIO_EP  #(
    .C_DATA_WIDTH( C_DATA_WIDTH ),
    .KEEP_WIDTH( KEEP_WIDTH ),
    .TCQ( TCQ )
  ) PIO_EP_inst (

    .clk( user_clk ),                             // I
    .rst_n( pio_reset_n ),                        // I

    .s_axis_tx_tready( s_axis_tx_tready ),        // I
    .s_axis_tx_tdata( s_axis_tx_tdata ),          // O
    .s_axis_tx_tkeep( s_axis_tx_tkeep ),          // O
    .s_axis_tx_tlast( s_axis_tx_tlast ),          // O
    .s_axis_tx_tvalid( s_axis_tx_tvalid ),        // O
    .tx_src_dsc( tx_src_dsc ),                    // O

    .tx_buf_av(tx_buf_av),                        // I

    .m_axis_rx_tdata( m_axis_rx_tdata ),          // I
    .m_axis_rx_tkeep( m_axis_rx_tkeep ),          // I
    .m_axis_rx_tlast( m_axis_rx_tlast ),          // I
    .m_axis_rx_tvalid( m_axis_rx_tvalid ),        // I
    .m_axis_rx_tready( m_axis_rx_tready ),        // O
    .m_axis_rx_tuser ( m_axis_rx_tuser ),         // I

    .req_compl(req_compl),                        // O
    .compl_done(compl_done),                      // O

    .cfg_interrupt( cfg_interrupt ),
    .cfg_interrupt_rdy( cfg_interrupt_rdy ),

    .cfg_completer_id ( cfg_completer_id ),        // I [15:0]

    .trigger_status(trigger_status),
    .control_reg(control_reg),
    .trigger_level(trigger_level),

     // ADC Interface
    .adc_data(adc_data),
    .adc_data_en(adc_data_en),
    .adc_data_clk(adc_data_clk),  // 125MHz

   
     .cfg_interrupt_n(cfg_interrupt_n),
       .dma_status(dma_status),
       .dma_tlp_payload_size(dma_tlp_payload_size),
       .dma_host_addr_tx(dma_host_addr_tx),
       .dma_data(dma_data),
       .dma_tlp_req(dma_tlp_req), 
       
        .s_axis_tx_tvalid_n(s_axis_tx_tvalid_n),
          .cfg_interrupt_rdy_n(cfg_interrupt_rdy_n),
          .fifo_rd_en(fifo_rd_en),
          .dma_tlp_compl_done(dma_tlp_compl_done),
          .tx_buf_av_n(tx_buf_av_n),
     
       .rd_addr(rd_addr),
            .wr_addr(wr_addr),
            .rd_be(rd_be),
            .wr_be(wr_be),
            .wr_data(wr_data),
            .wr_en(wr_en),  
            
        .rd_data(rd_data),
               .wr_busy(wr_busy)   
  );


  //
  // Turn-Off controller
  //

  PIO_TO_CTRL #(
    .TCQ( TCQ )
  ) PIO_TO_inst  (
    .clk( user_clk ),                       // I
    .rst_n( pio_reset_n ),                  // I

    .req_compl( req_compl ),                // I
    .compl_done( compl_done ),              // I

    .cfg_to_turnoff( cfg_to_turnoff ),      // I
    .cfg_turnoff_ok( cfg_turnoff_ok )       // O
  );


endmodule // PIO
