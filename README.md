# esther-trigger-hdl
Vivado HDL files for ESTHER trigger system using KC705 and AD fmcjesdadc1 board

## Getting started
### Prerequisites

 * [Vivado Design Suite](https://www.xilinx.com/support/download.html)
 ### How to build a project

To build a project, checkout the [latest release](https://github.com/analogdevicesinc/hdl/releases), after that just **cd** to the
project that you want to build

 ```
 [~]git clone https://github.com/analogdevicesinc/hdl
 [~]git checkout hdl_2018_r2
 [~]cd hdl/projects/fmcjesdadc1/kc705
 [~]source /home/Xilinx/Vivado/2018.2/settings64.sh
 [~]make
 [~]git clone https://github.com/bernardocarvalho/esther-trigger-hdl
```

Open project in Vivado and 

* From  TCL console run
 ```
source ./esther-trigger-hdl/system_bd_esther.tcl
 ```
 * Select system_bd file and "Generate Output Product"
 * Create HDL wrapper (Let Vivado manage created wrapper)
 * Replace file system_top.v with esther-trigger-hdl/str/hdl
 * Add trigger_gen.v and kc705_sma_constr.xdc


