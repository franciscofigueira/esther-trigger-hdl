# Other constraints in:
#/home/bernardo/FPGA/ad-ipfn-hdl/projects/fmcjesdadc1/kc705/system_constr.xdc
#/home/bernardo/FPGA/ad-ipfn-hdl/projects/common/kc705/kc705_system_constr.xdc
#First LED
#set_property -dict  {PACKAGE_PIN  AB8   IOSTANDARD  LVCMOS15} [get_ports gpio_bd[9]]
# PACKAGE_PIN AB8 [get_ports GPIO_LED_0_LS] 
#
################################################################################
##### SMA CLOCKS and GPOI
###############################################################################
set_property IOSTANDARD LVCMOS25 [get_ports user_sma_clk_*]
#user_sma_clk_p SMA J11
set_property PACKAGE_PIN L25 [get_ports user_sma_clk_p]
#create_clock -period 100.000 -name sma_clk [get_ports user_sma_clk_p]
set_property PACKAGE_PIN K25 [get_ports user_sma_clk_n]

set_property IOSTANDARD LVCMOS25 [get_ports user_sma_gpio_*]
set_property PACKAGE_PIN Y23 [get_ports user_sma_gpio_p]
set_property PACKAGE_PIN Y24 [get_ports user_sma_gpio_n]
#set_property IOSTANDARD LVCMOS25 [get_ports user_sma_gpio_n]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_false_path -from [get_pins {i_system_wrapper/system_i/axi_gpio/U0/gpio_core_1/Dual.gpio2_Data_Out_reg[*]/C}] 
set_false_path -from [get_pins {i_system_wrapper/system_i/axi_gpio/U0/gpio_core_1/Dual.gpio_Data_Out_reg[*]/C}] 

set_false_path -from [get_pins {i_trigger_gen/pulse_delay_r_reg[*]/C}] 
set_false_path -from [get_pins {i_trigger_gen/trigger0_r_reg/C}] 
set_false_path -from [get_pins {i_trigger_gen/trigger1_r_reg/C}] 

