vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 \
"../../../../basys3_soc.srcs/sources_1/ip/xadc_wiz_4/xadc_wiz_4.v" \


vlog -work xil_defaultlib \
"glbl.v"
