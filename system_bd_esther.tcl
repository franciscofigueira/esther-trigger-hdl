#
#source ./esther-trigger-hdl/system_bd_esther.tcl
#
open_bd_design {./fmcjesdadc1_kc705.srcs/sources_1/bd/system/system.bd}
source ../../scripts/adi_board.tcl
#
create_bd_port -dir O adc_valid_a
ad_connect axi_ad9250_0_core/adc_valid_a adc_valid_a
create_bd_port -dir O adc_enable_a
ad_connect axi_ad9250_0_core/adc_enable_a adc_enable_a
create_bd_port -dir O -from 31 -to 0 adc_data_a
ad_connect axi_ad9250_0_core/adc_data_a adc_data_a
#
create_bd_port -dir O adc_valid_b
ad_connect axi_ad9250_0_core/adc_valid_b adc_valid_b
create_bd_port -dir O adc_enable_b
ad_connect axi_ad9250_0_core/adc_enable_b adc_enable_b
create_bd_port -dir O -from 31 -to 0 adc_data_b
ad_connect axi_ad9250_0_core/adc_data_b adc_data_b
#
create_bd_port -dir O adc_valid_c
ad_connect axi_ad9250_1_core/adc_valid_a adc_valid_c
create_bd_port -dir O adc_enable_c
ad_connect axi_ad9250_1_core/adc_enable_a adc_enable_c
create_bd_port -dir O -from 31 -to 0 adc_data_c
ad_connect axi_ad9250_1_core/adc_data_a adc_data_c
#
create_bd_port -dir O adc_valid_d
ad_connect axi_ad9250_1_core/adc_valid_b adc_valid_d
create_bd_port -dir O adc_enable_d
ad_connect axi_ad9250_1_core/adc_enable_b adc_enable_d
create_bd_port -dir O -from 31 -to 0 adc_data_d
ad_connect axi_ad9250_1_core/adc_data_b adc_data_d
save_bd_design
close_bd_design [get_bd_designs system]
