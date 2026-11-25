#!/usr/bin/env bash
# ============================================================================
# run-all.sh — 批量执行所有领域测试脚本并汇总结果
# 用法:
#   ./run-all.sh                 # 顺序执行 tests/ 下全部领域脚本
#   ./run-all.sh auth user_org   # 只执行指定领域（slug，见文件名 test_<slug>_domain.sh）
# 环境变量与单个脚本一致（见 common.sh 头部）。
# 结果: 逐域输出 PASS/FAIL/SKIP，末尾汇总；任一域失败退出码为 1。
# ============================================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

# ---- 结果落盘目录（可用 ASDM_RUN_TS 固定；供 gen/report.js 解析）----
RUN_TS="${ASDM_RUN_TS:-$(date +%Y%m%d_%H%M%S)}"
RESULTS_DIR="$SCRIPT_DIR/results/$RUN_TS"
mkdir -p "$RESULTS_DIR"
printf '%s' "$RUN_TS" > "$SCRIPT_DIR/results/latest-run.txt"

DOMAINS=("$@")
if [[ ${#DOMAINS[@]} -eq 0 ]]; then
  DOMAINS=()
  for f in "$TESTS_DIR"/test_*_domain.sh; do
    DOMAINS+=("$(basename "$f" | sed 's/^test_//; s/_domain\.sh$//')")
  done
fi

TOTAL_PASS=0; TOTAL_FAIL=0; TOTAL_SKIP=0; FAILED_DOMAINS=()
declare -A DOMAIN_RESULT

for d in "${DOMAINS[@]}"; do
  script="$TESTS_DIR/test_${d}_domain.sh"
  if [[ ! -f "$script" ]]; then
    echo "[ERROR] 未找到领域脚本: $script"
    FAILED_DOMAINS+=("$d")
    continue
  fi
  log_file="$RESULTS_DIR/test_${d}_domain.log"
  bash "$script" > "$log_file" 2>&1
  rc=$?
  echo "exit=$rc" >> "$log_file"
  out="$(cat "$log_file")"
  line="$(grep -E '^===== 汇总' <<<"$out" | tail -1)"
  if [[ -z "$line" ]]; then line="(无汇总输出)"; fi
  echo "[$d] exit=$rc  $line"
  DOMAIN_RESULT[$d]="$rc $line"
  p="$(grep -oE 'PASS=[0-9]+' <<<"$line" | cut -d= -f2)"
  f="$(grep -oE 'FAIL=[0-9]+' <<<"$line" | cut -d= -f2)"
  s="$(grep -oE 'SKIP=[0-9]+' <<<"$line" | cut -d= -f2)"
  TOTAL_PASS=$((TOTAL_PASS + ${p:-0}))
  TOTAL_FAIL=$((TOTAL_FAIL + ${f:-0}))
  TOTAL_SKIP=$((TOTAL_SKIP + ${s:-0}))
  [[ $rc -ne 0 ]] && FAILED_DOMAINS+=("$d")
  # 单域失败详情
  if [[ $rc -ne 0 ]]; then
    grep -E '^  \[FAIL\]' <<<"$out" | head -10 | sed 's/^/    /'
  fi
done

echo ""
echo "================ 全部领域汇总 ================"
for d in "${DOMAINS[@]}"; do
  echo "  $d: ${DOMAIN_RESULT[$d]:-未执行}"
done
echo "总计: PASS=$TOTAL_PASS FAIL=$TOTAL_FAIL SKIP=$TOTAL_SKIP"
echo "详细日志: $RESULTS_DIR"
if [[ ${#FAILED_DOMAINS[@]} -gt 0 ]]; then
  echo "失败领域: ${FAILED_DOMAINS[*]}"
  exit 1
fi
exit 0
