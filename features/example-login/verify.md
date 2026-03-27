# 验证报告 — 用户登录

> AI 执行版 | feature-id: example-login

---

## 基本信息

- **feature-id**: `example-login`
- **验证日期**: 2026-03-28 10:00
- **验证轮次**: 第 1 轮（共允许 3 轮）
- **验证状态**: 通过

---

## required_checks 执行结果

| 检查项 | 命令 | 结果 | 证据文件 |
|--------|------|------|----------|
| lint | `npm run lint` | ✅ 通过 | `evidence/20260328-100000-check-results.txt` |
| test | `npm test -- --testPathPattern=auth` | ✅ 通过（5/5 用例） | `evidence/20260328-100000-check-results.txt` |

---

## 双文档一致性检查

| 检查项 | 结果 | 说明 |
|--------|------|------|
| goal.md ↔ spec.md 目标范围一致 | ✅ | 功能边界完全对应 |
| steps.md ↔ tasks.md 步骤对应 | ✅ | 6 步骤对应 6 任务 |
| acceptance.md ↔ verify.md 标准对应 | ✅ | AC-01~05 与验收项 1~5 对应 |

---

## 验证结论

- **最终状态**: done
- **证据链**: `evidence/20260328-100000-check-results.txt`

> ⚠️ 注意：这是虚拟示例，evidence/ 中的文件为占位符，实际项目中应包含真实命令输出。
