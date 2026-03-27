---
name: verify
description: 验收检查：运行 required_checks，检查双文档一致性，生成 verify.md
disable-model-invocation: true
---

# /verify — 验收检查

⚠️ **高风险操作，需人工触发，AI 不得自动调用**

## 用法

```
/verify <feature-id>
```

## 前置条件

- `feature.json` 的 `status` 为 `implementing`（所有任务已完成）
- tasks.md 中所有任务均已标记 ✅

## 执行步骤

1. 将 `feature.json` 的 `status` 更新为 `verifying`
2. 执行 `required_checks` 中的所有命令（使用 `command_windows` 字段）
3. 将结果保存到 `evidence/<timestamp>-check-results.txt`
4. 检查双文档一致性：
   - goal.md ↔ spec.md
   - steps.md ↔ tasks.md
   - acceptance.md ↔ verify.md
5. 生成 `verify.md`，引用 evidence/ 中的具体文件
6. 如检查通过：将 `status` 更新为 `done`
7. 如检查失败：记录失败项，在 `max_fix_rounds` 内修复并重试
8. 超过 `max_fix_rounds`：将 `status` 设为 `blocked`，停止等待人工

## 禁止事项

- verifying 状态下禁止执行 required_checks 白名单以外的命令
- 禁止自动进入下一个功能的实现
- 禁止把验证结果写入 auto memory 作为治理依据
