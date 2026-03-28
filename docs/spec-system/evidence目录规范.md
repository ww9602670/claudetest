# Evidence 目录规范

本文档定义 `features/<feature-id>/evidence/` 目录下的标准文件结构和命名规则。

---

## 标准文件

每个 feature 的 evidence 目录下应包含以下文件（由 hook 或手动产出）：

| 文件 | 生成方式 | 内容 |
|------|----------|------|
| `change-summary.md` | `evidence-write.js` (PostToolUse) 自动追加 | 每次 Edit/MultiEdit/Write 操作的时间戳、工具名、目标文件路径 |
| `checks.md` | `evidence-bash.js` (PostToolUse) 自动追加 | 每次 Bash 命令执行的时间戳、命令内容 |
| `iteration-log.md` | `/verify` skill 执行时手动生成 | 修复轮次记录：轮次号、失败项、修复动作、重试结果 |
| `<YYYYMMDD>-<HHMMSS>-check-results.txt` | `/verify` skill 执行时生成 | required_checks 的完整命令输出快照 |

---

## 自动记录触发条件

PostToolUse hooks 仅在以下条件下触发记录：

- feature 处于 `implementing` 或 `verifying` 状态
- 不在上述状态时，hook 静默退出，不产生文件

---

## 文件格式

### change-summary.md

```markdown
# 变更摘要记录

由 PostToolUse(evidence-write) 自动生成。

---

- **2026-03-28T14-30-00** | `Edit` | `src/auth/login.controller.js`
- **2026-03-28T14-32-15** | `Write` | `src/auth/auth.service.js`
```

### checks.md

```markdown
# 命令执行记录

由 PostToolUse(evidence-bash) 自动生成。

---

- **2026-03-28T14-35-00** | `npm run lint`
- **2026-03-28T14-36-12** | `npm test -- --testPathPattern=auth`
```

### iteration-log.md

```markdown
# 修复迭代记录

## 轮次 1

- 失败项：lint（2 个 ESLint 错误）
- 修复动作：修正 src/auth/auth.service.js 第 15、28 行
- 重试结果：lint 通过

## 轮次 2

- 无失败项
- 最终结果：全部通过
```

---

## 目录结构示例

```
features/example-login/evidence/
├── change-summary.md          ← PostToolUse 自动追加
├── checks.md                  ← PostToolUse 自动追加
├── iteration-log.md           ← /verify 手动生成
└── 20260328-100000-check-results.txt  ← /verify 生成
```

---

## 禁止事项

- 不允许在 evidence 目录下存放业务代码
- 不允许手动伪造 PostToolUse 自动记录（change-summary.md / checks.md 由 hook 自动管理）
- iteration-log.md 由 /verify skill 管理，不由 hook 自动生成

---

## 本规范适用范围

从阶段 03 起生效。阶段 01-02 已有的占位 evidence（如 example-login 的 `20260328-100000-check-results.txt`）不追溯适用本规范。
