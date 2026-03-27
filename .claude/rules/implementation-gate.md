---
paths:
  - "features/**"
---

# 实现门禁规则

在 features/ 目录下执行任何 Edit / MultiEdit / Write 操作前，必须通过以下 14 项检查。

## 前置检查清单

在开始任何实现工作前，逐项确认：

1. [ ] `feature.json` 存在于当前功能目录
2. [ ] `status` 字段为 `approved` 或 `implementing`
3. [ ] `approved_by` 字段不为空
4. [ ] `approved_at` 字段存在且为有效时间戳
5. [ ] `phase_gate_approved` 为 `true`
6. [ ] `spec.md` 已存在
7. [ ] `design.md` 已存在
8. [ ] `tasks.md` 已存在
9. [ ] 当前修改路径在 `allowed_paths` 列表内
10. [ ] 当前修改路径不在 `forbidden_paths` 列表内
11. [ ] 本次修改对应 tasks.md 中某具体任务
12. [ ] 当前 Git 分支不是 main / master（应在功能分支）
13. [ ] 未超出 `max_fix_rounds` 限制（verifying 状态时）
14. [ ] 无未解决的 `blocked` 状态依赖

## 范围控制双落点

**allowed_paths**（白名单）：feature.json 中定义，实现只能触及列表内路径。

**forbidden_paths**（黑名单）：feature.json 中定义，列表内路径绝对禁止触及。

两者同时生效，任一不满足即终止操作。

## Git 分支要求

- 实现阶段必须在功能分支（非 main/master）
- 分支名建议格式：`feat/<feature-id>`
