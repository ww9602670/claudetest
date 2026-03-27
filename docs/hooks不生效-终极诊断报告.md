# Hooks 不生效 — 终极诊断报告

## 最终结论（2026-03-28 已解决）

**根因确认：Claude Code v2.1.85 不从项目级 `.claude/settings.json` 加载 hooks，仅从用户级 `~/.claude/settings.json` 加载。**

将 hooks 配置迁移到 `C:\Users\Administrator\.claude\settings.json`（用户级）后，hooks 立即生效。gate-write.js 和 gate-bash.js 均已在真实 Claude Code 会话中验证通过。

---

## 问题排查历程

### 第一阶段：脚本层面排查（全部通过）

| 排查项 | 结果 | 证据 |
|--------|------|------|
| gate-write.js 语法错误 | ✅ 已修复 | `node -c` 通过 |
| gate-write.js 逻辑 Bug | ✅ 已修复 | 10/10 命令行测试全部通过 |
| gate-write.js 控制流穿透 | ✅ 已修复 | process.exitCode + return 重写 |
| gate-write.js fail-open | ✅ 已改为 fail-closed | 异常时 exit 2 |
| 工作目录不对 | ✅ 已确认 | claude_worke 会话 CWD 正确为 H:\claude_worke |
| settings.json 格式错误 | ✅ 已验证 | JSON 合法，结构符合文档 |
| settings.local.json | ✅ 已尝试 | 创建后 hook 仍未被调用 |
| 极简 test-hook.js（只写日志） | ✅ 已尝试 | hook-fired.txt 未产生 |
| 单一 matcher "Edit" | ✅ 已尝试 | 结果相同 |
| Node.js 可用性 | ✅ 正常 | 手动 node 执行一切正常 |

**结论**：脚本本身没有问题，Claude Code 根本没有调用它们。

### 第二阶段：环境/配置层面排查

| 排查项 | 结果 | 证据 |
|--------|------|------|
| 假设1: 项目 hooks 需用户批准 | ❌ 排除 | 全新终端启动，无任何批准提示出现 |
| **假设2: hooks 仅从用户级 settings 加载** | ✅ **确认为根因** | 迁移到用户级后 hooks 立即生效 |
| 假设3: Windows 特定 Bug | ❌ 排除 | 用户级 hooks 在 Windows 上正常工作 |
| 假设4: JSON 格式不符 | ❌ 排除 | 相同格式在用户级下直接生效 |

---

## 根因详解

### Claude Code hooks 配置加载规则（实测结论）

| 配置文件位置 | hooks 是否被加载 | 实测结果 |
|-------------|-----------------|---------|
| `项目/.claude/settings.json` | ❌ **不加载** | hooks 被静默忽略，无任何警告 |
| `项目/.claude/settings.local.json` | ❌ **不加载** | hooks 被静默忽略 |
| `~/.claude/settings.json`（用户级） | ✅ **加载** | hooks 正常执行 |

> **重要发现**：项目级 settings.json 中的 `permissions` 等其他字段可能被读取，但 `hooks` 字段被忽略。这可能是 Claude Code 出于安全考虑的设计（防止恶意项目通过 hooks 执行任意代码），也可能是 v2.1.85 的限制。

### 启动方式

之前通过自定义 `cc` 脚本启动，可能引入了额外的环境问题。验证时改用直接调用：

```powershell
$env:ANTHROPIC_API_KEY = "<api-key>"
cd H:\claude_worke
& "H:\claudecode\node_modules\.bin\claude.cmd"
```

---

## 修复方案（已执行）

将 hooks 配置写入用户级 `C:\Users\Administrator\.claude\settings.json`，使用绝对路径指向脚本：

```json
{
  "permissions": {
    "allow": ["Bash(*)", "Write(*)", "Read(*)", "Glob(*)", "Grep(*)"],
    "deny": []
  },
  "skipDangerousModePermissionPrompt": true,
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          { "type": "command", "command": "node H:/claude_worke/.claude/hooks/gate-write.js" }
        ]
      },
      {
        "matcher": "MultiEdit",
        "hooks": [
          { "type": "command", "command": "node H:/claude_worke/.claude/hooks/gate-write.js" }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          { "type": "command", "command": "node H:/claude_worke/.claude/hooks/gate-write.js" }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "node H:/claude_worke/.claude/hooks/gate-bash.js" }
        ]
      }
    ]
  }
}
```

---

## 实测验证记录（2026-03-28）

### 验证1: test-hook.js 触发测试

在用户级 settings.json 配置 test-hook.js（仅写日志）后，Claude Code 会话中执行 Edit 操作：

- **结果**：`hook-fired.txt` 成功生成，记录了 2 次触发
- **结论**：hooks 机制在用户级配置下正常工作

### 验证2: gate-write.js 拦截测试

feature.json status=draft（不属于 active 状态），尝试写入 `src/test.js`：

- **hook 输入**：tool_name=Write, file_path=H:\claude_worke\src\test.js
- **hook 处理**：relPath=src/test.js → 非豁免路径 → 查找活跃 feature → activeFeature=null
- **结果**：**exit 2 拦截成功** ✅
- **日志证据**：`BLOCK: no active feature`

### 验证3: gate-write.js 豁免路径测试

尝试写入 `docs/test.md`：

- **hook 输入**：tool_name=Write, file_path=H:\claude_worke\docs\test.md
- **hook 处理**：relPath=docs/test.md → 命中豁免前缀 `docs/`
- **结果**：**exit 0 放行成功** ✅
- **日志证据**：`ALLOW: exempt path`

### 验证4: gate-bash.js 黑名单模式（status=implementing）

通过模拟 Claude Code stdin JSON 输入直接测试 gate-bash.js：

| 命令 | 预期 | 结果 | 退出码 |
|------|------|------|--------|
| `git push --force origin main` | 拦截 | `[gate-bash] 高危命令被拦截` | 2 ✅ |
| `git status` | 放行 | （无输出） | 0 ✅ |
| `rm -rf /` | 拦截 | `[gate-bash] 高危命令被拦截` | 2 ✅ |
| `DROP TABLE users;` | 拦截 | `[gate-bash] 高危命令被拦截` | 2 ✅ |

### 验证5: gate-write.js allowed_paths 精确匹配（status=implementing）

| 目标路径 | 预期 | 结果 | 退出码 |
|----------|------|------|--------|
| `src/auth/login.js`（在 allowed_paths 中） | 放行 | `ALLOW: all checks passed` | 0 ✅ |
| `src/core/engine.js`（在 forbidden_paths 中） | 拦截 | `不在 allowed_paths 列表中` | 2 ✅ |
| `src/other/util.js`（不在任何列表中） | 拦截 | `不在 allowed_paths 列表中` | 2 ✅ |
| `docs/test.md`（豁免路径） | 放行 | `ALLOW: exempt path` | 0 ✅ |

> **注意**：`src/core/engine.js` 虽在 forbidden_paths 中，但实际先被 allowed_paths 检查拦截（因为不在 allowed_paths 中）。forbidden_paths 逻辑是在 allowed_paths 通过之后的二次过滤。

### 验证6: gate-bash.js 白名单模式（status=verifying）

verifying 状态下 gate-bash 切换为白名单模式，只允许 required_checks 中的命令：

| 命令 | 预期 | 结果 | 退出码 |
|------|------|------|--------|
| `npm run lint`（在 required_checks 中） | 放行 | （无输出） | 0 ✅ |
| `npm test -- --testPathPattern=auth`（在 required_checks 中） | 放行 | （无输出） | 0 ✅ |
| `ls -la`（不在白名单中） | 拦截 | `不在 required_checks 白名单中` | 2 ✅ |
| `git status`（不在白名单中） | 拦截 | `不在 required_checks 白名单中` | 2 ✅ |
| `git push --force origin main`（不在白名单中） | 拦截 | `不在 required_checks 白名单中` | 2 ✅ |

### 验证7: gate-write.js 在 verifying 状态下的行为

| 目标路径 | 预期 | 结果 | 退出码 |
|----------|------|------|--------|
| `src/auth/login.js`（allowed_paths 内） | 放行 | exit 0 | 0 ✅ |
| `src/core/engine.js`（不在 allowed_paths） | 拦截 | `不在 allowed_paths 列表中` | 2 ✅ |

---

## 人工验收 5 重点 — 最终结论

| # | 验收项 | 状态 | 验证方式 | 证据 |
|---|--------|------|----------|------|
| 1 | gate-write 拦截效果 | ✅ **通过** | Claude 真实会话 + 模拟 stdin | debug log 铁证 |
| 2 | gate-write 豁免放行 | ✅ **通过** | Claude 真实会话 + 模拟 stdin | debug log 铁证 |
| 3 | gate-bash 高危拦截 | ✅ **通过** | 模拟 stdin（4 条高危命令全拦截） | exit 2 + stderr 输出 |
| 4 | allowed_paths 精确匹配 | ✅ **通过** | 模拟 stdin（4 种路径全部正确） | exit code 0/2 |
| 5 | 端到端工作流 | ✅ **通过** | implementing + verifying 两种状态全覆盖 | 7 项子测试全通过 |

### 独立验证（用户在全新终端执行自动化脚本）

2026-03-28 用户在全新 PowerShell 终端中运行 `verify-hooks.ps1` 自动化验证脚本，**15/15 全部通过**：

```
============================================================
  Hooks Verification (5 groups, 15 tests)
============================================================

--- 1: gate-write block (status=done, no active feature) ---
  [1a] Write src/test.js (no active feature)        exitcode: 2  =>  PASS
  [1b] Edit src/app.js (no active feature)           exitcode: 2  =>  PASS

--- 2: gate-write exempt paths (should always allow) ---
  [2a] Write docs/test.md (exempt)                   exitcode: 0  =>  PASS
  [2b] Write .claude/config.json (exempt)            exitcode: 0  =>  PASS
  [2c] Write features/test/note.md (exempt)          exitcode: 0  =>  PASS

--- 3: gate-bash dangerous commands (status=implementing, blacklist) ---
  [3a] git push --force (dangerous)                  exitcode: 2  =>  PASS
  [3b] rm -rf / (dangerous)                          exitcode: 2  =>  PASS
  [3c] DROP TABLE (dangerous)                        exitcode: 2  =>  PASS
  [3d] git status (safe)                             exitcode: 0  =>  PASS

--- 4: allowed_paths matching (status=implementing) ---
  [4a] src/auth/login.js (in allowed_paths)          exitcode: 0  =>  PASS
  [4b] src/core/engine.js (in forbidden_paths)       exitcode: 2  =>  PASS
  [4c] src/other/util.js (not in any list)           exitcode: 2  =>  PASS

--- 5: verifying status (whitelist mode) ---
  [5a] npm run lint (in required_checks)             exitcode: 0  =>  PASS
  [5b] ls -la (not in required_checks)               exitcode: 2  =>  PASS
  [5c] src/auth/login.js (verifying + allowed)       exitcode: 0  =>  PASS

  Total: 15  |  Pass: 15  |  Fail: 0
  ALL PASSED - hooks verification complete
```

### 补充说明

- **验证方式说明**：由于 CLAUDE.md 中的 AI 指令层（"approved 之前禁止写入业务代码"）比 hooks 更早介入，导致 Claude 在真实会话中自行拒绝操作而不触发工具调用。因此第 3-5 项改用模拟 Claude Code stdin JSON 输入的方式直接测试 hook 脚本，与真实调用等价（输入格式完全一致）。
- **双层防护确认**：治理体系实际拥有两层防护——(1) CLAUDE.md AI 自律层；(2) hooks 系统强制层。两层独立工作，即使 AI 不遵守指令，hooks 仍能在工具调用时强制拦截。
- **hooks 真实触发已验证**：验证 1-3 通过真实 Claude Code 会话确认了 hooks 机制在用户级配置下的实际触发（hook-fired.txt 生成 + gate-write-debug.log 记录）。
- **自动化脚本可复用**：`verify-hooks.ps1` 可在任何时候重新运行，用于回归验证。

---

## 踩坑记录

### 坑1: Claude Code 不加载项目级 hooks

项目级 `.claude/settings.json` 中的 `hooks` 字段被静默忽略，必须放在用户级 `~/.claude/settings.json` 中。无任何错误提示。

### 坑2: PowerShell 5.x UTF-8 BOM 问题

Windows PowerShell 5.x 的 `Set-Content -Encoding UTF8` 会自动添加 BOM（`EF BB BF` 三字节前缀），导致 Node.js 的 `JSON.parse()` 解析失败。

- **症状**：`findActiveFeatureJson()` 返回 null，所有依赖 feature 状态的检查退化为"无活跃 feature"
- **首次验证**：15 项中 3 项 FAIL（4a、5b、5c），全部因 BOM 导致 feature.json 解析失败
- **修复**：改用 `[System.IO.File]::WriteAllText()` + `UTF8Encoding($false)` 写入无 BOM 文件
- **教训**：Windows 环境中任何工具链写入 JSON 文件后，务必检查是否带 BOM

### 坑3: 验证脚本移至子目录后 process.cwd() 路径漂移（2026-03-28）

将 `verify-hooks.ps1` 从项目根移到 `tests/` 目录后，从 `tests/` 运行时 `node` 继承了 `H:\claude_worke\tests` 作为 CWD，导致 gate-write.js 和 gate-bash.js 内的 `process.cwd()` 返回错误路径。

**gate-write.js 影响**：
- `normalizedCwd` = `/claude_worke/tests`
- 传入路径如 `H:/claude_worke/docs/test.md` → `normalizedAbs` = `/claude_worke/docs/test.md`
- 剥离 CWD 前缀失败（不以 `/claude_worke/tests/` 开头），`relPath` 保留完整路径
- 豁免前缀 `docs/` 无法匹配 `/claude_worke/docs/...`，导致 2a/2b/2c/4a/5c 全部误判为业务路径

**gate-bash.js 影响**：
- `findActiveFeatureJson(process.cwd())` 在 `tests/` 下找不到 `features/` 目录，返回 null
- verifying 状态下退化为黑名单模式，`ls -la` 不在黑名单，5b 放行（期望拦截）

**修复**：两个脚本均改为从 `__dirname` 推算项目根，不再依赖 `process.cwd()`：
```js
const PROJECT_ROOT = path.resolve(__dirname, '..', '..'); // .claude/hooks/ → 上两级 = 项目根
```
- gate-write.js：将 `const cwd = process.cwd()` 改为 `const cwd = PROJECT_ROOT`
- gate-bash.js：将 `findActiveFeatureJson(process.cwd())` 改为 `findActiveFeatureJson(PROJECT_ROOT)`

**教训**：hook 脚本不能假设调用者的工作目录，应使用 `__dirname` 定位自身位置来推算项目根。

---

## 当前文件状态

| 文件 | 状态 |
|------|------|
| `.claude/hooks/gate-write.js` | ✅ 生产就绪，debugLog 已移除 |
| `.claude/hooks/gate-bash.js` | ✅ 生产就绪 |
| `.claude/hooks/test-hook.js` | 🗑️ 调试用，可删除 |
| `.claude/settings.json`（项目级） | ✅ 已清理，无效 hooks 配置已移除 |
| `.claude/settings.local.json`（项目级） | ✅ 已清理，无效 hooks 配置已移除 |
| `~/.claude/settings.json`（用户级） | ✅ 正式 hooks 配置，已生效 |
| `features/example-login/feature.json` | status=done（已恢复） |
| `tests/verify-hooks.ps1` | ✅ 已移至 tests/ 目录，可用于回归测试 |

### 待清理

1. 删除 `.claude/hooks/test-hook.js`（调试用）
2. 删除 `gate-write-debug.log`（如存在）
~~3. 考虑移除 gate-write.js 中的 debugLog 调试代码（生产环境不需要）~~ ✅ 已完成（2026-03-28）
~~4. 考虑清理项目级 settings.json / settings.local.json 中无效的 hooks 配置（避免误导）~~ ✅ 已完成（2026-03-28）
~~5. `verify-hooks.ps1` 保留作为回归测试工具，或移至 `tests/` 目录~~ ✅ 已移至 tests/（2026-03-28）
