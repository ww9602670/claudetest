---
name: implement
description: 逐步实现：按 tasks.md 逐条执行，须 approved 状态
disable-model-invocation: true
---

# /implement — 逐步实现

⚠️ **高风险操作，需人工触发，AI 不得自动调用**

## 用法

```
/implement <feature-id> [task-id]
```

## 前置条件（必须全部满足）

1. `feature.json` 存在且 `status` 为 `approved` 或 `implementing`
2. `approved_by`、`approved_at`、`phase_gate_approved` 均已填写
3. `spec.md`、`design.md`、`tasks.md` 均存在
4. 当前 Git 分支不是 main / master

## 执行步骤

1. 读取 `tasks.md`，找到第一个未完成（无 ✅）的任务
2. 将 `feature.json` 的 `status` 更新为 `implementing`
3. 执行该任务对应的代码修改（仅限 `allowed_paths`）
4. 完成后在 tasks.md 对应任务行标记 ✅
5. 输出本任务执行摘要，等待人工确认再继续下一条

## 禁止事项

- 禁止一次性执行所有任务（必须逐条）
- 禁止修改 `forbidden_paths` 内的文件
- 禁止修改 `allowed_paths` 范围外的文件
- 禁止自动推进到 verify 阶段
