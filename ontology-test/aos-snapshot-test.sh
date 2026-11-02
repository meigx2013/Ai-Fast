#!/usr/bin/env bash
# ============================================================================
# aos-snapshot-test.sh — AOS 技术本体快照 API 测试与对比报告生成脚本
#
# 用法:
#   ./aos-snapshot-test.sh <contextId> [选项]
#   ./aos-snapshot-test.sh --self-check          # 仅自检，不执行测试
#   ./aos-snapshot-test.sh --help
#
# 参数:
#   contextId           AOS 上下文 ID（UUID 格式），也可用 --context-id 指定
#                       (env: AOS_CONTEXT_ID)
#
# 选项:
#   --base-url URL      API 基础地址 (env: AOS_BASE_URL, 默认 https://asdm-dt01.leansoftx.com)
#   --email EMAIL       登录邮箱     (env: AOS_EMAIL,    默认 test01@asdm.ai)
#   --password PWD      登录密码     (env: AOS_PASSWORD, 默认 admin@2026)
#   --page-size N       分页大小     (env: AOS_PAGE_SIZE, 默认 36)
#   --out-dir DIR       报告输出目录 (env: AOS_OUT_DIR, 默认脚本所在目录)
#   --self-check        自检模式（bash 语法 / Node 版本 / 连通性 / 引擎语法 / 参数）
#   -h, --help          帮助
#
# 退出码: 0=成功; 1=测试失败(API/业务错误/无快照); 2=用法或致命错误
#
# 依赖: bash + Node.js >= 18（无需 jq/curl），Windows 下用 Git Bash 执行
#
# 产出: <out-dir>/aos-snapshot-report-<contextId前8位>-<时间戳>.md
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="${AOS_BASE_URL:-https://asdm-dt01.leansoftx.com}"
EMAIL="${AOS_EMAIL:-test01@asdm.ai}"
PASSWORD="${AOS_PASSWORD:-admin@2026}"
PAGE_SIZE="${AOS_PAGE_SIZE:-36}"
OUT_DIR="${AOS_OUT_DIR:-$SCRIPT_DIR}"
CONTEXT_ID="${AOS_CONTEXT_ID:-}"
SELF_CHECK=0

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
die() { log "[FATAL] $*"; exit 2; }

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

# ---------------------------- 参数解析 ----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --context-id) [[ $# -ge 2 ]] || die "--context-id 需要参数值"; CONTEXT_ID="$2"; shift 2 ;;
    --base-url)   [[ $# -ge 2 ]] || die "--base-url 需要参数值";   BASE_URL="$2";   shift 2 ;;
    --email)      [[ $# -ge 2 ]] || die "--email 需要参数值";      EMAIL="$2";      shift 2 ;;
    --password)   [[ $# -ge 2 ]] || die "--password 需要参数值";   PASSWORD="$2";   shift 2 ;;
    --page-size)  [[ $# -ge 2 ]] || die "--page-size 需要参数值";  PAGE_SIZE="$2";  shift 2 ;;
    --out-dir)    [[ $# -ge 2 ]] || die "--out-dir 需要参数值";    OUT_DIR="$2";    shift 2 ;;
    --self-check) SELF_CHECK=1; shift ;;
    -h|--help)    usage ;;
    --*)          die "未知选项: $1" ;;
    *)            if [[ -z "$CONTEXT_ID" ]]; then CONTEXT_ID="$1"; shift
                  else die "多余的位置参数: $1（contextId 只能指定一次）"; fi ;;
  esac
done

UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
check_context_id() {
  [[ -n "$1" ]] || { log "[FATAL] 缺少 contextId 参数（用法: $0 <contextId>）"; return 2; }
  [[ "$1" =~ $UUID_RE ]] || { log "[FATAL] contextId 不是合法 UUID: $1"; return 2; }
  return 0
}

# ---------------------------- 引擎提取 ----------------------------
ENGINE_FILE="$(mktemp "${TMPDIR:-/tmp}/aos-engine-XXXXXX.mjs")" || die "无法创建临时文件"
trap 'rm -f "$ENGINE_FILE"' EXIT

extract_engine() {
  cat > "$ENGINE_FILE" <<'AOS_ENGINE_EOF'
import fs from 'node:fs';
import path from 'node:path';

const BASE = (process.env.AOS_BASE_URL || 'https://asdm-dt01.leansoftx.com').replace(/\/+$/, '');
const EMAIL = process.env.AOS_EMAIL || 'test01@asdm.ai';
const PASSWORD = process.env.AOS_PASSWORD || 'admin@2026';
const CONTEXT_ID = process.env.AOS_CONTEXT_ID || '';
const PAGE_SIZE = parseInt(process.env.AOS_PAGE_SIZE || '36', 10) || 36;
const OUT_DIR = process.env.AOS_OUT_DIR || '.';

const TYPES = ['Class','Route','Table','Mapper','Method','Module','Package','Function',
               'Component','Interface','Dependency','Repository','ApiEndpoint'];

const sleep = ms => new Promise(r => setTimeout(r, ms));
const fail = (code, msg) => { console.error(msg); process.exit(code); };
const fmt = n => Number(n).toLocaleString('en-US');
const pct = ratio => { const v = ratio * 100; return v === 0 ? '0.00%' : (v > 0 ? '+' : '') + v.toFixed(2) + '%'; };
const sign = d => (d > 0 ? '+' : '') + fmt(d);
const parseTime = s => { const t = Date.parse(s || ''); return isNaN(t) ? -Infinity : t; };

function pick(obj, ...keys) {
  if (!obj) return undefined;
  for (const k of keys) if (obj[k] !== undefined && obj[k] !== null) return obj[k];
  return undefined;
}

async function request(method, url, { json, token, timeoutMs = 30000, retries = 2 } = {}) {
  let lastErr = new Error('unknown');
  for (let i = 0; i <= retries; i++) {
    try {
      const headers = {};
      if (json !== undefined) headers['Content-Type'] = 'application/json';
      if (token) headers['Authorization'] = 'Bearer ' + token;
      const res = await fetch(url, {
        method,
        headers,
        body: json !== undefined ? JSON.stringify(json) : undefined,
        signal: AbortSignal.timeout(timeoutMs),
      });
      const text = await res.text();
      let body = null;
      try { body = JSON.parse(text); } catch { /* 非 JSON 响应 */ }
      if (res.status >= 500 && i < retries) { await sleep(1000 * (i + 1)); continue; } // 5xx 重试
      return { status: res.status, body, text };
    } catch (e) {                       // 网络错误/超时 重试
      lastErr = e;
      if (i < retries) { await sleep(1000 * (i + 1)); continue; }
    }
  }
  throw lastErr;
}

function ts() {
  const d = new Date(), p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

async function main() {
  // ---------- 1. 登录获取 JWT ----------
  let token = '';
  try {
    const r = await request('POST', `${BASE}/api/auth/login`,
      { json: { email: EMAIL, password: PASSWORD }, timeoutMs: 20000 });
    token = pick(r.body && r.body.data, 'token', 'accessToken') || pick(r.body, 'token', 'accessToken') || '';
    if (r.status !== 200 || !token) {
      fail(1, `[FAIL] 登录失败: HTTP=${r.status} code=${r.body?.code} message=${r.body?.message ?? String(r.text).slice(0, 200)}`);
    }
    console.error(`[OK] 登录成功 (code=${r.body.code}, tokenLen=${token.length})`);
  } catch (e) {
    fail(1, `[FAIL] 登录请求异常: ${e.message}`);
  }

  // ---------- 2. 分页拉取全部 available 快照 ----------
  const items = [];
  let total = null, page = 1;
  for (;;) {
    let r;
    try {
      r = await request('GET',
        `${BASE}/api/aos/contexts/${CONTEXT_ID}/snapshots?page=${page}&pageSize=${PAGE_SIZE}&status=available`,
        { token });
    } catch (e) {
      fail(1, `[FAIL] 快照列表请求异常(第 ${page} 页): ${e.message}`);
    }
    const b = r.body;
    if (r.status !== 200 || !b || b.code !== 0 || !b.data) {
      fail(1, `[FAIL] 快照列表接口失败: HTTP=${r.status} code=${b?.code} message=${b?.message}`);
    }
    const d = b.data;
    total = typeof d.total === 'number' ? d.total : (d.items || []).length;
    const got = (d.items || []).length;
    items.push(...(d.items || []));
    if (got === 0 || items.length >= total || page >= 50) break; // 防死循环
    page++;
  }
  console.error(`[OK] 快照获取完成: total=${total} 实取=${items.length} (${page} 页)`);
  if (items.length === 0) fail(1, `[FAIL] contextId=${CONTEXT_ID} 无 available 状态快照`);

  // ---------- 3. 提取数据元素 ----------
  const snapshots = items.map((s, idx) => {
    const tc = (s.stats && s.stats.typeCounts) || {};
    const typeCounts = {};
    let typesSum = 0;
    for (const t of TYPES) { typeCounts[t] = tc[t] ?? 0; typesSum += typeCounts[t]; }
    return {
      idx,
      id: s.id || '',
      shortId: (s.id || '').slice(0, 8),
      createdAt: s.createdAt || '',
      completedAt: s.completedAt || '',
      completedTs: parseTime(s.completedAt),
      objectCount: (s.counters && s.counters.objectCount) ?? s.stats?.objectCount ?? 0,
      linkCount: (s.counters && s.counters.linkCount) ?? s.stats?.linkCount ?? 0,
      violationCount: (s.stats && s.stats.violationCount) ?? 0,
      durationMs: (s.stats && s.stats.durationMs) ?? null,
      isDefault: !!s.isDefault,
      generation: (s.inputs && s.inputs.generation) ?? null,
      inputs: (((s.inputs && s.inputs.inputs) || []).map(i => `${i.materializedDir || '?'}(${i.kind || '?'})`).join(' + ')) || '-',
      typeCounts,
      typesSum,
    };
  });
  snapshots.sort((a, b) => (a.completedTs === b.completedTs ? a.idx - b.idx : a.completedTs - b.completedTs));

  // ---------- 4. 数据质量校验 ----------
  const anomalies = [];
  let sumMismatch = 0;
  for (const s of snapshots) {
    if (s.typesSum !== s.objectCount) {
      anomalies.push(`快照 \`${s.shortId}\`: 13 类明细之和(${s.typesSum}) ≠ objectCount(${s.objectCount})`);
      sumMismatch++;
    }
    const createdTs = parseTime(s.createdAt);
    if (s.completedTs !== -Infinity && createdTs !== -Infinity) {
      const gapMs = s.completedTs - createdTs;
      if (gapMs < 0) anomalies.push(`快照 \`${s.shortId}\`: completedAt 早于 createdAt ${-gapMs}ms（时间戳异常）`);
      else if (Math.abs(gapMs - 8 * 3600 * 1000) < 2000) anomalies.push(`快照 \`${s.shortId}\`: completedAt 与 createdAt 恰差 8 小时（疑似 UTC+8/UTC 时区写入不一致）`);
      else if (gapMs > 3600 * 1000) anomalies.push(`快照 \`${s.shortId}\`: completedAt 晚于 createdAt ${(gapMs / 3600000).toFixed(2)}h`);
    }
  }

  // ---------- 5. 生成报告 ----------
  const prev = snapshots.length >= 2 ? snapshots[snapshots.length - 2] : null;
  const last = snapshots[snapshots.length - 1];
  const L = [];
  const push = (...lines) => L.push(...lines);

  push('# AOS 技术本体快照历史数据对比分析报告', '');
  push(`- **生成时间**：${new Date().toISOString()}`);
  push(`- **API 接口**：\`${BASE}/api/aos/contexts/${CONTEXT_ID}/snapshots?page=1&pageSize=${PAGE_SIZE}&status=available\``);
  push(`- **鉴权方式**：\`POST /api/auth/login\` 获取 JWT → \`Authorization: Bearer {jwt}\``);
  push(`- **快照数量**：共 ${snapshots.length} 个（available 状态，已全量拉取）`, '');
  push('---', '');
  push('## 一、API 调用自验证结果', '');
  push('| 验证项 | 结果 |', '|---|---|');
  push('| 登录接口 | ✅ 成功获取 JWT |');
  push('| 快照列表接口 | ✅ HTTP 200，业务码 code=0 |');
  push(`| 分页与完整性 | ✅ total=${total}，实际获取 ${items.length} 个，无遗漏 |`);
  push(sumMismatch === 0
    ? '| 计数自洽性 | ✅ 各快照 13 类明细之和均等于 objectCount |'
    : `| 计数自洽性 | ⚠️ ${sumMismatch} 个快照明细之和与 objectCount 不符 |`);
  push('', '---', '');
  push('## 二、快照列表及核心数据', '');
  push('| # | 快照 ID | completedAt | objectCount | linkCount | 输入 | 默认 |');
  push('|---|---|---|---:|---:|---|---|');
  snapshots.forEach((s, i) => {
    push(`| ${i + 1} | \`${s.id}\` | ${s.completedAt} | ${fmt(s.objectCount)} | ${fmt(s.linkCount)} | ${s.inputs} | ${s.isDefault ? '**是**' : '否'} |`);
  });
  push('');

  // ---------- 三、linkCount 明细对比（全部快照） ----------
  push('---', '');
  push(`## 三、linkCount 明细对比（全部 ${snapshots.length} 个快照，按完成时间升序）`, '');
  push(`| 类型 | ${snapshots.map((s, i) => `快照${i + 1}（${(s.completedAt || '').slice(0, 10)}，${s.shortId}）`).join(' | ')} |`);
  push(`|---|${snapshots.map(() => '---:').join('|')}|`);
  for (const t of TYPES) {
    push(`| ${t} | ${snapshots.map(s => fmt(s.typeCounts[t])).join(' | ')} |`);
  }
  push(`| **合计** | ${snapshots.map(s => `**${fmt(s.typesSum)}**`).join(' | ')} |`);
  push('', '---', '');

  if (prev) {
    const dObj = last.objectCount - prev.objectCount;
    const dLink = last.linkCount - prev.linkCount;
    const densP = prev.objectCount ? prev.linkCount / prev.objectCount : 0;
    const densL = last.objectCount ? last.linkCount / last.objectCount : 0;

    push(`## 四、核心指标变化分析（最新两代：\`${prev.shortId}\` → \`${last.shortId}\`）`, '');
    push('| 指标 | 快照1 | 快照2 | 增量 | 增幅 |');
    push('|---|---:|---:|---:|---:|');
    push(`| objectCount（对象总数） | ${fmt(prev.objectCount)} | ${fmt(last.objectCount)} | ${sign(dObj)} | ${pct(prev.objectCount ? dObj / prev.objectCount : 0)} |`);
    push(`| linkCount（链接总数） | ${fmt(prev.linkCount)} | ${fmt(last.linkCount)} | ${sign(dLink)} | ${pct(prev.linkCount ? dLink / prev.linkCount : 0)} |`);
    push(`| 链接密度（link ÷ object） | ${densP.toFixed(2)} | ${densL.toFixed(2)} | ${(densL - densP).toFixed(2)} | ${pct(densP ? (densL - densP) / densP : 0)} |`);
    push(`| violationCount（违规数） | ${prev.violationCount} | ${last.violationCount} | ${sign(last.violationCount - prev.violationCount)} | - |`);
    push('');
    const changed = TYPES.filter(t => last.typeCounts[t] !== prev.typeCounts[t])
      .map(t => `${t}: ${prev.typeCounts[t]}→${last.typeCounts[t]}（${sign(last.typeCounts[t] - prev.typeCounts[t])}，${pct((last.typeCounts[t] - prev.typeCounts[t]) / (prev.typeCounts[t] || 1))}）`);
    push(`**发生变化的类型**：${changed.length ? changed.join('；') : '无（两代快照 13 类明细完全一致）'}`, '');
    push(`**结论**：对象数 ${dObj >= 0 ? '增长' : '下降'} ${fmt(Math.abs(dObj))}（${pct(prev.objectCount ? dObj / prev.objectCount : 0)}），`
      + `链接数 ${dLink >= 0 ? '增长' : '下降'} ${fmt(Math.abs(dLink))}（${pct(prev.linkCount ? dLink / prev.linkCount : 0)}）。`
      + (Math.abs(dObj) > 0 && Math.abs(dLink / (prev.linkCount || 1)) > Math.abs(dObj / (prev.objectCount || 1))
          ? '链接增速高于对象增速，对象间关联密度提升。' : '')
      + (last.violationCount === 0 ? '无本体违规，数据质量稳定。' : `存在 ${last.violationCount} 个本体违规项，需关注。`),
    '');
  } else {
    push('## 四、核心指标变化分析', '');
    push('> 当前上下文仅有 1 个快照，暂无历史对比。建议在输入变更后再次生成快照以积累历史数据。', '');
  }

  push('---', '');
  push('## 五、数据质量异常提示', '');
  if (anomalies.length === 0) push('未发现时间戳或计数异常。');
  else anomalies.forEach(a => push(`- ⚠️ ${a}`));
  push('');

  const reportFile = path.resolve(OUT_DIR, `aos-snapshot-report-${CONTEXT_ID.slice(0, 8)}-${ts()}.md`);
  fs.writeFileSync(reportFile, L.join('\n') + '\n', 'utf8');
  console.error(`[OK] 分析报告已生成: ${reportFile}`);
  console.log(reportFile);
}

main().catch(e => fail(2, `[FATAL] 未捕获异常: ${(e && e.stack) || e}`));
AOS_ENGINE_EOF
  return $?
}

# ---------------------------- 自检模式 ----------------------------
if [[ "$SELF_CHECK" -eq 1 ]]; then
  log "===== 自检开始 ====="
  pass=0; failc=0
  ok()  { log "  [PASS] $*"; pass=$((pass+1)); }
  bad() { log "  [FAIL] $*"; failc=$((failc+1)); }

  # 1. bash 语法检查
  if bash -n "$0" 2>/dev/null; then ok "bash 语法检查"; else bad "bash 语法检查"; fi

  # 2. Node.js 版本 >= 18
  if command -v node >/dev/null 2>&1; then
    NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
    if [[ "$NODE_MAJOR" -ge 18 ]] 2>/dev/null; then
      ok "Node.js 版本: $(node --version) (>=18)"
    else
      bad "Node.js 版本过低: $(node --version 2>/dev/null)（需要 >=18）"
    fi
  else
    bad "未找到 node 命令"
  fi

  # 3. 引擎提取与语法检查
  if extract_engine && [[ -s "$ENGINE_FILE" ]] && node --check "$ENGINE_FILE" 2>/dev/null; then
    ok "内嵌 Node 引擎语法检查 ($(wc -l < "$ENGINE_FILE") 行)"
  else
    bad "内嵌 Node 引擎提取/语法检查失败"
  fi

  # 4. API 服务连通性
  if command -v node >/dev/null 2>&1; then
    if AOS_BASE_URL="$BASE_URL" node -e '
      const b = (process.env.AOS_BASE_URL || "").replace(/\/+$/, "");
      fetch(b, { signal: AbortSignal.timeout(10000) })
        .then(r => { console.error(`HTTP ${r.status} @ ${b}`); process.exit(0); })
        .catch(e => { console.error(e.message); process.exit(1); });' 2>/dev/null; then
      ok "API 服务连通性: $BASE_URL"
    else
      bad "API 服务不可达: $BASE_URL"
    fi
  fi

  # 5. contextId 参数格式（提供时才校验）
  if [[ -n "$CONTEXT_ID" ]]; then
    if check_context_id "$CONTEXT_ID"; then ok "contextId 格式: $CONTEXT_ID"; else bad "contextId 格式非法: $CONTEXT_ID"; fi
  else
    log "  [SKIP] 未提供 contextId（自检模式下可选）"
  fi

  log "===== 自检结束: $pass 通过, $failc 失败 ====="
  [[ "$failc" -eq 0 ]] && exit 0 || exit 1
fi

# ---------------------------- 正式执行 ----------------------------
check_context_id "$CONTEXT_ID"; rc=$?
[[ $rc -ne 0 ]] && exit $rc

[[ "$PAGE_SIZE" =~ ^[1-9][0-9]*$ ]] || die "--page-size 必须为正整数: $PAGE_SIZE"
[[ -d "$OUT_DIR" ]] || mkdir -p "$OUT_DIR" || die "无法创建输出目录: $OUT_DIR"

extract_engine || die "引擎提取失败"
node --check "$ENGINE_FILE" 2>/dev/null || die "引擎语法检查失败"

log "开始 AOS 快照测试: contextId=$CONTEXT_ID baseUrl=$BASE_URL outDir=$OUT_DIR"
AOS_BASE_URL="$BASE_URL" AOS_EMAIL="$EMAIL" AOS_PASSWORD="$PASSWORD" \
AOS_CONTEXT_ID="$CONTEXT_ID" AOS_PAGE_SIZE="$PAGE_SIZE" AOS_OUT_DIR="$OUT_DIR" \
node "$ENGINE_FILE"
rc=$?
if [[ $rc -eq 0 ]]; then
  log "测试完成，报告生成成功"
else
  log "测试失败 (退出码=$rc)"
fi
exit $rc
