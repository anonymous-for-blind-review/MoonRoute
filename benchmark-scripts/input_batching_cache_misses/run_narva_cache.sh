#!/bin/bash

cd /root/MoonGen/build

testbed-rapidsync-reset
testbed-rapidsync-set '{ "end$i": ["narva", "klaipeda"], "start$i": ["narva", "klaipeda"] }' 

maxa=11
maxi=7
maxj=4

for a in $(seq 11 $maxa) ; do  # input batching
  for i in $(seq 7 $maxi) ; do # output batching
    for j in $(seq 1 $maxj) ; do
      cat ~/cfg_part1.lua > ~/cfg.lua
      inputb=$((2**($a-1)))
      outputb=$(( 2**$i ))
      echo "config[\"txQueueSize\"] = ${outputb}" >> ~/cfg.lua
      echo "config[\"rxBurstSize\"] = ${inputb}" >> ~/cfg.lua
      cat ~/cfg_part2.lua >> ~/cfg.lua
      echo "starting: inputBatch = ${inputb}   outputBatch = ${outputb}  a=$a  i=$i j=${i}"
      echo "sync on  start$(( ($a-1) * $maxi * $maxj + ($i-1) * $maxj + ($j-1)))"
      testbed-sync start$(( ($a-1) * $maxi * $maxj + ($i-1) * $maxj + ($j-1)))
      echo " OK"
      /root/MoonGen/build/MoonGen ~/router.lua 12&
      sleep 30
      /root/pmu-tools-master/ocperf.py stat -C 1 -x , -e mem_load_uops_retired.llc_miss,mem_load_uops_retired.l2_miss,mem_load_uops_retired.l1_miss,branch-misses sleep 1 2>&1 | /root/miss_extract.pl "[input_${inputb}_output_${outputb}_run_${j}_" >> /root/results/cacherun
      sleep 5
      killall MoonGen
      echo "finished: inputBatch = ${inputb}   outputBatch = ${outputb}  a=$a  i=$i j=${i}"
      echo "sync on  end$(( ($a-1) * $maxi * $maxj + ($i-1) * $maxj + ($j-1)))"
      testbed-sync end$(( ($a-1) * $maxi * $maxj + ($i-1) * $maxj + ($j-1)))
      echo " OK"
    done
  done
done
