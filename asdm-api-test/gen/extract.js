#!/usr/bin/env node
/**
 * extract.js — 解析 Postman Collection (api.json)，输出结构化领域摘要 domains.json
 * 用法: node gen/extract.js [api.json] [gen/domains.json]
 */
'use strict';
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const inPath = process.argv[2] || path.join(root, 'api.json');
const outPath = process.argv[3] || path.join(__dirname, 'domains.json');
const col = JSON.parse(fs.readFileSync(inPath, 'utf8'));

// ===== 域名 → 脚本 slug 映射（按 api.json 顶层 item.name）=====
const DOMAIN_SLUGS = {
  '认证授权域': 'auth',
  '用户与组织管理域': 'user_org',
  '项目管理域': 'project',
  '工作空间域': 'workspace',
  '上下文库域': 'context',
  '流水线域': 'pipeline',
  '资产注册域': 'asset_registry',
  '集成域': 'integration',
  '代码评审域': 'pr_review',
  '门户与内容域': 'portal',
  '基础设施域': 'infra',
  '数字分身域': 'twin',
};

// ===== 服务名 → slug =====
function serviceSlug(name) {
  if (!name) return 'core';
  const m = name.match(/asdm-admin-services-([\w-]+)/);
  return m ? m[1] : name.toLowerCase().replace(/[^a-z0-9]+/g, '_');
}

// ===== 鉴权类型判定（header 优先，description 兜底）=====
function classifyAuth(req) {
  const headers = req.header || [];
  const desc = req.description || '';
  const has = (k) => headers.some(h => (h.key || '').toLowerCase() === k.toLowerCase());
  const authVal = () => {
    const h = headers.find(x => (x.key || '').toLowerCase() === 'authorization');
    return h ? String(h.value || '') : '';
  };
  if (has('X-Citic-Secret')) return 'citic';
  if (has('X-Open-Access-Token')) return 'openaccess';
  if (has('X-Internal-Token')) return 'internal';
  if (has('X-Asdm-Pat')) return 'pat';
  const q = (req.url && req.url.query) || [];
  if (q.some(x => ['asdmPat', 'pat'].includes(x.key) && !x.disabled)) return 'pat';
  if (/\{\{pat\}\}/.test(authVal())) return 'pat';
  if (/\{\{token\}\}/.test(authVal())) return 'jwt';
  // description 兜底
  if (/X-Internal-Token/.test(desc)) return 'internal';
  if (/X-Citic-Secret/.test(desc)) return 'citic';
  if (/asdmPat/.test(desc)) return 'pat';
  if (/X-Open-Access-Token/.test(desc)) return 'openaccess';
  if (/公开接口|无需认证|permitAll/.test(desc)) return 'public';
  if (/无统一鉴权/.test(desc)) return 'none';
  if (has('Authorization')) return 'jwt';
  return 'none';
}

// ===== 提取 query（跳过 disabled，替换 {{pat}}）=====
function extractQuery(req) {
  const q = (req.url && req.url.query) || [];
  return q.filter(x => !x.disabled).map(x => {
    let v = x.value == null ? '' : (typeof x.value === 'object' ? JSON.stringify(x.value) : String(x.value));
    return { key: x.key, value: v.replace(/\{\{pat\}\}/g, '__PAT__') };
  });
}

// ===== 提取 path =====
function extractPath(req) {
  let segs;
  if (typeof req.url === 'string') {
    segs = req.url.replace(/\{\{\w+BaseUrl\}\}/, '').split('/').filter(Boolean);
  } else {
    segs = (req.url && req.url.path || []).map(String);
  }
  return '/' + segs.join('/');
}

// ===== 提取 body =====
function extractBody(req) {
  if (!req.body) return null;
  if (req.body.mode === 'raw' && req.body.raw) return { mode: 'raw', raw: req.body.raw };
  if (req.body.mode === 'formdata') {
    return { mode: 'formdata', fields: (req.body.formdata || []).map(f => ({ key: f.key, type: f.type })) };
  }
  return { mode: req.body.mode || 'none' };
}

// ===== 接口名 → 函数名 slug =====
function slugify(s) {
  return String(s).toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .replace(/_+/g, '_')
    .slice(0, 60);
}

// ===== 主遍历 =====
let seq = 0;
const domains = [];
for (const domainItem of col.item || []) {
  const dName = domainItem.name;
  const slug = DOMAIN_SLUGS[dName];
  if (!slug) throw new Error(`未知顶层领域: ${dName}`);
  const apis = [];
  const services = new Set();

  function walk(item, service, folders) {
    const name = item.name || '';
    if (item.item && item.item.length) {
      // 第二层视为"服务"分组
      const nextService = service || serviceSlug(name);
      const nextFolders = (service ? folders : []).concat(service ? [name] : []);
      for (const s of item.item) walk(s, nextService, nextFolders);
      return;
    }
    const r = item.request;
    if (!r || !r.method) return;
    const svc = service || 'core';
    services.add(svc);
    seq += 1;
    apis.push({
      seq,
      name: r.name || name,
      service: svc,
      folder: folders.join('/') || name,
      method: r.method,
      path: extractPath(r),
      auth: classifyAuth(r),
      query: extractQuery(r),
      body: extractBody(r),
      expected: (r.response && r.response[0] && r.response[0].code) || 200,
      desc: (r.description || '').split('\n').slice(0, 2).join(' ').slice(0, 120),
    });
  }
  // 顶层：领域层本身不是服务，直接以第二层分组名解析服务 slug
  if (Array.isArray(domainItem.item) && domainItem.item.length) {
    for (const sub of domainItem.item) walk(sub, serviceSlug(sub.name), []);
  } else {
    walk(domainItem, 'core', []);
  }
  domains.push({ name: dName, slug, script: `test_${slug}_domain.sh`, services: [...services], apis });
}

fs.writeFileSync(outPath, JSON.stringify({
  collection: col.info && col.info.name,
  total: seq,
  generatedAt: new Date().toISOString(),
  domains,
}, null, 1));

// ===== 汇总输出 =====
console.log(`collection: ${col.info && col.info.name}, total apis: ${seq}`);
for (const d of domains) {
  const authCount = {};
  for (const a of d.apis) authCount[a.auth] = (authCount[a.auth] || 0) + 1;
  console.log(`${d.name} | ${d.apis.length} apis | ${d.script} | auth: ${JSON.stringify(authCount)}`);
}
