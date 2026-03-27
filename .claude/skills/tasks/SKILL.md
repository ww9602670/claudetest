---
name: tasks
description: 任务拆解：同步生成小白版 steps.md 和 AI 执行版 tasks.md
disable-model-invocation: false
---

# /tasks — 任务拆解

## 用法

```
/tasks <feature-id>
```

## 前置条件

- `features/<feature-id>/spec.md` 必须存在
- `features/<feature-id>/design.md` 必须存在
- `feature.json` 的 `status` 须为 `approved`

## 执行步骤

1. 读取 `spec.md`、`design.md`、`goal.md`、`plan.md`
2. 在 `features/<feature-id>/` 下创建（或更新）：
   - `steps.md`（小白版可勾选步骤列表）
   - `tasks.md`（AI 执行版原子化任务清单）
3. 每个 task 必须：
   - 原子化（单一职责）
   - 可独立验证
   - 在 steps.md 有对应步骤

4. 完成后输出：
   - 文件路径列表
   - 任务数量摘要
   - 提示用户确认后才能运行 `/implement`

## 禁止事项

- 禁止在此阶段修改任何业务代码
- 禁止自动推进到 implement 阶段
