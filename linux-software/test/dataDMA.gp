#!/usr/bin/env gnuplot
#
#
clear
# set term png
set term png enhanced font '/usr/share/fonts/liberation/LiberationSans-Regular.ttf' 12
set output 'dataDMA.png'

#set xlabel 'Time (s)'
set xlabel 'Samp'
#set xlabel 'mSec'
#set ylabel 'Amp (V)'
set ylabel 'Amp (LSB)'
set title 'ESTHER  DMA data 05-11-2019'

dfile='dataDMA.bin'

sampl_freq =  125.0e6
sampl_per = 1.0 / sampl_freq
scaleY= 1.0
#scaleY= 0.0001729
plot_dec =7
# 200
firstl = 1
endl = 1e6

#

#plot dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($1)*scaleY+1e3) with lines lt 1 lw 1  title 'ch0', \
#     dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($2)*scaleY+2e3) with lines lt 2 lw 1  title 'ch1', \
#     dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($3)*scaleY) with lines lt 3 lw 1  title 'Ch2', \
#     dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($4)*scaleY) with lines lt 4 lw 1  title 'Ch3', \

#plot dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($5)*scaleY) with lines lt 5 lw 1  title 'Ch4', \
#     dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($6)*scaleY) with lines lt 6 lw 1  title 'Ch5', \
#     dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($7)*scaleY) with lines lt 7 lw 1  title 'Ch6'
#     #dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($8)*scaleY) with lines lt 8 lw 1  title 'Ch7', \
#     #dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($9)*scaleY) with lines lt 1 lw 2  title 'Ch8', \
#     #dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($10)*scaleY) with lines lt 2 lw 2  title 'Ch9', \

#plot dfile binary format='%32int32' every plot_dec::firstl:0:endl  using ($0*1):(($11)*scaleY) with lines lt 3 lw 2  title 'Ch10', \

plot dfile binary format='%4int16' every plot_dec::firstl:0:endl  using ($0*1):(($1)*scaleY) with lines lt 1 lw 1  title 'ch0', \
     dfile binary format='%4int16' every plot_dec::firstl:0:endl  using ($0*1):(($2)*scaleY) with lines lt 1 lw 1  title 'ch0', \
     dfile binary format='%4int16' every plot_dec::firstl:0:endl  using ($0*1):(($3)*scaleY) with lines lt 2 lw 1  title 'ch2', \
     dfile binary format='%4int16' every plot_dec::firstl:0:endl  using ($0*1):(($3)*scaleY) with lines lt 2 lw 1  title 'ch2'

#set term x11
set term wxt
replot
pause -1 "Hit return to continue"
