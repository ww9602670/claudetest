# Hooks 验证方案：已加载 / 已注册 / 已触发

本文档为第一阶段正式验证说明，让后续审查不再依赖会话口头解释。

---

## 三个验证维度

| 维度 | 含义 | 验证方式 |
|------|------|----------|
| 已加载 | hook 脚本文件存在且语法合法 | 文件存在性检查 + Node.js 语法校验 |
| 已注册 | hook 脚本已在运行时配置中注册 | 检查 `~/.claude/settings.json` 中的 hooks 配置 |
| 已触发 | hook 在实际工具调用时被执行并产生预期行为 | 运行 `tests/verify-hooks.ps1` 端到端验证 |

---

## 1. 已加载（文件存在性与语法合法性）

### 验证步骤

```powershell
# 检查文件存在
Test-Path "H:\claude_worke\.claude\hooks\gate-write.js"
Test-Path "H:\claude_worke\.claude\hooks\gate-bash.js"

# 检查语法合法性（无语法错误即可）
node --check "H:\claude_worke\.claude\hooks\gate-write.js"
node --check "H:\claude_worke\.claude\hooks\gate-bash.js"
```

### 预期结果

- 两个文件均存在（返回 `True`）
- 两次 `node --check` 均无输出、退出码为 0

---

## 2. 已注册（运行时配置中已声明）

### 说明

hooks 的运行时加载位置为**用户级** `~/.claude/settings.json`，不是项目级 `.claude/settings.json`。
项目级配置文件仅用于项目权限配置，不承担 hooks 注册职责。

### 验证步骤

```powershell
# 读取用户级配置
$settings = Get-Content "$env:USERPROFILE\.claude\settings.json" | ConvertFrom-Json

# 检查是否存在 hooks 配置节
$settings.hooks | ConvertTo-Json -Depth 5
```

### 预期结果

输出中应包含：
- `gate-write.js` 被配置在 `PreToolUse` 事件上（拦截 Write / Edit 工具调用）
- `gate-bash.js` 被配置在 `PreToolUse` 事件上（拦截 Bash 工具调用）

### 注册口径

> hooks 的注册位置为用户级配置。项目文档中对此件事的描述统一为"环境接入条件"，
> 不得混写为"项目级注册"。

---

## 3. 已触发（端到端行为验证）

### 验证步骤

```powershell
cd H:\claude_worke
.\tests\verify-hooks.ps1
```

### 预期结果

- 18/18 测试全部 PASS
- 覆盖以下场景：
  - 组 1：无活跃 feature 时 gate-write 拦截写入（2 例）
  - 组 2：豁免路径始终允许（3 例）
  - 组 3：危险命令黑名单拦截（4 例）
  - 组 4：implementing 状态下 allowed_paths 匹配（3 例）
  - 组 5：verifying 状态下白名单模式（3 例）
  - 组 6：命令拼接绕过防护（3 例）

---

## 4. PostToolUse 证据沉淀 hooks（阶段 03 新增）

### 文件清单

| 文件 | 事件 | 作用 |
|------|------|------|
| `.claude/hooks/evidence-write.js` | PostToolUse(Edit\|MultiEdit\|Write) | 追加记录到 `evidence/change-summary.md` |
| `.claude/hooks/evidence-bash.js` | PostToolUse(Bash) | 追加记录到 `evidence/checks.md` |

### 已加载验证

```powershell
node --check ".claude\hooks\evidence-write.js"
node --check ".claude\hooks\evidence-bash.js"
```

预期：无输出、退出码 0。

### 已注册验证

在 `~/.claude/settings.json` 的 hooks 配置中应包含：
- `evidence-write.js` 注册在 `PostToolUse` 事件上
- `evidence-bash.js` 注册在 `PostToolUse` 事件上

### 已触发验证

PostToolUse hooks 为非拦截型（仅记录），验证方式：
1. 确保某个 feature 处于 `implementing` 或 `verifying` 状态
2. 执行一次 Edit/Write 或 Bash 操作
3. 检查 `features/<feature-id>/evidence/change-summary.md` 或 `checks.md` 是否出现新记录

> PostToolUse hooks 不在 `verify-hooks.ps1` 的 18 项测试范围内（该脚本仅覆盖 PreToolUse 门禁），
> 以上手动步骤即为 PostToolUse 的"已触发"验证。

---

## 快速一次性验证

将以下步骤合并执行，即可完成全部验证：

```powershell
# 1. 已加载（全部 4 个 hook）
node --check ".claude\hooks\gate-write.js"
node --check ".claude\hooks\gate-bash.js"
node --check ".claude\hooks\evidence-write.js"
node --check ".claude\hooks\evidence-bash.js"

# 2. 已注册
(Get-Content "$env:USERPROFILE\.claude\settings.json" | ConvertFrom-Json).hooks | ConvertTo-Json -Depth 5

# 3. 已触发（PreToolUse 门禁）
.\tests\verify-hooks.ps1

# 4. 已触发（PostToolUse 证据沉淀）— 手动检查 evidence 目录
```

全部通过即表示当前环境的 hooks 治理体系处于可用状态。

---

## 适用范围

本方案覆盖阶段 01-03 的全部 hooks：
- PreToolUse 门禁：`gate-write.js`、`gate-bash.js`（阶段 01 引入）
- PostToolUse 证据沉淀：`evidence-write.js`、`evidence-bash.js`（阶段 03 引入）

本阶段不引入：
- 自动化 CI 集成
- Stop / SubagentStop 类 hook
