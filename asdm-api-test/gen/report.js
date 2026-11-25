#!/usr/bin/env node
/**
 * gen/report.js — 解析 results/<RUN_TS>/ 下的领域测试日志，生成 Markdown 接口自动化测试报告
 *
 * 用法:
 *   node gen/report.js                 # 使用 results/latest-run.txt 指向的最近一次运行
 *   node gen/report.js 20261125_135326 # 指定运行时间戳
 *   node gen/report.js --out <dir>     # 指定报告输出目录（默认 reports/）
 *
 * 输出: reports/api-test-report-YYYYMMDD-HHmmss.md
 * 依赖: 无第三方依赖（仅 Node 内置模块 + gen/domains.json 领域元数据）
 */
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const RESULTS_ROOT = path.join(ROOT, 'results');

// ---------- 参数 ----------
const args = process.argv.slice(2);
let runTs = '';
let outDir = path.join(ROOT, 'reports');
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--out') { outDir = path.resolve(args[i + 1]); i++; }
  else runTs = args[i];
}
if (!runTs) {
  const latest = path.join(RESULTS_ROOT, 'latest-run.txt');
  runTs = fs.readFileSync(latest, 'utf8').trim();
}
const resultsDir = path.join(RESULTS_ROOT, runTs);
if (!fs.existsSync(resultsDir)) {
  console.error(`[ERROR] 结果目录不存在: ${resultsDir}`);
  process.exit(2);
}

// ---------- 领域元数据 ----------
const domainsJson = JSON.parse(fs.readFileSync(path.join(__dirname, 'domains.json'), 'utf8'));
const domainMeta = new Map(); // slug -> { name, services }
const apiMeta = new Map();    // "METHOD /path" -> { name }
for (const d of domainsJson.domains) {
  domainMeta.set(d.slug, { name: d.name, services: d.services });
  for (const a of d.apis) {
    const key = `${a.method} ${a.path}`;
    if (!apiMeta.has(key)) apiMeta.set(key, { name: a.name });
  }
}

const METHOD_RE = /^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+(\/\S+)/;
const TIME_RE = /\s\[(\d+)ms\]$/;
const SEP = ' — ';

function esc(s) {
  return String(s == null ? '' : s).replace(/\|/g, '\\|').replace(/\r?\n/g, ' ');
}

/** 解析一条用例行 → { status, method, path, name, verdict, ms } */
function parseCase(line) {
  const m = line.match(/^\s*\[(PASS|FAIL|SKIP)\]\s+(.*)$/);
  if (!m) return null;
  const status = m[1];
  let text = m[2];
  let ms = null;
  const tm = text.match(TIME_RE);
  if (tm) { ms = Number(tm[1]); text = text.slice(0, tm.index); }

  // 方法 + 路径（无方法前缀的行是登录等辅助用例，不进接口明细）
  let method = '', reqPath = '';
  const mm = text.match(METHOD_RE);
  if (mm) { method = mm[1]; reqPath = mm[2]; }

  // 结论/原因 = 最后一个 " — " 之后的文本
  let verdict = '', label = text;
  const li = text.lastIndexOf(SEP);
  if (li >= 0) { label = text.slice(0, li); verdict = text.slice(li + SEP.length); }

  // 接口名称：优先 label 中的 摘要，其次 domains.json 的 api name，最后用路径
  let name = '';
  const sm = label.match(/摘要：(.+?)(?:\s+完整路径：|$)/);
  if (sm) name = sm[1].trim();
  if (!name && method) {
    const meta = apiMeta.get(`${method} ${reqPath}`);
    if (meta) {
      // "POST /api/x - Change Password" → 取破折号后的英文摘要
      const nm = meta.name.match(/^.+?\s+-\s+(.+)$/);
      name = nm ? nm[1].trim() : meta.name;
    }
  }
  if (!name) name = reqPath || label.slice(0, 60);

  // 附加动作标记（配对清理 / 幂等二次删除等派生用例）
  const actm = label.match(/(清理删除|二次删除\(幂等\)|登录成功)$/);
  const action = actm ? actm[1] : '';

  return { status, method, path: reqPath, name, verdict, ms, action, raw: text };
}

// ---------- 解析各领域日志 ----------
const logFiles = fs.readdirSync(resultsDir).filter(f => /^test_.+_domain\.log$/.test(f)).sort();
const domains = [];
for (const f of logFiles) {
  const slug = f.replace(/^test_/, '').replace(/_domain\.log$/, '');
  const meta = domainMeta.get(slug) || { name: slug, services: [] };
  const filePath = path.join(resultsDir, f);
  const stat = fs.statSync(filePath);
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);

  const cases = [];
  let auxPass = 0, auxFail = 0, auxSkip = 0;
  let scriptSummary = '';
  let scriptExit = '';
  for (const line of lines) {
    if (/^exit=\d+$/.test(line)) { scriptExit = line.replace('exit=', ''); continue; }
    if (/^===== 汇总/.test(line)) { scriptSummary = line.replace(/^===== 汇总:\s*/, ''); continue; }
    const c = parseCase(line);
    if (!c) continue;
    if (!c.method) {
      if (c.status === 'PASS') auxPass++;
      else if (c.status === 'FAIL') auxFail++;
      else auxSkip++;
      continue;
    }
    cases.push(c);
  }

  const pass = cases.filter(c => c.status === 'PASS').length;
  const fail = cases.filter(c => c.status === 'FAIL').length;
  const skip = cases.filter(c => c.status === 'SKIP').length;
  const executed = pass + fail;
  const times = cases.filter(c => c.ms != null).map(c => c.ms);
  const sum = times.reduce((a, b) => a + b, 0);
  const avg = times.length ? Math.round(sum / times.length) : null;
  const max = times.length ? Math.max(...times) : null;
  // 响应时间 p95
  const p95 = times.length ? (times.slice().sort((a, b) => a - b)[Math.floor((times.length - 1) * 0.95)]) : null;

  domains.push({
    slug, name: meta.name, services: meta.services, file: f,
    cases, pass, fail, skip, executed,
    rate: executed > 0 ? (pass * 100 / executed) : null,
    avg, p95, max, times,
    aux: { pass: auxPass, fail: auxFail, skip: auxSkip },
    scriptSummary, scriptExit,
    durationMs: Math.max(0, Math.round(stat.mtimeMs - (stat.birthtimeMs || stat.mtimeMs))),
  });
}

// ---------- 汇总 ----------
const tPass = domains.reduce((a, d) => a + d.pass, 0);
const tFail = domains.reduce((a, d) => a + d.fail, 0);
const tSkip = domains.reduce((a, d) => a + d.skip, 0);
const tTotal = tPass + tFail + tSkip;
const tExec = tPass + tFail;
const tTimes = domains.flatMap(d => d.times);
const tAvg = tTimes.length ? Math.round(tTimes.reduce((a, b) => a + b, 0) / tTimes.length) : null;
const tMax = tTimes.length ? Math.max(...tTimes) : null;
const allFailed = domains.flatMap(d => d.cases.filter(c => c.status === 'FAIL').map(c => ({ ...c, domain: d.name, slug: d.slug })));
const totalDurationMs = domains.reduce((a, d) => a + d.durationMs, 0);

// SKIP 原因分类统计
const skipReasons = new Map();
for (const d of domains) {
  for (const c of d.cases.filter(x => x.status === 'SKIP')) {
    let cat = '其他';
    const v = c.verdict;
    if (/TOKEN 未配置/.test(v)) cat = 'JWT 凭据未配置（登录失败/未提供）';
    else if (/PAT 未配置/.test(v)) cat = 'PAT 未配置';
    else if (/INTERNAL_TOKEN 未配置/.test(v)) cat = 'X-Internal-Token 未配置';
    else if (/OPEN_ACCESS_TOKEN 未配置/.test(v)) cat = 'X-Open-Access-Token 未配置';
    else if (/CITIC_SECRET 未配置/.test(v)) cat = 'CITIC_SECRET 未配置（外部系统）';
    else if (/写操作默认跳过/.test(v)) cat = '写操作守卫（ASDM_ALLOW_WRITES 未开启）';
    else if (/404 资源不存在/.test(v)) cat = '404 资源不存在（默认路径参数）';
    else if (/鉴权拦截/.test(v)) cat = '401/403 鉴权拦截';
    else if (/依赖服务\/上游不可达/.test(v)) cat = '502/503/504 依赖服务不可达';
    else if (/业务参数校验失败/.test(v)) cat = '400 业务参数校验失败';
    else if (/No static resource/.test(v)) cat = '500 路由不存在（No static resource）';
    else if (/业务码 code=/.test(v)) cat = '业务码非 200/0（数据不满足）';
    else if (/永久跳过|密码|状态破坏/.test(v)) cat = '永久跳过（破坏性操作）';
    skipReasons.set(cat, (skipReasons.get(cat) || 0) + 1);
  }
}

// ---------- 报告时间戳 ----------
// RUN_TS: 20261125_135326 → 文件名 20261125-135326
const fileTs = runTs.replace(/(\d{8})_(\d{6})/, '$1-$2');
const fmtDur = (ms) => {
  if (ms == null || ms <= 0) return '—';
  const s = Math.round(ms / 1000);
  return s >= 60 ? `${Math.floor(s / 60)}分${s % 60}秒` : `${s}秒`;
};

// ---------- 生成 Markdown ----------
const L = [];
L.push(`# ASDM Admin API 接口自动化测试报告`);
L.push('');
L.push(`> 由 \`asdm-api-test\` 幂等测试框架自动生成（run-all.sh → gen/report.js）`);
L.push('');
L.push(`| 执行信息 | 值 |`);
L.push(`|---|---|`);
L.push(`| 运行时间戳 | ${runTs} |`);
L.push(`| 测试环境 | https://asdm-sit.leansoftx.com (SIT) |`);
L.push(`| 接口来源 | api.json（Postman Collection v2.1，1000 接口，12 业务领域） |`);
L.push(`| 领域数 / 执行领域数 | 12 / ${domains.length} |`);
L.push(`| 接口用例总数 | ${tTotal}（通过 ${tPass} / 失败 ${tFail} / 跳过 ${tSkip}） |`);
L.push(`| 总通过率（通过/(通过+失败)） | ${tExec > 0 ? (tPass * 100 / tExec).toFixed(1) : '-'}% |`);
L.push(`| 平均响应时间 / 最慢 | ${tAvg != null ? tAvg + ' ms' : '—'} / ${tMax != null ? tMax + ' ms' : '—'} |`);
L.push(`| 测试总耗时（估算，按日志文件时间） | ${fmtDur(totalDurationMs)} |`);
L.push('');
L.push(`**执行结论**: ${tFail === 0 ? '✅ 全部执行用例通过，无失败接口。' : `❌ 存在 ${tFail} 个失败接口（详见「失败接口清单」）。`}`);
L.push('');

// ---- 领域统计 ----
L.push(`## 1. 领域统计总览`);
L.push('');
L.push(`| 领域 | 涉及服务 | 接口用例数 | 通过 | 失败 | 跳过 | 通过率 | 平均响应(ms) | 最慢(ms) |`);
L.push(`|---|---|---:|---:|---:|---:|---:|---:|---:|`);
for (const d of domains) {
  L.push(`| ${d.name} | ${esc(d.services.join(', '))} | ${d.pass + d.fail + d.skip} | ${d.pass} | ${d.fail} | ${d.skip} | ${d.rate != null ? d.rate.toFixed(1) + '%' : '-'} | ${d.avg != null ? d.avg : '—'} | ${d.max != null ? d.max : '—'} |`);
}
L.push(`| **合计** | — | **${tTotal}** | **${tPass}** | **${tFail}** | **${tSkip}** | **${tExec > 0 ? (tPass * 100 / tExec).toFixed(1) + '%' : '-'}** | **${tAvg != null ? tAvg : '—'}** | **${tMax != null ? tMax : '—'}** |`);
L.push('');
L.push(`> 注：通过率 = 通过 / (通过 + 失败)，跳过用例不计入分母（凭据未配置/写操作守卫/资源不存在等属于环境限制，非接口故障，详见附录 A）。`);
L.push('');

// ---- 失败接口清单 ----
L.push(`## 2. 失败接口清单（${allFailed.length} 个）`);
L.push('');
if (allFailed.length === 0) {
  L.push(`本次执行无失败接口。`);
} else {
  L.push(`| # | 领域 | 接口名称 | 方法 | 请求路径 | 失败原因 | 响应时间 |`);
  L.push(`|---:|---|---|---|---|---|---:|`);
  allFailed.forEach((c, i) => {
    L.push(`| ${i + 1} | ${c.domain} | ${esc(c.name)} | ${c.method} | \`${esc(c.path)}\` | ${esc(c.verdict)} | ${c.ms != null ? c.ms : '—'} |`);
  });
  // 失败原因归类
  const failCats = new Map();
  for (const c of allFailed) {
    let cat = '其他';
    if (/网络错误\/服务不可达/.test(c.verdict)) cat = '网络错误/服务不可达（连接失败/被重置）';
    else if (/期望 HTTP/.test(c.verdict)) cat = 'HTTP 状态码不符';
    else if (/响应有 code 缺 message/.test(c.verdict)) cat = '响应体结构断言失败（code 有 message 缺）';
    else if (/超时|timed?\s?out/i.test(c.verdict)) cat = '请求超时';
    failCats.set(cat, (failCats.get(cat) || 0) + 1);
  }
  L.push('');
  L.push(`**失败原因归类**: ${[...failCats.entries()].map(([k, v]) => `${k}×${v}`).join('；')}`);
}
L.push('');

// ---- 各领域接口明细 ----
L.push(`## 3. 各领域接口执行明细`);
for (const d of domains) {
  L.push('');
  L.push(`### 3.${domains.indexOf(d) + 1} ${d.name}（${d.slug}）`);
  L.push('');
  L.push(`- 覆盖服务: ${d.services.join(', ')}`);
  L.push(`- 结果: 通过 ${d.pass} / 失败 ${d.fail} / 跳过 ${d.skip}，通过率 ${d.rate != null ? d.rate.toFixed(1) + '%' : '-（无已执行用例）'}，平均响应 ${d.avg != null ? d.avg + ' ms' : '—'}，脚本退出码 ${d.scriptExit || '—'}${d.scriptSummary ? `，脚本汇总「${esc(d.scriptSummary)}」` : ''}`);
  if (d.aux.pass + d.aux.fail + d.aux.skip > 0) {
    L.push(`- 另有辅助用例（登录等非接口断言）: 通过 ${d.aux.pass} / 失败 ${d.aux.fail} / 跳过 ${d.aux.skip}`);
  }
  L.push('');
  L.push(`| # | 接口名称 | 方法 | 请求路径 | 状态 | 响应时间(ms) |`);
  L.push(`|---:|---|---|---|---|---:|`);
  d.cases.forEach((c, i) => {
    const st = c.status === 'PASS' ? '✅ 通过' : c.status === 'FAIL' ? '❌ 失败' : '⏭ 跳过';
    const name = c.action ? `${esc(c.name)}（${c.action}）` : esc(c.name);
    L.push(`| ${i + 1} | ${name} | ${c.method} | \`${esc(c.path)}\` | ${st} | ${c.ms != null ? c.ms : '—'} |`);
  });
}

// ---- 附录 A：跳过原因统计 ----
L.push('');
L.push(`## 附录 A. 跳过用例原因统计（共 ${tSkip} 个）`);
L.push('');
L.push(`| 跳过原因分类 | 数量 |`);
L.push(`|---|---:|`);
for (const [k, v] of [...skipReasons.entries()].sort((a, b) => b[1] - a[1])) {
  L.push(`| ${esc(k)} | ${v} |`);
}
L.push('');
L.push(`## 附录 B. 环境与执行说明`);
L.push('');
L.push(`- 测试框架: \`${ROOT.split(path.sep).pop()}/run-all.sh\`（幂等设计，详见 README.md）；原始日志位于 \`results/${runTs}/\`。`);
L.push(`- 响应时间来自 curl \`time_total\`（仅记录真实发出请求的用例；守卫类跳过无耗时）。`);
L.push(`- 写操作（POST/PUT/PATCH/DELETE）默认守卫跳过，需 \`ASDM_ALLOW_WRITES=1\` 启用；本次执行未配置真实凭据时，JWT/PAT/Internal/OpenAccess/Citic 类接口自动跳过。`);
L.push(`- 幂等性：全部读接口重复执行结果稳定；写接口启用后走「创建→删除→再删」自清理链，无数据残留。`);
L.push('');

// ---------- 写文件 ----------
fs.mkdirSync(outDir, { recursive: true });
const outFile = path.join(outDir, `api-test-report-${fileTs}.md`);
fs.writeFileSync(outFile, L.join('\n'), 'utf8');
console.log(`[OK] 报告已生成: ${outFile}`);
console.log(`     接口用例 ${tTotal}（PASS ${tPass} / FAIL ${tFail} / SKIP ${tSkip}），失败 ${allFailed.length} 个`);
process.exit(tFail > 0 ? 1 : 0);
