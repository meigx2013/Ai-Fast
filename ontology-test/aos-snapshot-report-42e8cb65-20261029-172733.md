# AOS 技术本体快照历史数据对比分析报告

- **生成时间**：2026-10-29T09:27:33.027Z
- **API 接口**：`https://asdm-dt01.leansoftx.com/api/aos/contexts/42e8cb65-453c-4ec5-8485-617d4a5fbb53/snapshots?page=1&pageSize=36&status=available`
- **鉴权方式**：`POST /api/auth/login` 获取 JWT → `Authorization: Bearer {jwt}`
- **快照数量**：共 2 个（available 状态，已全量拉取）

---

## 一、API 调用自验证结果

| 验证项 | 结果 |
|---|---|
| 登录接口 | ✅ 成功获取 JWT |
| 快照列表接口 | ✅ HTTP 200，业务码 code=0 |
| 分页与完整性 | ✅ total=2，实际获取 2 个，无遗漏 |
| 计数自洽性 | ✅ 各快照 13 类明细之和均等于 objectCount |

---

## 二、快照列表及核心数据

| # | 快照 ID | completedAt | objectCount | linkCount | 输入 | 默认 |
|---|---|---|---:|---:|---|---|
| 1 | `ed85599d-aae2-47df-a965-1a14da4bdbd3` | 2026-10-19T17:07:17.975Z | 4,624 | 26,165 | RuoYi-Springboot源码(git-repo) | 否 |
| 2 | `e4c327a0-9ee0-4f2c-9ddd-15fb8c8664dd` | 2026-10-29T07:21:45.122Z | 4,944 | 31,860 | RuoYi-Springboot-code(git-repo) + RuoYi-db(ddl) | **是** |

---

## 三、linkCount 明细对比（最新两代：`ed85599d` → `e4c327a0`）

| 类型 | 快照1（2026-10-19） | 快照2（2026-10-29） | 增量 Δ |
|---|---:|---:|---:|
| Class | 314 | 314 | 0 |
| Route | 21 | 21 | 0 |
| Table | 53 | 72 | +19 |
| Mapper | 23 | 23 | 0 |
| Method | 2,470 | 2,470 | 0 |
| Module | 217 | 215 | -2 |
| Package | 135 | 135 | 0 |
| Function | 1,002 | 1,306 | +304 |
| Component | 57 | 57 | 0 |
| Interface | 80 | 80 | 0 |
| Dependency | 73 | 73 | 0 |
| Repository | 1 | 2 | +1 |
| ApiEndpoint | 178 | 176 | -2 |
| **合计** | **4,624** | **4,944** | **+320** |

---

## 四、核心指标变化分析

| 指标 | 快照1 | 快照2 | 增量 | 增幅 |
|---|---:|---:|---:|---:|
| objectCount（对象总数） | 4,624 | 4,944 | +320 | +6.92% |
| linkCount（链接总数） | 26,165 | 31,860 | +5,695 | +21.77% |
| 链接密度（link ÷ object） | 5.66 | 6.44 | 0.79 | +13.88% |
| violationCount（违规数） | 0 | 0 | 0 | - |

**发生变化的类型**：Table: 53→72（+19，+35.85%）；Module: 217→215（-2，-0.92%）；Function: 1002→1306（+304，+30.34%）；Repository: 1→2（+1，+100.00%）；ApiEndpoint: 178→176（-2，-1.12%）

**结论**：对象数 增长 320（+6.92%），链接数 增长 5,695（+21.77%）。链接增速高于对象增速，对象间关联密度提升。无本体违规，数据质量稳定。

---

## 五、数据质量异常提示

- ⚠️ 快照 `ed85599d`: completedAt 与 createdAt 恰差 8 小时（疑似 UTC+8/UTC 时区写入不一致）
- ⚠️ 快照 `e4c327a0`: completedAt 早于 createdAt 199ms（时间戳异常）

