// 临时脚本：登录 DT01 获取 JWT，调用 AOS 快照列表 API，提取分析所需数据
const BASE = 'https://asdm-dt01.leansoftx.com';
const CONTEXT_ID = '42e8cb65-453c-4ec5-8485-617d4a5fbb53';

async function login() {
  const r = await fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'test01@asdm.ai', password: 'admin@2026' }),
  });
  const j = await r.json();
  const d = j.data || {};
  const token = d.token || d.accessToken || (j.token) || '';
  if (!token) throw new Error(`登录失败: code=${j.code} message=${j.message}`);
  console.error(`登录成功: code=${j.code}, tokenLen=${token.length}`);
  return token;
}

async function main() {
  const token = await login();
  const url = `${BASE}/api/aos/contexts/${CONTEXT_ID}/snapshots?page=1&pageSize=36&status=available`;
  const r = await fetch(url, { headers: { Authorization: 'Bearer ' + token } });
  const httpStatus = r.status;
  const j = await r.json();
  console.error(`API 调用: HTTP ${httpStatus}, code=${j.code}, message=${j.message}`);
  if (httpStatus !== 200 || j.code !== 0 || !j.data) {
    throw new Error(`API 调用失败: HTTP=${httpStatus}, code=${j.code}, message=${j.message}`);
  }

  const items = j.data.items || [];
  console.error(`返回快照数: ${items.length}, 分页: page=${j.data.page} pageSize=${j.data.pageSize} total=${j.data.total}`);

  const TYPES = ['Class','Route','Table','Mapper','Method','Module','Package','Function','Component','Interface','Dependency','Repository','ApiEndpoint'];
  const snapshots = items.map(s => ({
    id: s.id,
    runId: s.runId,
    isDefault: s.isDefault,
    createdAt: s.createdAt,
    completedAt: s.completedAt,
    objectCount: s.counters?.objectCount,
    linkCount: s.counters?.linkCount,
    inputs: (s.inputs?.inputs || []).map(i => `${i.materializedDir}(${i.kind})`).join(', '),
    inputCount: (s.inputs?.inputs || []).length,
    generation: s.inputs?.generation,
    typeCounts: (() => {
      const tc = s.stats?.typeCounts || {};
      const out = {};
      for (const t of TYPES) out[t] = tc[t] ?? 0;
      return out;
    })(),
  }));

  // 按完成时间正序排列（旧→新）
  snapshots.sort((a, b) => new Date(a.completedAt) - new Date(b.completedAt));

  const fs = await import('node:fs');
  fs.writeFileSync('d:/dev-src/Ai-Fast/ontology-test/snapshots-extracted.json',
    JSON.stringify({ httpStatus, code: j.code, total: j.data.total, count: snapshots.length, snapshots }, null, 2),
    'utf8');
  console.error('已写入 snapshots-extracted.json');

  // 简要输出供控制台核对
  for (const s of snapshots) {
    const typesSum = Object.values(s.typeCounts).reduce((a, b) => a + b, 0);
    console.error(`  [${s.completedAt}] obj=${s.objectCount} link=${s.linkCount} typesSum=${typesSum} inputs=[${s.inputs}]`);
  }
  console.log(JSON.stringify({ ok: true, count: snapshots.length }));
}

main().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
