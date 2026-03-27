---
paths:
  - "specs/**"
---

# Spec 工作流规则

当你在 specs/ 目录下工作时，遵守以下额外规则：

## 文档互锁

- 编写 `design.md` 前，同目录必须已存在 `spec.md`
- 编写 `tasks.md` 前，同目录必须已存在 `spec.md` 和 `design.md`
- 执行 Task 前，同目录必须已存在 `tasks.md`
- 编写 `verify.md` 前，`tasks.md` 中所有 Task 应已完成

## 变更同步

- 如果实现过程中发现 Spec 有问题，**先更新 spec.md**，在变更处添加 `> [变更记录] YYYY-MM-DD: 变更说明` 标注
- 如果实现与 Design 不一致，**先更新 design.md**，同样添加变更标注
- tasks.md 的修改只限于标记完成和追加完成记录，不要修改任务本身的描述

## 命名规范

- specs 下的功能目录名：英文、kebab-case、简洁（如 `user-login`，不是 `implement-user-login-feature`）
