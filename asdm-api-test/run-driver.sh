#!/usr/bin/env bash
# 后台驱动脚本：全量执行 run-all.sh 并落盘结果标记
TS="$(date +%Y%m%d_%H%M%S)"
export ASDM_RUN_TS="$TS"
cd "$(dirname "$0")"
printf '%s' "$TS" > results/driver-ts.txt
bash run-all.sh > "results/console_${TS}.log" 2>&1
echo "$?" > "results/rc_${TS}.txt"
echo ok > "results/done_${TS}.txt"
