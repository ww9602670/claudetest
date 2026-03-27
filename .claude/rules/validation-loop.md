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
