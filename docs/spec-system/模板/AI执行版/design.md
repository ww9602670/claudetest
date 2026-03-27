# 技术设计

> AI 执行版模板 — 技术设计
> 对应小白版：plan.md

---

## 设计概述

（描述整体技术方案，1-3 句话）

---

## 架构决策

### 方案选择

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 方案 A | | | 选用 / 放弃 |
| 方案 B | | | 选用 / 放弃 |

**选用方案**：（说明选用原因）

---

## 数据模型变更

（如需修改数据库，列出变更）

```sql
-- 示例
ALTER TABLE users ADD COLUMN remember_token VARCHAR(64);
```

---

## API 设计

（如需新增或修改 API）

```
POST /api/auth/login
Request: { email: string, password: string, remember: boolean }
Response: { token: string, expires_at: string }
```

---

## 文件变更清单

| 路径 | 操作 | 说明 |
|------|------|------|
| `src/（路径）` | 新增 | （说明） |
| `src/（路径）` | 修改 | （说明） |

---

## 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| （描述） | 高/中/低 | 高/中/低 | （措施） |
