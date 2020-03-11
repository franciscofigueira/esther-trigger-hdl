//////////////////////////////////////////////////////////////////////////////////
// Company: IPFN-IST
// Engineer: BBC
//
// Create Date: 05/02/2019 07:21:01 PM
// Design Name:
// Module Name: pci_dma_engine
// Project Name:
// Target Devices: kintex-7
// Tool Versions:  Vivado 2019.1
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// Copyright 2015 - 2019 IPFN-Instituto Superior Tecnico, Portugal
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
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module pci_dma_engine #(
    parameter C_DATA_WIDTH    = 64,         // RX/TX interface data width, only 64 is implemented
    parameter MAX_PAYLOAD_DW  = 8'd32,      //32DW or 64 DW or 128 DW. Check your PCIe hardware, e.g  lspci -vv -d :30

    // Do not override parameters below this line
    parameter KEEP_WIDTH = C_DATA_WIDTH / 8,              // TSTRB width
    parameter TCQ        = 1
)(
    // pcie Core
    input         pcie_user_clk,
    input         pcie_user_rst_n,
    input 		  s_axis_tx_tvalid,
    input  [5:0]  tx_buf_av,  //  Transmit Buffers Available
    output        cfg_interrupt,
    input		  cfg_interrupt_rdy,

    //registers interface
    input   [31:0]  control_reg,
    output  [7:0]   dma_status,
    input           dma_compl_acq, // No need for MSI irq
    input   [20:0]  dma_size, // in Bytes. MAX size 1 MB = 8k / 4k / 2k TLPs
    input   [31:0]  dma_ha_ch0, // dma ch0 host address
    //input   [31:0]  dma_ha_ch1,
    //input req_compl_wd_rx,
    output  reg [7:0]  dma_tlp_payload_size,       //to TX-DMA-engine - DMA BYTE SIZE in DW
    output  reg [31:0] host_addr_tx,		  //to TX-DMA-engine - addr_host_out
    output [C_DATA_WIDTH-1:0] dma_data_tx,    //to TX-DMA-engine - DMA data
    // Handshake with PIO_DMA_TX_ENGINE
    input   fifo_rd_en,
    output  tlp_req,       //to TX-DMA-engine - Start TLP request
    input   dma_tlp_compl_done,

	//input  [31:0]   clk_2_cnt,  // clk_100 domain
	//output [63:0]   dma_pkt_cnt, // Not used

    //DMA irq input data channel
    input           adc_data_clk, 	//I - clk_100
    input [63:0]    adc_data,
    output          data_ready_ch0,
    input           adc_data_en
    //input [511:0]   data_in_ch1,
    //output          data_ready_ch1,
    //input           data_valid_ch1
);

    `include "control_word_bits.vh"

    localparam MAX_PAYLOAD  = (MAX_PAYLOAD_DW * 4); // 128B / 256/ 512

    (* mark_debug="yes" *) wire [15:0]  num_full_tlps; // Max = 2^15 =  32768 TLPs = 4 MB
    wire [18:0] remain_dw; //18:0?
    wire [6:0] remainder;       // Max 127 DW = 508 Bytes
    assign num_full_tlps    = dma_size[20:2] / MAX_PAYLOAD_DW;  //16384B -> 128 packets of 32DW each or 16QW
    assign remain_dw        = num_full_tlps * MAX_PAYLOAD_DW;
    assign remainder        = (remain_dw < dma_size[20:2]) ?
                              (dma_size[20:2] - remain_dw) : 7'b0; // should be 0? check widths
    //assign rem = a % b;
    //assign quot = a / b;

    //(* mark_debug="yes" *) wire   dma_payload_not_zero;
    //assign dma_payload_not_zero = (dma_size != 0)? 1'b1 : 1'b0;
    wire  dma_ha_ch0_not_zero   = (dma_ha_ch0 != 0)? 1'b1 : 1'b0; //Host must define previously destination address
    //wire  dma_ha_ch1_not_zero   = (dma_ha_ch1 != 0)? 1'b1 : 1'b0;

    //assign req_compl_wd_tx = 1'b1; //allways read with data (0 for IO read)- not used

    (* mark_debug="yes" *) reg cfg_interrupt_r;
    assign cfg_interrupt = cfg_interrupt_r;

    (* mark_debug="yes" *) wire dmach0_en_i;
    //(* mark_debug="yes" *) wire streame_i = control_reg[`STREAME_BIT];
    assign dmach0_en_i = control_reg[`DMAE_BIT] ;
    reg [2:0] dmae_r;
    //reg [63:0] dma_pkt_cnt_r;
    //assign dma_pkt_cnt = dma_pkt_cnt_r;
    (* mark_debug="yes" *) wire DMAiE = control_reg[`DMAiE_BIT]; //
    reg dma_ch_sel_r = 1'b0; // 0: dma_irq, 1:dma_poll

    localparam DMA_SM_TLP_RST               = 3'b000;
    localparam DMA_SM_1ST_TLP               = 3'b001;
    localparam DMA_SM_2ND_TLP               = 3'b010;
    localparam DMA_SM_TLP_WAIT_COMPL        = 3'b011;
    //localparam DMA_SM_CH1_1ST_TLP           = 3'b100;
    //localparam DMA_SM_CH1_2ND_TLP           = 3'b101;
    //localparam DMA_SM_CH1_TLP_WAIT_COMPL    = 3'b110;
    localparam DMA_SM_REQ_END               = 3'b111;

    //########################## BUILD DMA PACKET ##############################//
    (* mark_debug="yes" *) reg [2:0]  state_rd_wr;
    (* mark_debug="yes" *) reg  tlp_req_r;
    assign tlp_req = tlp_req_r;

    (* mark_debug="yes" *) reg 	req_single_dma_flag;
    (* mark_debug="yes" *) wire fifo_irq_rd_i;
    (* mark_debug="yes" *) reg [14:0]   tlps2go;
    (* mark_debug="yes" *) reg          dmaC_r;
    reg [2:0] 	dma_current_buffer;
    //reg 	dmach1_up_buff_r = 0;

    assign fifo_irq_rd_i = (dma_ch_sel_r)? 1'b0 : fifo_rd_en;
    wire  fifo_1_rd_i    = (dma_ch_sel_r)? fifo_rd_en : 1'b0;
    wire prog_full_ch0, prog_almost_full;
    (* mark_debug="yes" *)  wire prog_empty_ch0;
    //(* mark_debug="yes" *)  wire  fifo_empty_i;
    //(* mark_debug="yes" *)  wire  fifo_full_i;
// prog_full_ch1 This signal in sync with clk_100_mmcm
    assign dma_status = {3'b0,  prog_empty_ch0, dmaC_r, dma_current_buffer};

    always @ (posedge pcie_user_clk) begin
        if (!pcie_user_rst_n) begin
            dmae_r              <= #TCQ 0;
            req_single_dma_flag	    <= #TCQ 1'b0;
            tlp_req_r	        <= #TCQ 0;
            tlps2go             <= #TCQ 15'b0;
            dma_tlp_payload_size     <= #TCQ 0;
            host_addr_tx        <= #TCQ 32'b0;
            dma_current_buffer  <= #TCQ 3'b0; // start at buff = 0
            //dma_pkt_cnt_r       <= #TCQ 0;
            dma_ch_sel_r <= 1'b0;

            state_rd_wr 	    <= #TCQ DMA_SM_TLP_RST;
        end
        else begin
            dmae_r <= {dmae_r[1:0], dmach0_en_i}; // Shift register for delay

            if(dmae_r[2:1] == 2'b01)  // Detect L->H on DMAE
                req_single_dma_flag	    <= #TCQ 1'b1;
            case (state_rd_wr)
                DMA_SM_TLP_RST: begin  // waiting streaming fifo ready
                    if ( req_single_dma_flag && dma_ha_ch0_not_zero) begin // waiting for new user DMA request
                    //else if ( dmach0_en_i && dma_ha_ch0_not_zero) begin // waiting for new user DMA request
                        dma_ch_sel_r           <= #TCQ 1'b0;
                        state_rd_wr 	    <= #TCQ DMA_SM_1ST_TLP;
                    end
                    else begin
                        tlp_req_r	    <= #TCQ 1'b0;
                        dma_tlp_payload_size    <= #TCQ 0;
                    end
                end

                DMA_SM_1ST_TLP: begin       //Build first tlp for request
                    req_single_dma_flag	<= #TCQ 1'b0;
                    if ((tx_buf_av > 6'h01) && !prog_empty_ch0) begin
                        host_addr_tx 		<= #TCQ dma_ha_ch0;
                        tlp_req_r 	        <= #TCQ 1'b1;

                        if (num_full_tlps == 16'b0) begin  // single packet not full: remainer DW
                            dma_tlp_payload_size    <= #TCQ {1'b0, remainder[6:0]}; // -1 ??
                            tlps2go  		    <= #TCQ 0;
                        end
                        else begin
                            dma_tlp_payload_size    <= #TCQ MAX_PAYLOAD_DW;
                            tlps2go  		    <= #TCQ num_full_tlps - 1'b1;
                        end
                        state_rd_wr         <= #TCQ DMA_SM_TLP_WAIT_COMPL;
                    end
                    else if ( !dmach0_en_i ) begin// Just in case, don't wait forever...
                        state_rd_wr 	<= #TCQ DMA_SM_TLP_RST;
                    end
                end
                DMA_SM_2ND_TLP: begin // 1      //request new tlp from same packet

                    if ((tx_buf_av > 6'h01) && !prog_empty_ch0) begin
                        host_addr_tx <= #TCQ {host_addr_tx + MAX_PAYLOAD};

                        if (tlps2go != 0 ) begin
                            dma_tlp_payload_size    <= #TCQ MAX_PAYLOAD_DW;
                            tlps2go 			<= #TCQ tlps2go -1'b1;
                            tlp_req_r           <= #TCQ 1'b1;
                            state_rd_wr 	    <= #TCQ DMA_SM_TLP_WAIT_COMPL;
                        end
                        else begin
                            if ( remainder != 0) begin
                                dma_tlp_payload_size    <= #TCQ {1'b0, remainder[6:0]};
                                tlp_req_r           <= #TCQ 1'b1;
                                state_rd_wr         <= #TCQ DMA_SM_TLP_WAIT_COMPL;
                            end
                            else begin //No more TLPs on this request.
                                dma_current_buffer  <= #TCQ dma_current_buffer + 3'b001;
                                dma_tlp_payload_size 	<= #TCQ 0;
                                tlp_req_r		    <= #TCQ 1'b0;
                                state_rd_wr 		<= #TCQ DMA_SM_REQ_END; //
                            end
                        end
                    end
                    else if ( !dmach0_en_i ) begin//  don't wait forever...
                        state_rd_wr 	<= #TCQ DMA_SM_TLP_RST;
                    end
                end //DMA_SM_2ND_TLP

                DMA_SM_TLP_WAIT_COMPL: begin	//  Sending QWs from FIFO, waiting PIO_DMA_TX engine ...
                    if(dma_tlp_compl_done == 1'b1) begin
                        tlp_req_r       <= #TCQ 1'b0;
                        state_rd_wr     <= #TCQ DMA_SM_2ND_TLP;  // Send next (if any) TLPs
                    end
                    else if ( dmach0_en_i == 1'b0) begin// Just in case, don't wait forever...
                        tlp_req_r       <= #TCQ 1'b0;
                        state_rd_wr 	<= #TCQ DMA_SM_TLP_RST; //
                    end

                end

 
                DMA_SM_REQ_END: begin //end Request
                    state_rd_wr     <= #TCQ DMA_SM_TLP_RST;
                end //DMA_SM_REQ_END

                default :
                    state_rd_wr 	<= #TCQ DMA_SM_TLP_RST;
            endcase
        end
    end

//##################################################################
//########################## DMAiE INTERRUPT ENABLE ################
    (* mark_debug="yes" *) reg	[2:0] 	start_interrupt_r;

//######################## MSI INTERRUPT MODE ######################
    (* mark_debug="yes" *)  reg  [1:0]  state_irq;

    always @ (posedge pcie_user_clk) //begin
        if (!pcie_user_rst_n) begin
            //count_int        			<= #TCQ 32'b0;
            cfg_interrupt_r  		     <= #TCQ 1'b0;
            dmaC_r 			         <= #TCQ 1'b0;
            state_irq			     <= #TCQ 2'b0;
            start_interrupt_r        <= #TCQ 3'b0;
        end
        else begin
            start_interrupt_r[2:1] <= start_interrupt_r[1:0]; // Shift register for delay
            //if (len_i == 1'b1 && state_rd_wr == DMA_SM_TLP_WAIT_REQ_COMPL)  //new interrupt ! rest
            if ( state_rd_wr == DMA_SM_REQ_END)  //
                start_interrupt_r[0] <= #TCQ 1'b1;
            else
                start_interrupt_r[0] <= #TCQ 1'b0;
            case (state_irq)
                2'b00: //begin
                    if (DMAiE && start_interrupt_r[2]) begin // && (!dmaC_r)) begin
                        cfg_interrupt_r	<= #TCQ 1'b1;
                        dmaC_r		 	<= #TCQ 1'b1;
                        //count_int  		<= #TCQ count_int + 1'b1;
                        state_irq		<= #TCQ 2'b01;
                    end
                2'b01:
                    if (cfg_interrupt_rdy) begin
                        cfg_interrupt_r	<= #TCQ 1'b0;
                        state_irq		<= #TCQ 2'b00;
                    end
                2'b10: //begin TODO needed for MSI irqs?
                    if (!dma_compl_acq) begin
                        dmaC_r 			<= #TCQ 1'b0;
                        state_irq		<= #TCQ 2'b00;
                    end
                default :
                    state_irq 	    <= #TCQ 2'b00;

            endcase
        end

    wire dma_fifo_arst = control_reg[`DMA_RST_BIT]; // Asynchronous reset
    wire dma_fifo_srst;// = dma_fifo_arst; // for now...
    wire  [63:0] fifo_data_out;//, fifo_irq_data_out, fifo_poll_data_out;
    //assign fifo_data_out = (dma_ch_sel_r)? fifo_poll_data_out : fifo_irq_data_out ;
    // Swap data bytes here for Pcie Endianess
    assign  dma_data_tx = {fifo_data_out[39:32],fifo_data_out[47:40],fifo_data_out[55:48],fifo_data_out[63:56],
        fifo_data_out[7:0], fifo_data_out[15:8], fifo_data_out[23:16], fifo_data_out[31:24]};
    assign data_ready_ch0 = !prog_full_ch0;
    //assign data_ready_ch1 = !prog_full_ch1;

/*
// xpm_cdc_async_rst: Asynchronous Reset Synchronizer
// Xilinx Parameterized Macro, version 2019.1
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF(4), // DECIMAL; range: 2-10
        //.INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        //.RST_ACTIVE_HIGH(1) // DECIMAL; 0=active low reset, 1=active high reset
        .INIT(0), // DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization
// registers to 1<Paste>
    )
    xpm_cdc_async_rst_inst (
        .dest_arst(dma_fifo_srst), // 1-bit output: src_arst asynchronous reset signal synchronized to destination
        // clock domain. This output is registered. NOTE: Signal asserts asynchronously
        // but deasserts synchronously to dest_clk. Width of the reset signal is at least
        // (DEST_SYNC_FF*dest_clk) period.
        .dest_clk(adc_data_clk), // 1-bit input: Destination clock.
        .src_arst(dma_fifo_arst) // 1-bit input: Source asynchronous reset signal.
    );
*/
// xpm_cdc_sync_rst: Synchronous Reset Synchronizer
    // // Xilinx Paraprog_full_cmeterized Macro, version 2019.1
	 xpm_cdc_sync_rst #(
	 .DEST_SYNC_FF(4), // DECIMAL; range: 2-10
	 .INIT(0), // DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization
    // // registers to 1
    .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0) // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    )
    xpm_cdc_sync_rst_inst (
        .dest_rst(dma_fifo_srst), // 1-bit output: src_rst synchronized to the destination clock domain. This output
        // is registered.
		 .dest_clk(adc_data_clk), // 1-bit input: Destination clock.
		 .src_rst(dma_fifo_arst) // 1-bit input: Source reset signal.
		 );
	// End of xpm_cdc_sync_rst_inst instantiation

// End of xpm_cdc_async_rst_inst instantiation
//############## DMA  Raw data FIFO #########################
    wire wr_rst_busy, rd_rst_busy;
    //wr_en/rd_en should not be toggled when reset (rst) or wr_rst_busy or rd_rst_busy is asserted.
    wire wr_en_ch0, rd_en_ch0;
    assign wr_en_ch0 = (wr_rst_busy)? 1'b0: adc_data_en;
    assign rd_en_ch0 = (rd_rst_busy)? 1'b0: fifo_irq_rd_i;

wire [16:0] wr_data_cnt_ch0;
 wire read_en_n;
/*
//assign read_en_n=(adc_data_en)?fifo_irq_rd_i:((prog_full_ch0)?1'b1:1'b0);
reg rd_en_n, buff;
always  @(posedge pcie_user_clk)begin
if(prog_full_ch0==1'b1 && adc_data_en==1'b0) {rd_en_n,buff}<={buff,1'b1};
else if(prog_full_ch0==1'b0 && adc_data_en==1'b0) {rd_en_n,buff}<={buff,1'b0};
else if(adc_data_en){rd_en_n,buff}<={buff,fifo_irq_rd_i};

end
*/
reg read_en,buff1,write_en,buff2;
reg [1:0] state1, n_state;
always @(*) begin
case (state1)
   2'b00: begin
   if(wr_data_cnt_ch0 > 1050) n_state<=2'b01;
   //{write_en,buff2}<={buff2,1'b1};
  // {read_en,buff1}<={buff1,1'b0};
   //write_en<=1'b1;
   //read_en<=1'b0;
   end
   2'b01: begin
   if(wr_data_cnt_ch0 <1000 && adc_data_en==1'b0) n_state<=2'b00;
   else if(adc_data_en==1'b1) n_state<=2'b10;
  // {write_en,buff2}<={buff2,1'b0};
  // {read_en,buff1}<={buff1,1'b1};
  // write_en<=1'b0;
   //read_en<=1'b1;
   end
   2'b10:begin
   if(dmach0_en_i == 1'b0)n_state<=2'b00;
   //write_en<=1'b1;
   //read_en<=fifo_irq_rd_i;
   //{write_en,buff2}<={buff2,1'b1};
   //{read_en,buff1}<={buff1,fifo_irq_rd_i};
   end
   default: n_state<=2'b00;
   endcase
end
always @(posedge pcie_user_clk) state1<=n_state;

wire read_en_m, write_en_m;
mux3 rmu(.sel(state1),
.a(1'b0),
.b(1'b1),
.c(rd_en_ch0),
.out(read_en_m)
);

mux3 wmu(.sel(state1),
.a(1'b1),
.b(1'b1),
.c(wr_en_ch0),
.out(write_en_m)
);



fifo_generator_0(
 .rst (dma_fifo_srst),
    .wr_clk (adc_data_clk),
    .rd_clk (pcie_user_clk),
    .din (adc_data),
    .wr_en (write_en_m),
    .rd_en (read_en_m),
    .dout (fifo_data_out),
    .full (),
    .almost_full (prog_almost_full),
    .empty (),
    .almost_empty (),
    .wr_data_count (wr_data_cnt_ch0 ),
    .prog_full (prog_full_ch0),
    .prog_empty (prog_empty_ch0),
    .wr_rst_busy (wr_rst_busy),
    .rd_rst_busy (rd_rst_busy)
);

/*
`define __XPM_FIFO__
`ifdef  __XPM_FIFO__

// wire  [11:0] wr_data_cnt_ch0;
// xpm_fifo_async: Asynchronous FIFO
// Xilinx Parameterized Macro, version 2019.1 UG953
    xpm_fifo_async #(
        .CDC_SYNC_STAGES(2), // DECIMAL
        .DOUT_RESET_VALUE("0"), // String
        .ECC_MODE("no_ecc"), // String
        .FIFO_MEMORY_TYPE("block"), // String
        .FIFO_READ_LATENCY(0), // DECIMAL If READ_MODE = "fwft", then the only applicable value is 0.
        .FIFO_WRITE_Dpcie_user_clkEPTH(32768), // DECIMAL,  FIFO_READ_DEPTH = 16384:128us 
        .FULL_RESET_VALUE(0), // DECIMAL Sets full, almost_full and prog_full during reset
        .PROG_EMPTY_THRESH(32), //Max_Value=(FIFO_WRITE_DEPTH-3)-(READ_MODE_VAL*2), error in UG953? should be Max=FIFO_READ_DEPTH - ...? One 32DW TLP is 16 rd
        .PROG_FULL_THRESH(5000), // DECIMAL PROG_FULL_THRESH value must be between .
        //.RD_DATA_COUNT_WIDTH(7), // DECIMAL log2(FIFO_READ_DEPTH)+1
        .READ_DATA_WIDTH(64), // DECIMAL
        .READ_MODE("fwft"), // String READ_MODE_VAL = 1
        .RELATED_CLOCKS(0), // DECIMAL, wr_clk and rd_clk not related
//        .SIM_ASSERT_CHK(0), // DECIMAL; 0 = disable simulation messages, 1=enable simulation messages
        .USE_ADV_FEATURES("0202"), // String
        //    Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1
        //    Setting USE_ADV_FEATURES[2] to 1 enables wr_data_count; Default value of this bit is 1
        //    Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1
        .WAKEUP_TIME(0), // DECIMAL Disable Sleep
        .WRITE_DATA_WIDTH(64), // DECIMAL
        .WR_DATA_COUNT_WIDTH(16) // DECIMAL the width should be log2(FIFO_WRITE_DEPTH)+1.
    )
    dma_fifo_0 (fmcjesdadc1
        .almost_empty(), // 1-bit output: Almost Empty : When asserted, this signal indicates that
        // only one more read can be performed before the FIFO goes to empty.
        .almost_full(prog_almost_full), // 1-bit output: Almost Full: When asserted, this signal indicates that
        // only one more write can be performed before the FIFO is full.
        .data_valid(), /prog_full_ch0/ 1-bit output: Read Data Valid: When asserted, this signal indicates
        // that valid data is available on the output bus (dout).
        //.dbiterr(dbiterr), // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
        // a double-bit error and data in the FIFO core is corrupted.
        .dout(fifo_data_out), // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
        // when reading the FIFO.
        .empty(), // 1-bit output: Empty Flag: When asserted, this signal indicates that the
        // FIFO is empty. Read requests are ignored when the FIFO is empty,
        // initiating a read while empty is not destructive to the FIFO.
        .full(), // 1-bit output: Full Flag: When asserted, this signal indicates that the
        // FIFO isdma_fifo_srst full. Write requests are ignored wh/home/francisco/tmp/hdl/projects/fmcjesdadc1/kc705/esther-trigger-hdl/src/hdl/pcieen the FIFO is full,
        // initiating a write when the FIFO is full is not destructive to the
        // contents of the FIFO.
        .overflow(), // 1-bit output: Overflow: This signal indicates that a write request
        // (wren) during the prior clock cycle was rejected, because the FIFO is
        // full. Overflowing the FIFO is not destructive to the contents of the
        // FIFO.
        .prog_empty(prog_empty_ch0), // 1-bit output: Programmable Empty: This signal is asserted when the
        // number of words in the FIFO is less than or equal to the programmable
        // empty threshold value. It is de-asserted when the number of words in
        // the FIFO exceeds the programmable empty threshold value.
        .prog_full(prog_full_ch0), // 1-bit output: Programmable Full: This signal is asserted when the
        // number of words in the FIFO is greater than or equal to the
        // programmable full threshold value. It is de-asserted when the number of
        // words in the FIFO is less than the programmable full threshold value.
        .rd_data_count(), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
        // number of words read from the FIFO.
        .rd_rst_busy(rd_rst_busy), // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
        // domainadc_data_clk is currently in a reset state.
        .sbiterr(), // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
        .dbiterr(), // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
        // and fixed a singfmcjesdadc1le-bit error.
        .underflow(), // 1-bit output: Underflow: Indicates that the read request (rd_en) during
        // the previous clock cycle was rejected because the FIFO is empty. Under
        // flowing the FIFO is not destructive to the FIFO.
        .wr_ack(), // 1-bit output: Write Acknowledge: This signal indicates that a write
        // request (wr_en) during the prior clock cycle is succeeded.
        .wr_data_count(wr_data_cnt_ch0), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
        // the number of words written into the FIFO.
        .wr_rst_busy(wr_rst_busy), // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
        // write domain is currently in a reset state.
        .din(adc_data), // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
        // writing the FIFO.
        .injectdbiterr(1'b0fmcjesdadc1), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
        // the ECC feature is used on block RAMs or UltraRAM macros.
        .injectsbiterr(1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
        // the ECC feature is used on block RAMs or UltraRAM macros.
        .rd_clk(pcie_user_clk), // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
        // running clock.
        .rd_en(read_en), // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
        // signal causes data (on dout) to be read from the FIFO. Must be held
        // active-low when rd_rst_busy is active high.
        .rst(dma_fifo_srst), // 1-bit input: /home/francisco/tmp/hdl/projects/fmcjesdadc1/kc705/esther-trigger-hdl/src/hdl/pcieReset: Must be synchronous to wr_clk. The clock(s) can be
        // unstable at the time of applying reset, but reset must be released only
        // after the clock(s) is/are stable.
        .sleep(1'b0), // 1fmcjesdadc1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
        // block is in power saving mode.
        .wr_clk(adc_data_clk), // 1-bit input: Write clock: Used for write operation. wr_clk must be a
        // free running clock.
        .wr_en(write_en) // 1-bit input: Write Enable: If the FIFO is not full, asserting this
        // signal causes data (on din) to be written to the FIFO. Must be held
        // active-low when rst or wr_rst_busy is active high.
    );
`else

    // Write depth ... 2047 Read depth 16373
    // Constant Full threshold 4000
    dma_fifo dma_fifo_0 (fmcjesdadc1
        .rst(dma_fifo_arst),
        .wr_clk(adc_data_clk),
        .wr_en(wr_en_ch0),//
        .din(adc_data), // adc_data   512b = 64 Bytes
        .rd_clk(pcie_user_clk),
        .rd_en(rd_en_ch0 ),
        .dout(fifo_data_out),  // PCIe 64b, 8B
        .empty(),
        .full(),
        .prog_full(prog_full_ch0),
        //.prog_empty_thresh(dma_size[16:3]),// Max= (h4000-1) = 16383 (64b),  2048 * 8 = 16kB input wire [13 : 0] prog_empty_thresh h800/2048 * 8 = 16kB
        .prog_empty(prog_/home/francisco/tmp/hdl/projects/fmcjesdadc1/kc705/esther-trigger-hdl/src/hdl/pcieempty_ch0),
        .wr_rst_busy(wr_rst_busy), // O safety circuit
        .rd_rst_busy(rd_rst_busy)  // O
    );

`endif //  __XPM_FIFO__
*/

endmodule
