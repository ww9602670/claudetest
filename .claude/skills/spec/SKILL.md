---
name: spec
description: 需求分析：同步生成小白版 goal.md 和 AI 执行版 spec.md
argument-hint: "<feature-id> <需求描述>"
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
paths:
  - "features/**/goal.md"
  - "features/**/spec.md"
  - "features/**/feature.json"
---

# /spec — 需求分析

## 用法

```
/spec <feature-id> <需求描述>
```

## 执行步骤

1. 在 `features/<feature-id>/` 目录下创建（或更新）以下文件：
   - `goal.md`（小白版目标说明）
   - `spec.md`（AI 执行版需求规格）
   - `feature.json`（初始化状态为 `draft`）

2. 两份文档必须同步：目标范围、允许/禁止边界、成功标准保持一致

3. 完成后输出：
   - 文件路径列表
   - 提示用户确认后才能运行 `/design`

## 禁止事项

- 禁止在此阶段修改任何业务代码
- 禁止自动推进到 design 阶段
- status 保持 `draft`，等待人工 review
