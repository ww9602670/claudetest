# gate-write.js 闸门失效 — 故障诊断与修复方案

## 现象

将 `features/example-login/feature.json` 的 `status` 改为 `draft` 后，对 `src/hook-smoke-test.txt` 执行 Edit 操作，hook 未拦截，写入成功。

## 根因

**gate-write.js 第 34 行存在 JavaScript 语法错误，脚本根本无法加载。**

```javascript
// 第 34 行（当前有 Bug 的代码）
return p.replace(/\/g, '/').replace(/^[A-Za-z]:\//, '/');
```

在 Sonnet 生成代码时，反斜杠正则表达式的转义被错误处理。写入磁盘的实际字节中，正则字面量 `/\/g` 的转义序列不完整，导致 JavaScript 解析器抛出 `SyntaxError: missing ) after argument list`。

### 实测证据

```
$ echo '{"tool_name":"Edit","tool_input":{"file_path":"H:\claude_worke\src\hook-smoke-test.txt"}}' \
  | node .claude/hooks/gate-write.js

SyntaxError: missing ) after argument list
    at gate-write.js:34
```

### 问题链条

```
gate-write.js 第 34 行语法错误
  → Node.js 加载阶段即抛 SyntaxError
    → 进程异常退出（既非 exit 0 也非 exit 2）
      → Claude Code hook 机制视异常退出为 fail-open
        → 所有 Edit / Write / MultiEdit 操作不受拦截
```

### 为什么 gate-bash.js 没有同样的问题？

gate-bash.js 中没有 `normalizePath` 函数，不涉及反斜杠正则替换，因此无语法错误。实测 gate-bash.js 可以正常加载运行。

---

## 修复方案

### 修复 1（必须）：修正 normalizePath 正则

将第 34 行替换为不依赖正则反斜杠字面量的写法：

```javascript
// 修复前（有 Bug）
return p.replace(/\/g, '/').replace(/^[A-Za-z]:\//, '/');

// 修复后（推荐：用 split/join 替代正则，完全避免转义歧义）
return p.split('\').join('/').replace(/^[A-Za-z]:\//, '/');
```

**为什么推荐 split/join**：反斜杠正则在多种工具链（AI 生成、编辑器写入、Read 回读）中极易被二次转义或吃掉转义。`split('\').join('/')` 语义清晰，无歧义。

### 修复 2（建议）：补充 hook 自检

在 `main()` 调用前添加一次性自检，确保核心函数可用：

```javascript
// 在 main() 之前
try {
  normalizePath('C:\test');
} catch (e) {
  process.stderr.write('[gate-write] 自检失败: ' + e.message + '\n');
  process.exit(2); // 自检失败时拒绝放行，不走 fail-open
}
```

### 修复 3（必须）：验证修复效果

修复后执行以下测试：

```bash
# 测试 1：status=draft 时写 src/ → 应被拦截（exit 2）
cd H:/claude_worke
echo '{"tool_name":"Edit","tool_input":{"file_path":"H:\claude_worke\src\hook-smoke-test.txt"}}' \
  | node .claude/hooks/gate-write.js
# 期望：stderr 输出拒绝原因，exit code 2

# 测试 2：豁免路径（docs/）→ 应放行（exit 0）
echo '{"tool_name":"Edit","tool_input":{"file_path":"H:\claude_worke\docs\test.md"}}' \
  | node .claude/hooks/gate-write.js
# 期望：exit 0，无 stderr

# 测试 3：在 Claude Code 中实际操作
# 确保 feature.json status=draft，尝试 Edit src/ 下文件
# 期望：Claude Code 显示 hook 拦截，操作被阻止
```

---

## 影响范围

| 组件 | 状态 | 说明 |
|------|------|------|
| gate-write.js | ❌ **完全失效** | 语法错误，无法加载 |
| gate-bash.js | ✅ 正常 | 实测可运行 |
| settings.json hooks 注册 | ✅ 正常 | 格式正确 |
| feature.json 模板/示例 | ✅ 正常 | 字段完整 |
| rules/*.md | ✅ 正常 | 逻辑描述无误 |

---

## 修复后清理

1. 将 `features/example-login/feature.json` 的 `status` 恢复为 `done`
2. `src/hook-smoke-test.txt` 为测试文件，可删除或保留

---

## 修正复审结论

原复审结论由"通过"降级为 **有条件通过**：

- **唯一阻塞项**：gate-write.js 第 34 行语法错误
- 修复工作量：改动 1 行代码 + 回归测试 3 项
- 其余 18 项正向检查 + 6 项负向检查仍然成立
- 修复并验证通过后即可恢复为"通过"
