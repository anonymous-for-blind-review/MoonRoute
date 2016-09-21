#!/bin/bash

cd /root/MoonGen/build

mkdir ~/results

testbed-rapidsync-reset
testbed-rapidsync-set '{ "end$i": ["tallinn", "palanga"], "start$i": ["tallinn", "palanga"] }' 

w=24

for i in $(seq 1 10) ; do
  for j in $(seq 1 4) ; do
    echo "syncing on  start$(( ($i-1) * 10 + ($j-1)))"
    testbed-sync start$(( ($i-1) * 10 + ($j-1)))
    echo " OK"
    #if [ "$j" -gt 5 ]; then
    sleep 7
    #fi
    freq=$((($i-1)*200 + 1600))
    /root/MoonGen/build/MoonGen ~/load.lua 0 ~/results/run cfg_${freq}_run_${j}_ 29
    echo "finished run $i $j freq was ${freq}"
    echo "syncing on  end$(( ($i-1) * 10 + ($j-1)))"
    testbed-sync end$(( ($i-1) * 10 + ($j-1)))
    echo " OK"
  done
  w=$((w + 1))
done
