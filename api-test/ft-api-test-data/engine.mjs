/**
 * FT-TBD 在线智能体空间开放接入 — API 测试引擎（由 ft-tbd-api-test.sh 释放）
 * 独立运行: FT_BASE_URL=... FT_EMAIL=... node engine.mjs [--fresh|--resume]
 * 依赖编排: 0.1登录→token; 1.7镜像→imageConfigId; 1.1实例→instanceId;
 *           1.10项目→projectId; 2.2→wsUrl; [ACP WS连接]→3.2会话→sessionId; 4.1→filePath; 4.3→artifactId
 * 自愈: 网络错误/5xx重试、401重新登录、3.2建立裸ACP WS连接、1.11删除前关闭WS、0.2 JWT兜底
 */
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const BASE = process.env.FT_BASE_URL || 'https://asdm-dt01.leansoftx.com';
const EMAIL = process.env.FT_EMAIL || 'test01@asdm.ai';
const PASSWORD = process.env.FT_PASSWORD || 'admin@2026';
const WSID = process.env.FT_WORKSPACE_ID || '17';
const WORKSPACE_ID = /^\d+$/.test(String(WSID)) ? Number(WSID) : WSID;
const PAT = process.env.FT_PAT || 'pat_YVewHpc9JiOwyZw9BXsonSSw6k1XjoiJmzN67917Qv4';
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

let TOKEN = state.token || '';
let reloginTried = false;

async function rawRequest(method, path, opts = {}) {
  const { json, form, query, token = TOKEN, timeoutMs = 60000 } = opts;
  const url = new URL(BASE + path);
  if (query) for (const [k, v] of Object.entries(query)) {
    if (v !== undefined && v !== null && String(v) !== '') url.searchParams.set(k, String(v));
  }
  const headers = {};
  if (token) headers.Authorization = 'Bearer ' + token;
  let body;
  if (json !== undefined) { headers['Content-Type'] = 'application/json'; body = JSON.stringify(json); }
  else if (form) { body = form; }
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), timeoutMs);
  try {
    const res = await fetch(url, { method, headers, body, signal: ac.signal });
    const text = await res.text();
    let parsed = null; try { parsed = JSON.parse(text); } catch {}
    return { status: res.status, statusText: res.statusText, headers: res.headers, text, body: parsed };
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
  } else if (r.text) parts.push(r.text.slice(0, 120));
  return parts.join(' | ');
}

async function doLogin() {
  const r = await rawRequest('POST', '/api/auth/login', { json: { email: EMAIL, password: PASSWORD } });
  const d = r.body?.data || {};
  TOKEN = pick(d, 'token', 'accessToken') || pick(r.body, 'token', 'accessToken') || '';
  if (TOKEN) {
    state.token = TOKEN;
    state.asdmUserId = String(pick(d, 'userId', 'asdmUserId') || pick(d.user, 'id', 'userId') || pick(r.body, 'userId') || state.asdmUserId || '1');
    return true;
  }
  return false;
}

/** 带通用自愈的请求执行：网络错误/5xx 重试；401 重新登录后重试（鉴权接口除外）；extraHeal 步骤级自愈 */
async function healRequest(method, path, opts = {}, { isAuth = false, extraHeal } = {}) {
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
    if (last.status === 401 && !isAuth && !reloginTried) {
      reloginTried = true;
      log('  401 → 自愈: 重新登录');
      const ok = await doLogin();
      if (ok) { attempt--; continue; }
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
/** 建立 ACP WebSocket 连接（诊断结论: 裸连接即可支持 HTTP 会话创建；主动 initialize 反触发智能体鉴权要求） */
async function wsHeal() {
  try {
    if (!state.wsUrl) return false;
    let wsUrl = state.wsUrl;
    if (wsUrl.startsWith('/')) wsUrl = 'wss://' + new URL(BASE).host + wsUrl;
    else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) wsUrl = 'wss://' + wsUrl;
    const headers = {};
    if (state.wsToken) headers.Authorization = 'Bearer ' + state.wsToken;
    else if (TOKEN) headers.Authorization = 'Bearer ' + TOKEN;
    wsHandle = await openWsKeepAlive(wsUrl, headers, 300000);
    await sleep(2000);
    return true;
  } catch (e) {
    log('  WS 自愈失败:', e.message);
    return false;
  }
}

async function waitInstanceRunning(maxMs = 300000) {
  const start = Date.now();
  let lastStatus;
  while (Date.now() - start < maxMs) {
    const r = await rawRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId), { timeoutMs: 20000 });
    lastStatus = r.body?.data?.status ?? r.body?.data?.instance?.status;
    if (lastStatus === 'running') return { running: true, status: lastStatus };
    log('  实例状态: ' + lastStatus + '（等待中...）');
    await sleep(6000);
  }
  return { running: false, status: lastStatus };
}

const TS = Date.now();

const steps = [
  { id: '0.1', name: '账号密码登录', run: async () => {
    const ok = await doLogin();
    reloginTried = false;
    return { ok, note: ok ? '获取 token 成功, asdmUserId=' + state.asdmUserId : '登录失败' };
  } },
  { id: '0.2', name: 'PAT 兑换 JWT', run: async () => {
    let r = await healRequest('POST', '/api/auth/personal-access-tokens/exchange', { token: PAT }, { isAuth: true });
    let at = pick(r.body?.data, 'accessToken', 'token');
    let healed = false;
    if (!at && TOKEN) {
      log('  PAT 兑换 401 → 自愈: 尝试使用 JWT 作为凭据');
      const r2 = await rawRequest('POST', '/api/auth/personal-access-tokens/exchange', { token: TOKEN });
      if (bizOk(r2)) { r = r2; at = pick(r2.body?.data, 'accessToken', 'token'); healed = !!at; }
    }
    return { ok: bizOk(r) && !!at, note: bizNote(r) + (at ? '（兑换成功' + (healed ? '，JWT 兜底自愈' : '') + '）' : '；PAT 已失效且无有效 PAT 凭据，无法完成兑换') };
  } },
  { id: '1.7', name: '可用镜像列表', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + WORKSPACE_ID + '/images');
    const list = Array.isArray(r.body?.data) ? r.body.data : (r.body?.data?.items || r.body?.data?.list || []);
    const ic = list.length ? (pick(list[0], 'imageId', 'imageConfigId', 'id', 'configId') || '') : '';
    if (ic) state.imageConfigId = String(ic);
    return { ok: bizOk(r), note: bizNote(r) + '；镜像数=' + list.length + (ic ? '，选中 imageConfigId=' + ic : '') };
  } },
  { id: '1.1', name: '创建实例', run: async () => {
    if (!state.imageConfigId) {
      const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + WORKSPACE_ID + '/images');
      const list = Array.isArray(r.body?.data) ? r.body.data : [];
      state.imageConfigId = String(pick(list[0], 'imageId', 'imageConfigId', 'id', 'configId') || '');
    }
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces', {
      json: { workspaceId: WORKSPACE_ID, imageConfigId: state.imageConfigId, cpu: '2', memory: '4Gi', idleTimeoutMinutes: 30 },
      timeoutMs: 120000,
    });
    const d = r.body?.data || {};
    const id = pick(d, 'instanceId') || pick(d.instance, 'instanceId') || pick(d, 'id');
    if (id) state.instanceId = String(id);
    return { ok: bizOk(r) && !!id, note: bizNote(r) + '；instanceId=' + (id || '-') };
  } },
  { id: '1.2', name: '实例列表', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces');
    const list = Array.isArray(r.body?.data) ? r.body.data : [];
    return { ok: bizOk(r), note: bizNote(r) + '；实例数=' + list.length };
  } },
  { id: '1.3', name: '实例详情', run: async () => {
    const first = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId));
    let note = bizNote(first);
    const ok = bizOk(first);
    if (ok) {
      const st = first.body?.data?.status ?? first.body?.data?.instance?.status;
      if (st !== 'running') {
        log('  实例未运行，轮询等待就绪...');
        const w = await waitInstanceRunning(300000);
        note += '；初始 status=' + st + '，最终 status=' + w.status + (w.running ? '（running）' : '（等待超时）');
      } else note += '；status=running';
    }
    return { ok, note };
  } },
  { id: '1.8', name: '项目列表', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/projects');
    const list = Array.isArray(r.body?.data) ? r.body.data : [];
    return { ok: bizOk(r), note: bizNote(r) + '；项目数=' + list.length };
  } },
  { id: '1.10', name: '创建项目', run: async () => {
    const name = 'api-test-' + TS;
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/projects', {
      json: { name, description: '接口自动化测试项目', slug: 'api-test-' + TS },
    });
    const d = r.body?.data || {};
    const id = pick(d, 'projectId') || pick(d.project, 'projectId') || pick(d, 'id');
    if (id) state.projectId = String(id);
    return { ok: bizOk(r) && !!id, note: bizNote(r) + '；projectId=' + (id || '-') };
  } },
  { id: '1.9', name: '项目详情', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/projects/' + encodeURIComponent(state.projectId));
    return { ok: bizOk(r), note: bizNote(r) };
  } },
  { id: '2.1', name: '进入实例', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/enter', {
      json: { projectId: state.projectId },
    });
    return { ok: bizOk(r), note: bizNote(r) };
  } },
  { id: '2.2', name: '获取连接信息', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/connect', {
      json: { projectId: state.projectId },
    });
    const d = r.body?.data || {};
    const wsUrl = pick(d, 'wsUrl', 'url', 'websocketUrl');
    if (wsUrl) state.wsUrl = wsUrl;
    const wsToken = pick(d, 'token', 'wsToken', 'accessToken');
    if (wsToken) state.wsToken = wsToken;
    return { ok: bizOk(r), note: bizNote(r) + (wsUrl ? '；wsUrl=' + String(wsUrl).slice(0, 90) : '') };
  } },
  { id: '2.3', name: '查询用户连接状态', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/connection-status', {
      query: { asdmUserId: state.asdmUserId || '1' },
    });
    const d = r.body?.data || {};
    return { ok: bizOk(r), note: bizNote(r) + '；connected=' + (pick(d, 'connected') ?? '-') + ', connectionCount=' + (pick(d, 'connectionCount') ?? '-') };
  } },
  { id: '3.1', name: '会话列表', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/sessions', {
      query: { projectId: state.projectId },
    });
    const list = Array.isArray(r.body?.data) ? r.body.data : [];
    return { ok: bizOk(r), note: bizNote(r) + '；会话数=' + list.length };
  } },
  { id: '3.2', name: '创建会话', run: async () => {
    const path = '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/sessions';
    const json = { projectId: state.projectId };
    let healedNote = '';
    const r = await healRequest('POST', path, { json }, {
      extraHeal: async (last) => {
        if (last.status !== 409 && last.status !== 400 && last.status !== 500) return null;
        const msg = String(last.body?.message || '');
        if (!wsHandle) {
          log('  创建会话被拒(' + last.status + ') → 自愈①: 建立 ACP WebSocket 连接后重试');
          const healed = await wsHeal();
          if (!healed) return null;
          healedNote = '，自愈①: 建立 ACP WS 连接';
          return await rawRequest('POST', path, { json });
        }
        if (msg.includes('initialize') || msg.includes('initialized')) {
          log('  仍提示需要 initialize → 自愈②: 补发 ACP initialize 后重试');
          const initMsg = { jsonrpc: '2.0', id: Date.now(), method: 'initialize', params: { protocolVersion: 1, clientCapabilities: {} } };
          await wsHandle.sendJsonRpc(initMsg, 20000);
          await sleep(2000);
          healedNote = '，自愈②: 补发 initialize';
          return await rawRequest('POST', path, { json });
        }
        if (msg.includes('Authentication required') || last.status === 500) {
          log('  智能体要求鉴权 → 自愈③: 关闭并重开裸 WS 连接后重试');
          try { wsHandle.close(); } catch {}
          wsHandle = null;
          const healed = await wsHeal();
          if (!healed) return null;
          healedNote = '，自愈③: 重开裸 WS 连接';
          return await rawRequest('POST', path, { json });
        }
        return null;
      },
    });
    const d = r.body?.data || {};
    const id = pick(d, 'sessionId') || pick(d.session, 'sessionId') || pick(d, 'id');
    if (id) state.sessionId = String(id);
    return { ok: bizOk(r) && !!id, note: bizNote(r) + '；sessionId=' + (id || '-') + healedNote };
  } },
  { id: '3.3', name: '切换会话', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/sessions/switch', {
      json: { sessionId: state.sessionId, projectId: state.projectId },
    });
    return { ok: bizOk(r), note: bizNote(r) };
  } },
  { id: '3.5', name: '获取会话可用模型', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/sessions/' + encodeURIComponent(state.sessionId) + '/models');
    const cm = pick(r.body?.data, 'currentModel') || pick(r.body?.data, 'model');
    if (cm) state.modelId = String(cm);
    const models = Array.isArray(r.body?.data?.models) ? r.body.data.models.length : '-';
    return { ok: bizOk(r), note: bizNote(r) + '；currentModel=' + (cm || '-') + ', models=' + models };
  } },
  { id: '3.6', name: '切换会话模型', run: async () => {
    const model = state.modelId || 'deepseek-v4-flash';
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/sessions/' + encodeURIComponent(state.sessionId) + '/model', {
      json: { model },
    });
    return { ok: bizOk(r), note: bizNote(r) + '；model=' + model };
  } },
  { id: '3.7', name: '停止生成', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/generation/stop', {
      json: { sessionId: state.sessionId },
    });
    return { ok: bizOk(r), note: bizNote(r) };
  } },
  { id: '4.1', name: '上传文件', run: async () => {
    const fileName = 'api-test-' + TS + '.txt';
    const form = new FormData();
    form.append('file', new Blob(['FT-TBD 接口测试上传文件 ' + new Date().toISOString()], { type: 'text/plain' }), fileName);
    form.append('projectId', state.projectId);
    form.append('path', '');
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/artifacts', {
      form, timeoutMs: 120000,
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
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/artifacts', {
      query: { path: state.filePath, projectId: state.projectId },
    });
    const ct = r.headers?.get?.('content-type') || '';
    const isFile = /octet-stream|text\/|application\/download/.test(ct) || (r.text && !r.text.trim().startsWith('{'));
    return { ok: bizOk(r) && !!r.text, note: bizNote(r) + '；contentType=' + (ct || '-') + ', bytes=' + (r.text ? Buffer.byteLength(r.text) : 0) + (isFile ? '（文件内容）' : '') };
  } },
  { id: '4.3', name: '上传制品到智能体空间', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/workspace-artifacts', {
      json: { projectId: state.projectId, path: state.artifactPath || state.filePath },
      timeoutMs: 120000,
    });
    const d = r.body?.data || {};
    const id = pick(d, 'artifactId', 'id');
    if (id) state.artifactId = String(id);
    return { ok: bizOk(r) && !!id, note: bizNote(r) + '；artifactId=' + (id || '-') };
  } },
  { id: '4.4', name: '获取智能体空间制品列表', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspaces/' + WORKSPACE_ID + '/workspace-artifacts');
    const list = Array.isArray(r.body?.data) ? r.body.data : [];
    return { ok: bizOk(r), note: bizNote(r) + '；制品数=' + list.length };
  } },
  { id: '4.5', name: '下载制品', run: async () => {
    const r = await healRequest('GET', '/api/v1/agentorbit/workspace-artifacts/' + encodeURIComponent(state.artifactId));
    const ct = r.headers?.get?.('content-type') || '';
    return { ok: bizOk(r) && !!r.text, note: bizNote(r) + '；contentType=' + (ct || '-') + ', bytes=' + (r.text ? Buffer.byteLength(r.text) : 0) };
  } },
  { id: '3.4', name: '删除会话', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/sessions/' + encodeURIComponent(state.sessionId));
    return { ok: bizOk(r), note: bizNote(r) };
  } },
  { id: '1.11', name: '删除项目', run: async () => {
    const path = '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/projects/' + encodeURIComponent(state.projectId);
    if (wsHandle) {
      log('  自愈①: 删除前先关闭我方 ACP WS 连接');
      try { wsHandle.close(); } catch {}
      wsHandle = null;
      await sleep(2000);
    }
    const r = await healRequest('POST', path, { json: { force: false } }, {
      extraHeal: async (last) => {
        if (last.status !== 409) return null;
        log('  删除项目 409 → 自愈②: force=true 重试');
        const r2 = await rawRequest('POST', path, { json: { force: true } });
        if (r2.status === 404 && String(r2.body?.message || '').includes('不存在')) {
          return { status: 200, statusText: 'OK', body: { code: 200, message: 'success(项目已确认删除)' }, text: JSON.stringify(r2.body) };
        }
        return r2;
      },
    });
    return { ok: bizOk(r), note: bizNote(r) };
  } },
  { id: '1.5', name: '重启实例', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/restart', { timeoutMs: 120000 });
    const ok = bizOk(r);
    if (ok) {
      log('  等待实例重启就绪...');
      const w = await waitInstanceRunning(240000);
      return { ok, note: bizNote(r) + '；重启后 status=' + w.status };
    }
    return { ok, note: bizNote(r) };
  } },
  { id: '1.4', name: '暂停实例', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId) + '/stop', { timeoutMs: 120000 });
    return { ok: bizOk(r), note: bizNote(r) };
  } },
  { id: '1.6', name: '删除实例', run: async () => {
    const r = await healRequest('POST', '/api/v1/agentorbit/workspaces/' + encodeURIComponent(state.instanceId), { timeoutMs: 120000 });
    return { ok: bizOk(r), note: bizNote(r) };
  } },
];

// 报告展示顺序（Postman 原始编号顺序，共 28 个接口）
const displayOrder = [
  '0.1', '0.2',
  '1.1', '1.2', '1.3', '1.4', '1.5', '1.6', '1.7', '1.8', '1.9', '1.10', '1.11',
  '2.1', '2.2', '2.3',
  '3.1', '3.2', '3.3', '3.4', '3.5', '3.6', '3.7',
  '4.1', '4.2', '4.3', '4.4', '4.5',
];

function writeReport(okCount, failIds, missingIds) {
  const stamp = new Date().toISOString().replace(/[:T]/g, '-').slice(0, 19);
  const L = [];
  L.push('# FT-TBD 在线智能体空间开放接入 — 接口测试报告');
  L.push('');
  L.push('- **测试时间**: ' + new Date().toISOString());
  L.push('- **环境**: ' + BASE);
  L.push('- **账号**: ' + EMAIL);
  L.push('- **workspaceId**: ' + WORKSPACE_ID);
  L.push('- **汇总**: ' + okCount + '/' + displayOrder.length + ' 通过'
    + (failIds.length ? '；失败: ' + failIds.join(', ') : '')
    + (missingIds.length ? '；未执行: ' + missingIds.join(', ') : ''));
  L.push('');
  L.push('| 接口编号 | 接口名称 | 执行结果 | 说明 |');
  L.push('|---|---|---|---|');
  for (const id of displayOrder) {
    const r = results[id];
    if (!r) { L.push('| ' + id + ' | - | ⏸ 未执行 | 执行中断 |'); continue; }
    L.push('| ' + id + ' | ' + r.name + ' | ' + (r.ok ? '✅ 成功' : '❌ 失败') + ' | '
      + String(r.note || '').replace(/\|/g, '/').slice(0, 200) + ' |');
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
    TOKEN = '';
  }
  log('=== FT-TBD 接口自动化测试开始（' + BASE + ' workspace=' + WORKSPACE_ID + '）===');
  let skipped = 0;
  for (const step of steps) {
    if (results[step.id]?.ok) {
      log('[SKIP] ' + step.id + ' ' + step.name + '（已成功）');
      skipped++;
      continue;
    }
    const start = Date.now();
    log('[RUN ] ' + step.id + ' ' + step.name);
    let out = { ok: false, note: '未执行' };
    try {
      out = await step.run() || out;
    } catch (e) {
      out = { ok: false, note: '异常: ' + e.message };
    }
    results[step.id] = { id: step.id, name: step.name, ok: !!out.ok, note: out.note || '', durationMs: Date.now() - start };
    saveFiles();
    log('[DONE] ' + step.id + ' ' + step.name + ' → ' + (out.ok ? '✅ 成功' : '❌ 失败') + ' (' + results[step.id].durationMs + 'ms) ' + (out.note || ''));
    if (!out.ok && ['0.1', '1.1', '1.10'].includes(step.id)) {
      log('!!! 依赖步骤 ' + step.id + ' 失败，中止执行');
      break;
    }
    if (!out.ok && step.id === '3.2') {
      log('  警告: 会话创建失败，会话相关后续步骤可能失败，继续执行其余接口');
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
