#!/usr/bin/env bash
# 语法检查所有测试脚本
fail=0
for f in /d/dev-src/Ai-Fast/asdm-api-test/tests/*.sh /d/dev-src/Ai-Fast/asdm-api-test/common.sh; do
  if bash -n "$f" 2>/tmp/synerr.txt; then
    echo "OK          $(basename "$f")"
  else
    echo "SYNTAX-FAIL $(basename "$f"): $(cat /tmp/synerr.txt)"
    fail=1
  fi
done
exit $fail
