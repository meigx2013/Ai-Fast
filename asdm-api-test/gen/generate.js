#!/usr/bin/env node
/**
 * generate.js — 从 gen/domains.json 生成分领域幂等测试脚本 tests/test_<slug>_domain.sh
 * 用法: node gen/generate.js
 * 幂等策略:
 *   GET/HEAD  → 直接调用，断言 HTTP 状态码 + 响应顶层结构（404→SKIP 资源不存在）
 *   写操作    → 默认 GUARDED（ASDM_ALLOW_WRITES=1 才执行）：
 *               POST 唯一性字段注入 __RUN_ID__ / requestId 固定幂等键；
 *               能配对同域 DELETE 的 POST 走「创建→提取ID→删除→再删(幂等)」链；
 *               PUT/PATCH 对默认 ID 更新，404→SKIP；
 *               DELETE 用 DUMMY_ID 校验「删除不存在资源」的幂等语义（200/404 皆可）。
 *   危险接口  → 永久 SKIP（改密码/登出/注册/实例生命周期/清库类/multipart 文件）。
 */
'use strict';
const fs = require('fs');
const path = require('path');

const GEN_DIR = __dirname;
const ROOT = path.resolve(GEN_DIR, '..');
const OUT_DIR = path.join(ROOT, 'tests');
const summary = JSON.parse(fs.readFileSync(path.join(GEN_DIR, 'domains.json'), 'utf8'));

// ===== 常量 =====
const UNIQUE_KEYS = ['email', 'username', 'name', 'displayName', 'title', 'nickname'];
const IDEMPOTENT_KEYS = ['requestId', 'requestID', 'idempotencyKey', 'idempotency-key'];
const DANGER_SEGMENTS = new Set([
  'restart', 'stop', 'start', 'shutdown', 'migrate', 'migration', 'reset',
  'clean', 'purge', 'clear', 'rebuild', 'terminate', 'restore', 'delete-all', 'deleteall', 'cleanup',
]);
// 永久黑名单（写方法）
const HARD_BLACKLIST = [
  { match: a => a.path === '/api/auth/change-password' && a.method === 'POST', why: '修改真实账号密码，禁止自动执行' },
  { match: a => a.path === '/api/auth/logout' && a.method === 'POST', why: '会使当前 JWT 失效，影响后续用例' },
  { match: a => a.path === '/api/auth/register' && a.method === 'POST', why: '创建真实用户且无自清理接口（SIT 注册通常禁用，可用 register-status 预检）' },
];

// ===== 工具函数 =====
function bquote(s) { // 安全嵌入 bash 双引号字符串
  return String(s).replace(/[\\"`$]/g, ' ').replace(/[\r\n]+/g, ' ').trim();
}
function shellSingleQuote(s) {
  return "'" + String(s).replace(/'/g, "'\\''") + "'";
}
function normalizeSegs(p) {
  return p.split('/').filter(Boolean).map(s => (s.startsWith(':') || s.startsWith('*') ? '*' : s));
}
function pathVarNames(p) { // 提取路径变量名（含 :id\d+ 这类怪变量，取字母数字前缀）
  const out = [];
  for (const seg of p.split('/')) {
    if (seg.startsWith(':')) out.push(seg.slice(1).replace(/[^\w]/g, '') || 'id');
    else if (seg.startsWith('*')) out.push('id');
  }
  return out;
}
function genPathExpr(p, idExprMap) { // 路径变量 → $(path_id xxx) 或 ${DUMMY_ID} 或 ${rid}
  return p.split('/').map(seg => {
    if (!seg) return '';
    if (seg.startsWith(':')) {
      const name = seg.slice(1).replace(/[^\w]/g, '') || 'id';
      if (idExprMap && idExprMap[name] !== undefined) return idExprMap[name];
      return `$(path_id ${name})`;
    }
    if (seg.startsWith('*')) return idExprMap && idExprMap['*'] !== undefined ? idExprMap['*'] : '$(path_id id)';
    return seg;
  }).join('/').replace(/^\/\//, '/');
}
function encodeQuery(api) {
  if (!api.query || !api.query.length) return '';
  return api.query.map(q => {
    let v = String(q.value);
    if (v === '__PAT__') return `${q.key}=\${PAT}`;
    return `${q.key}=${encodeURIComponent(v)}`;
  }).join('&');
}

// body 唯一性字段注入 __RUN_ID__ 标记；幂等键固定；过期日期字段推远
function markBody(raw) {
  let o;
  try { o = JSON.parse(raw); } catch (e) { return { raw, marked: false }; }
  let marked = false;
  (function walk(x) {
    if (Array.isArray(x)) { x.forEach(walk); return; }
    if (x && typeof x === 'object') {
      for (const k of Object.keys(x)) {
        const v = x[k];
        if (typeof v === 'string' && IDEMPOTENT_KEYS.includes(k)) { x[k] = 'asdm-shell-idem-fixed'; marked = true; }
        else if (typeof v === 'string' && /^(expires?At|expiryAt|expireAt|validUntil)$/i.test(k) && /^\d{4}-\d{2}-\d{2}/.test(v)) {
          const year = parseInt(v.slice(0, 4), 10);
          if (year <= 2030) { x[k] = '2099-01-01T00:00:00'; marked = true; }
        }
        else if (typeof v === 'string' && UNIQUE_KEYS.includes(k) && v && !v.includes('__RUN_ID__')) {
          x[k] = k === 'email' ? `auto___RUN_ID__@example.com` : `${v}__RUN_ID__`;
          marked = true;
        } else walk(v);
      }
    }
  })(o);
  return marked ? { raw: JSON.stringify(o, null, 1), marked: true } : { raw, marked: false };
}

// POST → DELETE 配对（取公共前缀最大、长度差 ≤1 且 DELETE 尾段为变量）
function findDeletePair(post, deletes) {
  const pn = normalizeSegs(post.path);
  let best = null, bestScore = -1;
  for (const del of deletes) {
    const dn = normalizeSegs(del.path);
    if (dn.length !== pn.length && dn.length !== pn.length + 1) continue;
    if (dn.length === pn.length + 1 && dn[dn.length - 1] !== '*') continue;
    let common = 0;
    while (common < Math.min(pn.length, dn.length) && pn[common] === dn[common]) common++;
    const need = Math.max(2, Math.min(pn.length, dn.length) - 1);
    if (common >= need && common > bestScore) { best = del; bestScore = common; }
  }
  return best;
}

// ===== 用例函数生成 =====
function genCase(api, domain, deletes, fn) {
  const label = bquote(`${api.method} ${api.path}`);
  const desc = bquote((api.desc || '').slice(0, 60));
  const L = (s) => s; // 行收集器占位

  // --- login 特判 ---
  if (api.path === '/api/auth/login' && api.method === 'POST') {
    return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}
${fn}() {
  # 登录前置：已由 login_if_needed() 覆盖（失败会在控制台与汇总中体现）
  if [[ -n "\$TOKEN" ]]; then
    log_pass "${label} — 已由 login_if_needed 覆盖（ASDM_TOKEN 或登录成功）"
  else
    log_skip "${label} — 登录失败，见 login_if_needed 输出"
  fi
}
`;
  }

  // --- formdata ---
  if (api.body && api.body.mode === 'formdata') {
    return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}
${fn}() {
  log_skip "${label} — 需要 multipart 文件上传，无法幂等自动执行（${desc}）"
}
`;
  }

  // --- 永久黑名单（写方法）---
  if (api.method !== 'GET' && api.method !== 'HEAD') {
    const hb = HARD_BLACKLIST.find(x => x.match(api));
    const segs = api.path.split('/').filter(Boolean);
    const danger = segs.some(s => DANGER_SEGMENTS.has(s));
    const staticDelete = api.method === 'DELETE' && !segs.some(s => s.startsWith(':') || s.startsWith('*'));
    if (hb) {
      return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}
${fn}() {
  log_skip "${label} — 永久跳过：${bquote(hb.why)}"
}
`;
    }
    if (danger) {
      return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}
${fn}() {
  log_skip "${label} — 永久跳过：路径含状态变更/清理类操作段（${segs.filter(s => DANGER_SEGMENTS.has(s)).join('/')}），避免破坏环境"
}
`;
    }
    if (staticDelete) {
      return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}
${fn}() {
  log_skip "${label} — 永久跳过：静态路径整体删除，无法限定删除范围"
}
`;
    }
  }

  const isRead = api.method === 'GET' || api.method === 'HEAD';
  const pathVars = pathVarNames(api.path);
  const query = encodeQuery(api);
  const queryArgD = query ? `"${query.replace(/"/g, '\\"')}"` : '""';
  const hasBody = api.body && api.body.mode === 'raw' && api.body.raw;

  // --- 读接口 ---
  if (isRead) {
    const pathExpr = genPathExpr(api.path);
    const ssoish = /sso/i.test(api.folder) || /sso/i.test(api.path);
    const codes = ssoish ? '200 301 302' : String(api.expected || 200);
    return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}
${fn}() {
  local label="${label} — ${desc}"
  need_auth ${api.auth} "\$label" || return 0
  req ${api.auth} ${api.method} "${pathExpr}" "" ${queryArgD}
  expect_read_ok "\$label" ${codes}
}
`;
  }

  // --- 写接口（GUARDED）---
  const authGuard = `writes_allowed "\$label" || return 0
  need_auth ${api.auth} "\$label" || return 0`;
  const pair = api.method === 'POST' ? findDeletePair(api, deletes) : null;

  if (pair) {
    // 创建→提取ID→删除→再删（幂等）
    const pairLabel = `${api.method} ${pair.path}`;
    // DELETE 配对路径：第一个变量用 ${rid}
    let firstVarReplaced = false;
    const idMap = {};
    const delSegs = pair.path.split('/');
    for (let i = 0; i < delSegs.length; i++) {
      const s = delSegs[i];
      if ((s.startsWith(':') || s.startsWith('*')) && !firstVarReplaced) {
        firstVarReplaced = true;
        delSegs[i] = '\${rid}';
      } else if (s.startsWith(':')) {
        delSegs[i] = `\$(path_id ${s.slice(1).replace(/[^\w]/g, '') || 'id'})`;
      } else if (s.startsWith('*')) {
        delSegs[i] = '$(path_id id)';
      }
    }
    const delPath = delSegs.join('/');
    let bodyBlock = '';
    if (hasBody) {
      const mb = markBody(api.body.raw);
      const sedLine = mb.marked
        ? `local body; body="\$(sed "s|__RUN_ID__|\${RUN_ID}|g" <<'JSONEOF'\n${mb.raw}\nJSONEOF\n)"`
        : `local body; body="\$(cat <<'JSONEOF'\n${api.body.raw}\nJSONEOF\n)"`;
      bodyBlock = `  ${sedLine}\n`;
    }
    const postPathExpr = genPathExpr(api.path);
    return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}（配对清理: ${bquote(pairLabel)}）
${fn}() {
  local label="${label} — ${desc}"
  ${authGuard}
${bodyBlock}  req ${api.auth} ${api.method} "${postPathExpr}" ${hasBody ? '"$body"' : '""'} ${queryArgD}
  if ! expect_status "\$label" ${api.expected || 200}; then return 1; fi
  expect_json_top "\$label"
  local rid; rid="\$(extract_id)"
  if [[ -z "\$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：\$(head -c 200 <<<"\$BODY")"
    return 0
  fi
  # 清理：${bquote(pairLabel)}
  req ${pair.auth} DELETE "${delPath}" "" ${pair.query && pair.query.length ? `"${encodeQuery(pair).replace(/"/g, '\\"')}"` : '""'}
  if ! expect_status "\$label 清理删除" ${pair.expected || 200} 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req ${pair.auth} DELETE "${delPath}" "" ${pair.query && pair.query.length ? `"${encodeQuery(pair).replace(/"/g, '\\"')}"` : '""'}
  expect_status "\$label 二次删除(幂等)" ${pair.expected || 200} 404
}
`;
  }

  // --- 无配对的写接口 ---
  if (api.method === 'DELETE') {
    const pathExpr = genPathExpr(api.path, { __dummy: true });
    // DELETE 统一用 DUMMY_ID 替换变量段，防误删真实资源
    const dummyPath = api.path.split('/').map(s =>
      (s.startsWith(':') || s.startsWith('*')) ? '\${DUMMY_ID}' : s
    ).join('/');
    return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}
${fn}() {
  local label="${label} — ${desc}"
  ${authGuard}
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req ${api.auth} DELETE "${dummyPath}" "" ${queryArgD}
  expect_status "\$label (幂等删除校验)" 200 404
}
`;
  }

  // PUT/PATCH/POST 未配对
  const pathExpr = genPathExpr(api.path);
  let bodyBlock = '';
  if (hasBody) {
    const mb = markBody(api.body.raw);
    const sedLine = mb.marked
      ? `local body; body="\$(sed "s|__RUN_ID__|\${RUN_ID}|g" <<'JSONEOF'\n${mb.raw}\nJSONEOF\n)"`
      : `local body; body="\$(cat <<'JSONEOF'\n${api.body.raw}\nJSONEOF\n)"`;
    bodyBlock = `  ${sedLine}\n`;
  }
  const expectLine = (api.method === 'PUT' || api.method === 'PATCH')
    ? 'expect_status_missing "\$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP'
    : 'expect_status "\$label" 200\n  expect_json_top "\$label"';
  return `# seq${api.seq} ${bquote(api.folder)} | auth=${api.auth}（无配对删除接口，失败请人工核查数据残留）
${fn}() {
  local label="${label} — ${desc}"
  ${authGuard}
${bodyBlock}  req ${api.auth} ${api.method} "${pathExpr}" ${hasBody ? '"$body"' : '""'} ${queryArgD}
  ${expectLine}
}
`;
}

// ===== 主流程 =====
fs.mkdirSync(OUT_DIR, { recursive: true });
const report = [];
for (const dom of summary.domains) {
  const apis = dom.apis;
  const deletes = apis.filter(a => a.method === 'DELETE');
  const used = new Map();
  const cases = [];
  let stats = { read: 0, guarded: 0, paired: 0, skipHard: 0 };

  for (const api of apis) {
    // 函数名: <slug>_<method>_<pathslug>
    let base = `${dom.slug}_${api.method.toLowerCase()}_${api.path}`
      .replace(/^\//, '')
      .replace(/[:\/]+/g, '_')
      .replace(/[^\w]/g, '_')
      .replace(/_+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 70);
    let fn = base, i = 2;
    while (used.has(fn)) { fn = `${base}_${i++}`; }
    used.set(fn, api.seq);
    cases.push(genCase(api, dom, deletes, fn));

    const isRead = api.method === 'GET' || api.method === 'HEAD';
    const hard = !isRead && (
      HARD_BLACKLIST.some(x => x.match(api)) ||
      api.path.split('/').filter(Boolean).some(s => DANGER_SEGMENTS.has(s)) ||
      (api.method === 'DELETE' && !api.path.split('/').filter(Boolean).some(s => s.startsWith(':') || s.startsWith('*'))) ||
      (api.body && api.body.mode === 'formdata'));
    if (isRead) stats.read++;
    else if (hard) stats.skipHard++;
    else { stats.guarded++; if (api.method === 'POST' && findDeletePair(api, deletes)) stats.paired++; }
  }

  const header = `#!/usr/bin/env bash
# ============================================================================
# ${dom.name} — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: ${dom.services.join(', ')}
# 接口总数: ${apis.length}（读 ${stats.read} 直测 / 写 ${stats.guarded} 受控[含配对清理 ${stats.paired}] / 永久跳过 ${stats.skipHard}）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
source "\$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
`;
  const fns = [...used.keys()];
  const mainBody = apis.map(a => `  ${fns[apis.indexOf(a)]} || true`).join('\n');

  const script = header + cases.join('\n') + `
# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== ${dom.name} (${apis.length} apis) =========="
  login_if_needed || true
${mainBody}
  finish
}
main "\$@"
`;
  fs.writeFileSync(path.join(OUT_DIR, dom.script), script);
  report.push({ domain: dom.name, script: dom.script, total: apis.length, ...stats });
}

console.log('生成完成 → tests/');
for (const r of report) {
  console.log(`${r.domain.padEnd(10)} ${r.script.padEnd(32)} total=${r.total} 读直测=${r.read} 写受控=${r.guarded}(配对=${r.paired}) 永久跳过=${r.skipHard}`);
}
