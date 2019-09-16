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

Open project in Vivado and run

* From  TCL console run
source ./esther-trigger-hdl/system_bd_esther.tcl
