#!/bin/bash

export PATH="/c/questasim64_10.7c/win64":$PATH

reset
TOP_TB=tb_conv_top # name top testbench

# prepare workspace
alias vlb='reset; rm -rf work; mkdir -p log; vlib work'
alias vlgr='vlog -f filelist_rtl.f  +cover=bcefs -l ./log/vlogr.log'
alias vlgt='vlog -f filelist_tb.f -l log/vlogt.log'

# compile rtl and testbench
alias vlg='vlgr; vlgt'

# run simulation with UVM lib
alias vsm='vsim -c ${TOP_TB} -wlf vsim.wlf -solvefaildebug -assertdebug -assertcover -sva -coverage -voptargs=+acc -l ./log/vsim.log -do "add wave -r /${TOP_TB}/*; run -all; quit"'

# run simulation without UVM lib
alias sim='vlb; vlg; vsm'

# view wave form
alias viw='vsim -view vsim.wlf -do wave.do &'

alias run='vsm'

#gen report
alias rep='vcover report -stmtaltflow -html -htmldir report -source -details  coverage.ucdb'
alias viw_rep='rep; firefox ./report/index.html'
