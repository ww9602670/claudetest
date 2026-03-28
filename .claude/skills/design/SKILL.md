---
name: design
description: 技术设计：同步生成小白版 plan.md 和 AI 执行版 design.md
argument-hint: "<feature-id>"
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
paths:
  - "features/**/plan.md"
  - "features/**/design.md"
---

# /design — 技术设计

## 用法

```
/design <feature-id>
```

## 前置条件

- `features/<feature-id>/spec.md` 必须存在
- `features/<feature-id>/feature.json` 的 `status` 须为 `review` 或 `approved`

## 执行步骤

1. 读取 `spec.md` 和 `goal.md`
2. 在 `features/<feature-id>/` 下创建（或更新）：
   - `plan.md`（小白版方案翻译，非技术语言）
   - `design.md`（AI 执行版技术设计）
3. 两份文档必须保持一致：技术方案与非技术描述一一对应

4. 完成后输出：
   - 文件路径列表
   - 提示用户确认后才能运行 `/tasks`

## 禁止事项

- 禁止在此阶段修改任何业务代码
- 禁止自动推进到 tasks 阶段
