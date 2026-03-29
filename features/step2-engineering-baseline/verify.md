# 验证报告

> AI 执行版模板 — 验证报告
> 对应小白版：acceptance.md

---

## 基本信息

- **feature-id**: `step2-engineering-baseline`
- **验证日期**: 待填写
- **验证轮次**: 第 1 轮
- **验证状态**: 待执行

---

## required_checks 执行结果

| 检查项 | 命令 | 结果 | 证据文件 |
|--------|------|------|----------|
| verify-feature-structure | `ls features/step2-engineering-baseline/` | 待执行 | `evidence/structure-check.txt` |
| verify-feature-json | `cat features/step2-engineering-baseline/feature.json` | 待执行 | `evidence/feature-json-check.txt` |
| verify-documents-exist | `ls -la features/step2-engineering-baseline/*.md` | 待执行 | `evidence/documents-check.txt` |

---

## 双文档一致性检查

| 检查项 | 结果 | 说明 |
|--------|------|------|
| goal.md ↔ spec.md 目标范围一致 | 待检查 | |
| steps.md ↔ tasks.md 步骤对应 | 待检查 | |
| acceptance.md ↔ verify.md 标准对应 | 待检查 | |

---

## 失败项分析

（如有失败，列出每项失败原因和修复方案）

- （暂无，待执行后填写）

---

## 验证结论

- **最终状态**: 待验证
- **block 原因**: 无（待验证后更新）
- **证据链**: `features/step2-engineering-baseline/evidence/` 目录
