#!/bin/bash

while true;
do
  tx_bytes=$(cat /sys/devices/virtual/net/$1/statistics/tx_bytes);
  rx_bytes=$(cat /sys/devices/virtual/net/$1/statistics/rx_bytes);
  echo -e "$(($(date +%s%N)/1000000))\t$tx_bytes\t$rx_bytes" >> $2;
  sleep $3;
done
