---
paths:
  - "features/**"
---

# 验证循环规则

## 修复轮次限制

- `max_fix_rounds` 字段定义最大自动修复轮次（默认 3）
- 达到上限后必须停止，标记 `status: blocked`，等待人工介入
- 每轮修复后必须更新 `fix_round_current` 计数

## 停止条件

以下任一条件满足时，立即停止验证循环：

1. 所有 `required_checks` 均通过
2. 达到 `max_fix_rounds` 上限
3. 出现无法自动修复的错误类型
4. `status` 被设置为 `blocked`

## Bash 双层策略

**verifying 状态（白名单模式）**：
- 只允许执行 `required_checks` 中列出的命令
- 其他所有 Bash 命令被拦截

**其他状态（黑名单模式）**：
- 拦截高危命令：`rm -rf`、`git push --force`、`git reset --hard`、`DROP TABLE`、`> /dev/null 2>&1` 等
- 允许常规开发命令

## 证据链要求

每次验证必须在 `evidence/` 目录下保存：

- `<timestamp>-check-results.txt` — 检查命令输出
- `<timestamp>-summary.md` — 本轮验证摘要（通过/失败/修复项）

verify.md 必须引用 evidence/ 中的具体文件作为证据。

---

## 执行层级标注

| 约束项 | 层级 | 执行机制 |
|--------|------|----------|
| max_fix_rounds 轮次限制 | 生效层 | AI 自觉遵守 |
| 达到上限标记 blocked | 生效层 | AI 自觉遵守 |
| verifying 状态白名单模式 | 硬拦截层 | gate-bash.js 只允许 required_checks 命令 |
| 其他状态黑名单模式 | 硬拦截层 | gate-bash.js 拦截高危命令 |
| 证据链保存到 evidence/ | 生效层 | AI 自觉遵守 |

> **gate-bash.js 失败策略**：fail-open（异常时放行）。
> **设计理由**：对 Bash 采用 fail-closed 会导致 JSON 解析异常时所有命令被误拦，严重影响基本开发体验。这是安全性与可用性的折中。gate-write.js 采用 fail-closed 是因为写入操作的风险更高，宁可误拦也不放行。
