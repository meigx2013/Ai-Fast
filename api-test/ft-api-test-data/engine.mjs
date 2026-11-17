/**
 * FT-TBD 在线智能体空间开放接入（服务化接口）— API 测试引擎（由 ft-tbd-api-test.sh 释放）
 * 接口契约: FT-TBD 在线智能体空间开放接入.postman_collection_v2.json（19 个接口）
 * 独立运行: FT_BASE_URL=... FT_OPEN_ACCESS_TOKEN=... FT_ASDM_PAT=... FT_USER_ID=... node engine.mjs [--fresh|--resume]
 * 鉴权: X-Open-Access-Token 全局携带；enter/connect 额外携带 X-Asdm-Pat；成员接口携带 userId
 * 依赖编排: 1.1列表→instanceId/workspaceId; 1.2详情(等待running);
 *           2.2connect→wsUrl; [ACP WS连接+initialize]→3.2会话→sessionId; 3.4模型→currentModel; 4.1→filePath; 4.3→artifactId
 * 自愈: 网络错误/5xx重试、3.2创建会话409→建立ACP WS连接并initialize后重试、
 *       1.2实例stopped→restart、1.3停止后自动restore重启
 */
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const BASE = process.env.FT_BASE_URL || 'https://asdm-dt01.leansoftx.com';
const OAT = process.env.FT_OPEN_ACCESS_TOKEN || 'oat_NqUKhk8W658Kew8lUAGjgr6Xx-66eatkOYEezVogxto';
const PAT = process.env.FT_ASDM_PAT || 'pat_5AmoF95eEMFjSxfGQ-3_GCJYibciY-JBVu_ETItZCOg';
const USER_ID_RAW = process.env.FT_USER_ID || '52';
const USER_ID = /^\d+$/.test(String(USER_ID_RAW)) ? Number(USER_ID_RAW) : USER_ID_RAW;
const FRESH = process.argv.includes('--fresh');

const DIR = fileURLToPath(new URL('.', import.meta.url));
const STATE_FILE = DIR + 'state.json';
const RESULTS_FILE = DIR + 'results.json';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const load = (f, d) => { try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return d; } };
let state = load(STATE_FILE, {});
let results = load(RESULTS_FILE, {});
const saveFiles = () => {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  fs.writeFileSync(RESULTS_FILE, JSON.stringify(results, null, 2));
};
const log = (...a) => console.log(new Date().toISOString().slice(11, 19), ...a);
const pick = (obj, ...keys) => {
  for (const k of keys) { const v = obj?.[k]; if (v !== undefined && v !== null) return v; }
};

// 当前步骤的 HTTP 累计耗时（毫秒）与请求次数（rawRequest 层统计，不含轮询间隔等待）
let httpTime = { ms: 0, count: 0 };
const resetHttpTime = () => { httpTime = { ms: 0, count: 0 }; };

async function rawRequest(method, path, opts = {}) {
  const { json, form, query, pat = false, timeoutMs = 60000 } = opts;
  const url = new URL(BASE + path);
  if (query) for (const [k, v] of Object.entries(query)) {
    if (v !== undefined && v !== null && String(v) !== '') url.searchParams.set(k, String(v));
  }
  const headers = { 'X-Open-Access-Token': OAT };
  if (pat) headers['X-Asdm-Pat'] = PAT;
  let body;
  if (json !== undefined) { headers['Content-Type'] = 'application/json'; body = JSON.stringify(json); }
  else if (form) { body = form; }
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), timeoutMs);
  const _t0 = Date.now();
  try {
    const res = await fetch(url, { method, headers, body, signal: ac.signal });
    const buf = Buffer.from(await res.arrayBuffer());
    const text = buf.toString('utf8');
    httpTime.ms += Date.now() - _t0;
    httpTime.count++;
    let parsed = null; try { parsed = JSON.parse(text); } catch {}
    // 二进制响应检测：非 JSON 且含 NUL 字节或 UTF-8 解码失败(U+FFFD)，避免原始字节污染日志/报告
    const binary = !parsed && buf.length > 0 && (buf.includes(0) || /\uFFFD/.test(text));
    return { status: res.status, statusText: res.statusText, headers: res.headers, text, body: parsed, byteLength: buf.length, binary };
  } finally { clearTimeout(t); }
}

function bizOk(r) {
  if (r.status < 200 || r.status >= 300) return false;
  if (r.body && typeof r.body === 'object' && 'code' in r.body) {
    const c = r.body.code;
    return c === 0 || c === 200 || c === '0' || c === '200' || c === true;
  }
  return true;
}
function bizNote(r) {
  const b = r.body;
  const parts = ['HTTP ' + r.status];
  if (b && typeof b === 'object') {
    if ('code' in b) parts.push('code=' + b.code);
    if (b.message) parts.push(String(b.message).slice(0, 120));
  } else if (r.binary) parts.push('<二进制内容 ' + r.byteLength + ' 字节>');
  else if (r.text) parts.push(r.text.slice(0, 120));
  return parts.join(' | ');
}

/** 带通用自愈的请求执行：网络错误/5xx 重试；extraHeal 步骤级自愈（401/403 为令牌失效不可自愈，直接返回） */
async function healRequest(method, path, opts = {}, { extraHeal } = {}) {
  let last;
  for (let attempt = 1; attempt <= 4; attempt++) {
    try {
      last = await rawRequest(method, path, opts);
    } catch (e) {
      log('  网络错误(' + attempt + '): ' + e.name + ' ' + e.message);
      if (attempt >= 3) break;
      await sleep(2000);
      continue;
    }
    if (last.status === 401 || last.status === 403) {
      log('  ' + last.status + ' 令牌/权限失效（openAccessToken 或 asdmPat 无效），不可自愈');
      break;
    }
    if (last.status >= 500 && attempt < 3) { log('  5xx → 重试(' + attempt + ')'); await sleep(2000); continue; }
    if (extraHeal) {
      const healed = await extraHeal(last);
      if (healed) { last = healed; break; }
    }
    break;
  }
  return last;
}

const instPath = () => '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId);
const getInstanceStatus = async () => {
  const r = await rawRequest('GET', instPath(), { timeoutMs: 30000 });
  return { ok: bizOk(r), status: r.body?.data?.status, body: r.body };
};

/** 轮询实例状态直到目标态；error/terminated 视为终态提前返回 */
async function waitStatus(target, maxMs, intervalMs = 6000) {
  const start = Date.now();
  let lastStatus;
  while (Date.now() - start < maxMs) {
    const s = await getInstanceStatus();
    lastStatus = s.status;
    if (lastStatus === target) return { hit: true, status: lastStatus };
    if (lastStatus === 'error' || lastStatus === 'terminated') return { hit: false, status: lastStatus, terminal: true };
    log('  实例状态: ' + lastStatus + '（等待 ' + target + '...）');
    await sleep(intervalMs);
  }
  return { hit: false, status: lastStatus };
}

/** 重启实例并等待 running（自愈/环境还原共用） */
async function restartInstance(maxMs = 300000) {
  const r = await healRequest('POST', instPath() + '/restart', { timeoutMs: 120000 });
  if (!bizOk(r)) return { ok: false, status: null };
  const w = await waitStatus('running', maxMs);
  return { ok: w.hit, status: w.status };
}

const TS = Date.now();

/** 最小 WebSocket 客户端：接收/解析帧、回 pong、发送带掩码的文本帧、等待 JSON-RPC 响应 */
async function openWsKeepAlive(wsUrl, headers = {}, keepMs = 300000) {
  const url = new URL(wsUrl);
  const secure = url.protocol === 'wss:';
  const mod = secure ? await import('node:https') : await import('node:http');
  const key = crypto.randomBytes(16).toString('base64');
  return new Promise((resolve, reject) => {
    const req = mod.request({
      hostname: url.hostname, port: url.port || (secure ? 443 : 80),
      path: url.pathname + url.search, method: 'GET',
      headers: {
        Upgrade: 'websocket', Connection: 'Upgrade', Origin: BASE,
        'Sec-WebSocket-Key': key, 'Sec-WebSocket-Version': '13',
        ...headers,
      },
    });
    req.setTimeout(15000, () => { req.destroy(new Error('WS 握手超时')); });
    req.on('upgrade', (res, socket) => {
      log('  WS 已连接:', wsUrl.slice(0, 110));
      let buf = Buffer.alloc(0);
      const pending = new Map();
      socket.on('data', (chunk) => {
        buf = Buffer.concat([buf, chunk]);
        while (buf.length >= 2) {
          const opcode = buf[0] & 0x0f;
          const masked = (buf[1] & 0x80) !== 0;
          let len = buf[1] & 0x7f, off = 2;
          if (len === 126) { if (buf.length < 4) break; len = buf.readUInt16BE(2); off = 4; }
          else if (len === 127) { if (buf.length < 10) break; len = Number(buf.readBigUInt64BE(2)); off = 10; }
          const maskLen = masked ? 4 : 0;
          if (buf.length < off + maskLen + len) break;
          let payload = buf.subarray(off + maskLen, off + maskLen + len);
          if (masked) {
            const mask = buf.subarray(off, off + 4);
            const out = Buffer.from(payload);
            for (let i = 0; i < out.length; i++) out[i] ^= mask[i % 4];
            payload = out;
          }
          if (opcode === 0x9) {
            const mask = crypto.randomBytes(4);
            const maskedPayload = Buffer.from(payload);
            for (let i = 0; i < maskedPayload.length; i++) maskedPayload[i] ^= mask[i % 4];
            const hdr = Buffer.from([0x8a, 0x80 | maskedPayload.length]);
            socket.write(Buffer.concat([hdr, mask, maskedPayload]));
          } else if (opcode === 0x1 || opcode === 0x2) {
            const text = payload.toString('utf8');
            if (text.length < 300) log('  WS 收到:', text.slice(0, 200));
            try {
              const msg = JSON.parse(text);
              if (msg && msg.id !== undefined && pending.has(msg.id)) {
                pending.get(msg.id)(msg);
                pending.delete(msg.id);
              }
            } catch {}
          }
          buf = buf.subarray(off + maskLen + len);
        }
      });
      socket.on('error', (e) => log('  WS 错误:', e.message));
      socket.on('close', () => log('  WS 关闭'));
      const killer = setTimeout(() => { try { socket.destroy(); } catch {} }, keepMs);
      const handle = {
        socket,
        sendJsonRpc: (msg, timeoutMs = 20000) => new Promise((res2) => {
          let payload = Buffer.from(JSON.stringify(msg), 'utf8');
          const mask = crypto.randomBytes(4);
          for (let i = 0; i < payload.length; i++) payload[i] ^= mask[i % 4];
          let hdr;
          if (payload.length < 126) hdr = Buffer.from([0x81, 0x80 | payload.length]);
          else if (payload.length < 65536) {
            hdr = Buffer.alloc(4);
            hdr[0] = 0x81; hdr[1] = 0x80 | 126; hdr.writeUInt16BE(payload.length, 2);
          } else {
            hdr = Buffer.alloc(10);
            hdr[0] = 0x81; hdr[1] = 0x80 | 127; hdr.writeBigUInt64BE(BigInt(payload.length), 2);
          }
          socket.write(Buffer.concat([hdr, mask, payload]));
          const t = setTimeout(() => { pending.delete(msg.id); res2(null); }, timeoutMs);
          pending.set(msg.id, (m) => { clearTimeout(t); res2(m); });
        }),
        close: () => { clearTimeout(killer); try { socket.destroy(); } catch {} },
      };
      resolve(handle);
    });
    req.on('response', (res) => reject(new Error('WS 握手失败 HTTP ' + res.statusCode)));
    req.on('error', reject);
    req.end();
  });
}

let wsHandle = null;
/**
 * ACP 连接自愈（3.2 创建会话 409 时触发）:
 * 服务化接口要求外部调用方持有"活跃且已 initialize"的 ACP 连接。
 * 使用 2.2 connect 返回的 wsUrl 建立裸 WS → 发送 initialize → 等待响应与 session/new 通知。
 */
async function wsInitialize() {
  try {
    if (!state.wsUrl) return false;
    let wsUrl = state.wsUrl;
    if (wsUrl.startsWith('/')) wsUrl = 'wss://' + new URL(BASE).host + wsUrl;
    else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) wsUrl = 'wss://' + wsUrl;
    if (wsHandle) { try { wsHandle.close(); } catch {} wsHandle = null; }
    wsHandle = await openWsKeepAlive(wsUrl, {}, 300000);
    const resp = await wsHandle.sendJsonRpc(
      { jsonrpc: '2.0', id: Date.now(), method: 'initialize', params: { protocolVersion: 1, clientCapabilities: {} } },
      20000,
    );
    log('  ACP initialize 响应: ' + (resp ? JSON.stringify(resp).slice(0, 150) : '超时（继续尝试）'));
    await sleep(3000); // 等待 session/new 等服务端通知就绪
    return true;
  } catch (e) {
    log('  WS 自愈失败: ' + e.message);
    wsHandle = null;
    return false;
  }
}


const steps = [
  { id: '1.1', name: '查询全部在线智能体空间', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces');
    const list = Array.isArray(r.body?.data) ? r.body.data : [];
    // 实例发现：优先 running；否则选最近更新的非 terminated 实例（交由 1.2 自愈拉起）；集合不含创建实例端点
    const running = list.filter((i) => i.status === 'running');
    const alive = list.filter((i) => i.status !== 'terminated')
      .sort((a, b) => String(b.updatedAt || '').localeCompare(String(a.updatedAt || '')));
    const chosen = running[0] || alive[0];
    let healNote = '';
    if (chosen) {
      state.instanceId = String(pick(chosen, 'instanceId') || '');
      state.workspaceId = pick(chosen, 'workspaceId') !== undefined ? String(chosen.workspaceId) : state.workspaceId;
      if (!running.length) healNote = '；无 running 实例，选中 status=' + chosen.status + '（将由 1.2 自愈拉起）';
    }
    return { ok: bizOk(r) && !!state.instanceId, note: bizNote(r) + '；实例数=' + list.length + '，选中 instanceId=' + (state.instanceId || '-') + (state.workspaceId ? '（workspaceId=' + state.workspaceId + '）' : '') + healNote };
  } },
  { id: '1.2', name: '实例详情（兼作状态轮询）', run: async () => {
    const first = await healRequest('GET', instPath());
    let note = bizNote(first);
    let ok = bizOk(first);
    if (ok) {
      let st = first.body?.data?.status;
      if (st !== 'running') {
        log('  实例 status=' + st + '，非 running');
        let healed = false;
        // stopped/短暂中间态：先等待；仍非 running 或终态 → 自愈: restart 拉起
        if (st !== 'error' && st !== 'terminated') {
          const w = await waitStatus('running', 120000);
          if (w.hit) st = 'running';
          else st = w.status;
        }
        if (st !== 'running') {
          log('  实例 ' + st + ' → 自愈: 调用 restart 拉起并等待 running');
          const rr = await restartInstance(300000);
          healed = rr.ok;
          st = rr.status;
        }
        note += '；初始 status=' + first.body?.data?.status + '，最终 status=' + st
          + (healed ? '；@healed restart 拉起后恢复 running' : '（未恢复）');
        ok = healed || st === 'running';
      } else note += '；status=running';
    }
    return { ok, note };
  } },
  { id: '2.1', name: '进入实例', run: async () => {
    const r = await healRequest('POST', instPath() + '/enter', { json: { userId: USER_ID }, pat: true, timeoutMs: 120000 });
    const d = r.body?.data || {};
    const homeDir = pick(d, 'homeDir');
    return { ok: bizOk(r), note: bizNote(r) + (homeDir ? '；homeDir=' + homeDir + ', projectSlug=' + (pick(d, 'projectSlug') || '-') : '') };
  } },
  { id: '2.2', name: '获取连接信息', run: async () => {
    const r = await healRequest('POST', instPath() + '/connect', { json: { userId: USER_ID }, pat: true, timeoutMs: 120000 });
    const d = r.body?.data || {};
    const wsUrl = pick(d, 'wsUrl');
    if (wsUrl) state.wsUrl = wsUrl;
    return { ok: bizOk(r), note: bizNote(r) + (wsUrl ? '；wsUrl=' + String(wsUrl).slice(0, 90) : '') };
  } },
  { id: '2.3', name: '查询用户连接状态', run: async () => {
    const r = await healRequest('GET', instPath() + '/connection-status', { query: { userId: USER_ID } });
    const d = r.body?.data || {};
    return { ok: bizOk(r), note: bizNote(r) + '；connected=' + (pick(d, 'connected') ?? '-') + ', connectionCount=' + (pick(d, 'connectionCount') ?? '-') };
  } },
  { id: '3.1', name: '会话列表', run: async () => {
    const r = await healRequest('GET', instPath() + '/sessions', { query: { userId: USER_ID } });
    const list = Array.isArray(r.body?.data) ? r.body.data : [];
    return { ok: bizOk(r), note: bizNote(r) + '；会话数=' + list.length };
  } },
  { id: '3.2', name: '创建会话', run: async () => {
    const path = instPath() + '/sessions';
    const json = { userId: USER_ID };
    let healedNote = '';
    const r = await healRequest('POST', path, { json }, {
      extraHeal: async (last) => {
        if (last.status !== 409) return null;
        // 自愈: 无活跃 ACP 连接被拒 → 按 2.2 的 wsUrl 建立 ACP WS 连接并 initialize 后重试
        log('  创建会话 409 → 自愈: 建立 ACP WebSocket 连接并 initialize 后重试');
        const ok = await wsInitialize();
        if (!ok) return null;
        const r2 = await rawRequest('POST', path, { json });
        if (bizOk(r2) && pick(r2.body?.data, 'sessionId')) healedNote = '，@healed 建立 ACP WS 连接并 initialize 后重试成功';
        return r2;
      },
    });
    const d = r.body?.data || {};
    const id = pick(d, 'sessionId') || pick(d.session, 'sessionId') || pick(d, 'id');
    if (id) state.sessionId = String(id);
    return { ok: bizOk(r) && !!id, note: bizNote(r) + '；sessionId=' + (id || '-') + healedNote };
  } },
  { id: '3.4', name: '获取会话可用模型', run: async () => {
    if (!state.sessionId) return { ok: false, note: '级联失败: 未获得 sessionId（3.2 创建会话失败）' };
    const r = await healRequest('GET', instPath() + '/sessions/' + encodeURIComponent(state.sessionId) + '/models', { query: { userId: USER_ID } });
    const cm = pick(r.body?.data, 'currentModel') || pick(r.body?.data, 'model');
    if (cm) state.modelId = String(cm);
    const models = Array.isArray(r.body?.data?.models) ? r.body.data.models.length : '-';
    return { ok: bizOk(r), note: bizNote(r) + '；currentModel=' + (cm || '-') + ', models=' + models };
  } },
  { id: '3.5', name: '切换会话模型', run: async () => {
    if (!state.sessionId) return { ok: false, note: '级联失败: 未获得 sessionId（3.2 创建会话失败）' };
    const model = state.modelId || 'deepseek-v4.1-flash';
    const r = await healRequest('POST', instPath() + '/sessions/' + encodeURIComponent(state.sessionId) + '/model', {
      json: { userId: USER_ID, model },
    });
    const cm = pick(r.body?.data, 'currentModel');
    return { ok: bizOk(r), note: bizNote(r) + '；model=' + model + (cm ? '，切换后 currentModel=' + cm : '') };
  } },
  { id: '3.6', name: '获取会话历史', run: async () => {
    if (!state.sessionId) return { ok: false, note: '级联失败: 未获得 sessionId（3.2 创建会话失败）' };
    const r = await healRequest('GET', instPath() + '/sessions/' + encodeURIComponent(state.sessionId) + '/history', {
      query: { limit: 50, userId: USER_ID },
    });
    const msgs = Array.isArray(r.body?.data?.messages) ? r.body.data.messages.length : '-';
    return { ok: bizOk(r), note: bizNote(r) + '；messages=' + msgs };
  } },
  { id: '3.7', name: '停止生成', run: async () => {
    if (!state.sessionId) return { ok: false, note: '级联失败: 未获得 sessionId（3.2 创建会话失败）' };
    const r = await healRequest('POST', instPath() + '/generation/stop', {
      json: { userId: USER_ID, sessionId: state.sessionId },
    });
    const stopped = pick(r.body?.data, 'stopped');
    return { ok: bizOk(r), note: bizNote(r) + (stopped !== undefined ? '；stopped=' + stopped : '') };
  } },
  { id: '4.1', name: '上传文件', run: async () => {
    const fileName = 'api-test-' + TS + '.txt';
    const form = new FormData();
    form.append('file', new Blob(['FT-TBD 服务化接口测试上传文件 ' + new Date().toISOString()], { type: 'text/plain' }), fileName);
    form.append('path', '');
    const r = await healRequest('POST', instPath() + '/artifacts', {
      query: { userId: USER_ID }, form, timeoutMs: 120000,
    });
    const fullPath = pick(r.body?.data, 'path', 'fullPath', 'filePath');
    let filePath = '';
    if (fullPath) {
      const m = String(fullPath).match(/\/projects\/[^/]+\/(.+)$/);
      filePath = m ? m[1] : String(fullPath);
    }
    if (!filePath) filePath = fileName;
    state.filePath = filePath;
    state.artifactPath = filePath;
    return { ok: bizOk(r), note: bizNote(r) + '；filePath=' + filePath };
  } },
  { id: '4.2', name: '下载文件', run: async () => {
    const r = await healRequest('GET', instPath() + '/artifacts', {
      query: { path: state.filePath, userId: USER_ID },
    });
    const ct = r.headers?.get?.('content-type') || '';
    const bytes = r.byteLength ?? (r.text ? Buffer.byteLength(r.text) : 0);
    return { ok: bizOk(r) && bytes > 0, note: bizNote(r) + '；contentType=' + (ct || '-') + ', bytes=' + bytes };
  } },
  { id: '4.3', name: '上传制品到智能体空间', run: async () => {
    const r = await healRequest('POST', instPath() + '/workspace-artifacts', {
      json: { userId: USER_ID, path: state.artifactPath || state.filePath },
      timeoutMs: 120000,
    });
    const d = r.body?.data || {};
    const id = pick(d, 'artifactId', 'id');
    if (id) state.artifactId = String(id);
    return { ok: bizOk(r) && !!id, note: bizNote(r) + '；artifactId=' + (id || '-') };
  } },
  { id: '4.4', name: '获取智能体空间制品列表', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.workspaceId) + '/workspace-artifacts');
    const list = Array.isArray(r.body?.data) ? r.body.data : [];
    const found = list.some((a) => String(pick(a, 'artifactId')) === String(state.artifactId));
    return { ok: bizOk(r), note: bizNote(r) + '；制品数=' + list.length + (state.artifactId ? '，含本次上传 artifactId=' + state.artifactId + '：' + (found ? '是' : '否') : '') };
  } },
  { id: '4.5', name: '下载制品（按 artifactId）', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/artifacts/' + encodeURIComponent(state.artifactId));
    const ct = r.headers?.get?.('content-type') || '';
    const bytes = r.byteLength ?? (r.text ? Buffer.byteLength(r.text) : 0);
    return { ok: bizOk(r) && bytes > 0, note: bizNote(r) + '；contentType=' + (ct || '-') + ', bytes=' + bytes + (r.binary ? '（zip 二进制）' : '') };
  } },
  { id: '3.3', name: '删除会话', run: async () => {
    if (!state.sessionId) return { ok: false, note: '级联失败: 未获得 sessionId（3.2 创建会话失败）' };
    const r = await healRequest('POST', instPath() + '/sessions/' + encodeURIComponent(state.sessionId), { query: { userId: USER_ID } });
    const deleted = pick(r.body?.data, 'deleted');
    return { ok: bizOk(r), note: bizNote(r) + (deleted !== undefined ? '；deleted=' + deleted : '') };
  } },
  { id: '1.4', name: '重启实例', run: async () => {
    const r = await healRequest('POST', instPath() + '/restart', { timeoutMs: 120000 });
    const ok = bizOk(r);
    if (ok) {
      log('  等待实例重启就绪...');
      const w = await waitStatus('running', 300000);
      return { ok: w.hit, note: bizNote(r) + '；重启后 status=' + w.status };
    }
    return { ok, note: bizNote(r) };
  } },
  { id: '1.3', name: '暂停实例', run: async () => {
    const r = await healRequest('POST', instPath() + '/stop', { timeoutMs: 120000 });
    const ok = bizOk(r);
    if (!ok) return { ok, note: bizNote(r) };
    const w = await waitStatus('stopped', 120000, 4000);
    let note = bizNote(r) + '；停止后 status=' + w.status;
    // 环境还原：实例非本脚本创建，测试后自动 restart 恢复 running，避免影响他人
    log('  自愈: 自动重启恢复实例到 running（环境还原）');
    const rr = await restartInstance(300000);
    note += rr.ok ? '；@restored 已自动重启恢复 running' : '；⚠ 恢复失败，实例停留在 ' + rr.status + '，请人工确认';
    return { ok: w.hit && rr.ok, note };
  } },
];

// 报告展示顺序（Postman v2 集合编号顺序，共 19 个接口）
const displayOrder = [
  '1.1', '1.2', '1.3', '1.4',
  '2.1', '2.2', '2.3',
  '3.1', '3.2', '3.3', '3.4', '3.5', '3.6', '3.7',
  '4.1', '4.2', '4.3', '4.4', '4.5',
];

function writeReport(okCount, failIds, missingIds) {
  const stamp = new Date().toISOString().replace(/[:T]/g, '-').slice(0, 19);
  const L = [];
  L.push('# FT-TBD 在线智能体空间开放接入（服务化接口）— 接口测试报告');
  L.push('');
  L.push('- **测试时间**: ' + new Date().toISOString());
  L.push('- **环境**: ' + BASE);
  L.push('- **userId**: ' + USER_ID + '（openAccessToken: ' + OAT.slice(0, 12) + '...）');
  L.push('- **实例**: ' + (state.instanceId || '-') + '（workspaceId=' + (state.workspaceId || '-') + '）');
  L.push('- **汇总**: ' + okCount + '/' + displayOrder.length + ' 通过'
    + (failIds.length ? '；失败: ' + failIds.join(', ') : '')
    + (missingIds.length ? '；未执行: ' + missingIds.join(', ') : ''));
  const fmtSec = (ms) => (ms === undefined || ms === null) ? '-' : (ms / 1000).toFixed(2);
  L.push('');
  L.push('| 接口编号 | 接口名称 | 执行结果 | 响应时间(秒) | 说明 |');
  L.push('|:--------|:--------------------|:---------|------------:|:----------------------------------------|');
  for (const id of displayOrder) {
    const r = results[id];
    if (!r) { L.push('| ' + id + ' | - | ⏸ 未执行 | - | 执行中断 |'); continue; }
    L.push('| ' + id + ' | ' + r.name + ' | ' + (r.ok ? '✅ 成功' : '❌ 失败') + ' | '
      + fmtSec(r.respMs !== undefined ? r.respMs : r.durationMs) + ' | '
      + String(r.note || '').replace(/\|/g, '/').slice(0, 200) + ' |');
  }
  const respTimes = displayOrder
    .map((id) => results[id] && results[id].respMs)
    .filter((ms) => ms !== undefined && ms !== null);
  if (respTimes.length) {
    const total = respTimes.reduce((a, b) => a + b, 0);
    const avg = total / respTimes.length;
    const max = Math.max(...respTimes);
    const maxId = displayOrder.find((id) => results[id] && results[id].respMs === max);
    L.push('');
    L.push('**响应时间统计**（rawRequest 层 HTTP 纯请求耗时，不含轮询等待）: 平均 '
      + (avg / 1000).toFixed(2) + ' 秒，最长 ' + (max / 1000).toFixed(2) + ' 秒（' + maxId + '），'
      + '合计 ' + (total / 1000).toFixed(2) + ' 秒，共 ' + respTimes.length + ' 个接口。');
  }
  const file = DIR + 'report-' + stamp + '.md';
  fs.writeFileSync(file, L.join('\n'));
  return file;
}

async function main() {
  if (FRESH) {
    fs.writeFileSync(RESULTS_FILE, '{}');
    fs.writeFileSync(STATE_FILE, '{}');
    results = {}; state = {};
  }
  log('=== FT-TBD 服务化接口测试开始（' + BASE + ' userId=' + USER_ID + '）===');
  let skipped = 0;
  for (const step of steps) {
    if (results[step.id]?.ok) {
      log('[SKIP] ' + step.id + ' ' + step.name + '（已成功）');
      skipped++;
      continue;
    }
    const start = Date.now();
    resetHttpTime();
    log('[RUN ] ' + step.id + ' ' + step.name);
    let out = { ok: false, note: '未执行' };
    try {
      out = await step.run() || out;
    } catch (e) {
      out = { ok: false, note: '异常: ' + e.message };
    }
    results[step.id] = { id: step.id, name: step.name, ok: !!out.ok, note: out.note || '', durationMs: Date.now() - start, respMs: httpTime.ms, reqCount: httpTime.count };
    saveFiles();
    log('[DONE] ' + step.id + ' ' + step.name + ' → ' + (out.ok ? '✅ 成功' : '❌ 失败') + ' (耗时 ' + results[step.id].durationMs + 'ms, HTTP 响应 ' + httpTime.ms + 'ms/' + httpTime.count + '次) ' + (out.note || ''));
    if (!out.ok && ['1.1', '1.2'].includes(step.id)) {
      log('!!! 依赖步骤 ' + step.id + ' 失败（无可用实例/实例无法拉起），中止执行');
      break;
    }
    if (!out.ok && step.id === '2.2') {
      log('  警告: connect 失败，会话相关后续步骤可能失败，继续执行其余接口');
    }
  }
  if (wsHandle) { try { wsHandle.close(); } catch {} }
  const okCount = displayOrder.filter((id) => results[id]?.ok).length;
  const failIds = displayOrder.filter((id) => results[id] && !results[id].ok);
  const missingIds = displayOrder.filter((id) => !results[id]);
  const reportFile = writeReport(okCount, failIds, missingIds);
  log('=== 执行完成: ' + okCount + '/' + displayOrder.length + ' 成功（跳过已成功 ' + skipped + '）===');
  log('报告已生成: ' + reportFile);
  process.exitCode = missingIds.length ? 2 : (failIds.length ? 1 : 0);
}

main().catch((e) => {
  log('致命错误: ' + (e.stack || e.message));
  process.exitCode = 2;
});
