# gate-write.js 修复报告（迭代记录）

## 迭代次数：1 次（一次通过）

---

## 故障原因分析

gate-write.js 存在 **两层 Bug**，第一层掩盖了第二层：

### Bug 1（已由 Sonnet 修复）：语法错误

第 34 行的正则表达式 `/\/g` 在 Sonnet 写入磁盘时反斜杠转义被破坏，导致 Node.js 在 `require` 阶段就抛出 `SyntaxError`，脚本完全无法加载。

**修复方式**：`p.replace(/\/g, '/')` → `p.split('\').join('/')`

### Bug 2（本次修复）：控制流穿透 + fail-open 兜底

语法修复后，逻辑层存在致命的控制流问题：

```javascript
// 旧代码
function block(msg) {
  process.stderr.write(msg + '\n');
  process.exit(2);    // ← 在 async 事件回调中不保证立即终止
}

if (!featureJson) {
  block('...');       // ← 调用后没有 return
}
const status = featureJson.status;  // ← 如果 exit 未立即生效 → null.status → TypeError
// → 被 catch (e) { allow(); } 捕获 → exit 0 → 放行！
```

**核心问题**：

1. `process.exit()` 在 Node.js 的 `stream.on('end')` 回调中行为不可靠：可能在当前 tick 结束前不会立即终止进程
2. 所有 `block()` / `allow()` 调用后没有 `return`，代码继续执行
3. catch-all 使用 `allow()`（fail-open），任何运行时异常都导致放行

**这就是为什么闸门时灵时不灵**——取决于 `process.exit()` 在事件循环中何时被处理。

---

## 修复内容

| 改动 | 旧 | 新 | 理由 |
|------|----|----|------|
| 退出方式 | `process.exit(N)` | `process.exitCode = N` | 设置退出码但不强制终止，让事件循环自然结束 |
| 控制流 | `block()` 后无 return | 每个 `block()/allow()` 后都有 `return` | 杜绝穿透执行 |
| 异常策略 | `catch(e) { allow() }` (fail-open) | `catch(e) { block() }` (fail-closed) | 异常时拒绝放行 |
| 默认退出码 | 无 | `process.exitCode = 2` 在 main 入口 | 即使脚本异常退出也是拦截 |
| 路径分隔符 | `split('\')` | `split(path.sep)` | 使用 Node.js 内置跨平台分隔符 |
| 代码结构 | 逻辑混在 stdin 回调 | 提取为 `handleEvent(event)` | 可测试、可读 |
| 豁免列表 | 缺 CLAUDE.md | 增加 `CLAUDE.md` | CLAUDE.md 是治理文件，应豁免 |
| normalizePath | 不检查空值 | `if (!p) return ''` | 防止空路径导致异常 |

---

## 测试结果

### 基础场景（status=draft）

| 测试 | 输入 | 期望 | 实际 | 结果 |
|------|------|------|------|------|
| Edit src/ | tool_name=Edit, path=src/hook-smoke-test.txt | exit 2 | exit 2 | PASS |
| Edit docs/ | tool_name=Edit, path=docs/test.md | exit 0 | exit 0 | PASS |
| Edit features/ | tool_name=Edit, path=features/example-login/spec.md | exit 0 | exit 0 | PASS |
| Write src/ | tool_name=Write, path=src/hook-smoke-test.txt | exit 2 | exit 2 | PASS |
| Read tool | tool_name=Read | exit 0 | exit 0 | PASS |

### 路径控制（status=implementing）

| 测试 | 路径 | allowed_paths 包含？ | forbidden_paths 包含？ | 期望 | 实际 |
|------|------|---------------------|----------------------|------|------|
| src/auth/login.js | YES | NO | exit 0 | exit 0 | PASS |
| src/hook-smoke-test.txt | NO | NO | exit 2 | exit 2 | PASS |
| src/core/main.js | NO | YES | exit 2 | exit 2 | PASS |

### 异常处理（fail-closed）

| 测试 | 输入 | 期望 | 实际 | 结果 |
|------|------|------|------|------|
| 畸形 JSON | "bad json{{{" | exit 2 | exit 2 | PASS |
| 空 stdin | "" | exit 2 | exit 2 | PASS |

**全部 10 项测试通过。**

---

## 未修改的文件

- gate-bash.js：无语法错误，逻辑无问题，未做修改
- settings.json：hooks 注册格式正确，未做修改
- feature.json：测试中临时改为 implementing，测试后已恢复为 done

---

## 人工验收建议

修复后请在 Claude Code 中执行以下实际测试：

1. 确保 `features/example-login/feature.json` 的 `status` 为 `draft`
2. 在 Claude Code 中要求 AI 编辑 `src/hook-smoke-test.txt`
3. 期望看到 hook 拦截信息，编辑操作被阻止
4. 然后将 `status` 改为 `implementing`，再次尝试编辑 `src/auth/test.js`
5. 期望：允许（在 allowed_paths 内）
6. 尝试编辑 `src/core/test.js`
7. 期望：拦截（在 forbidden_paths 内）
