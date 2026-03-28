# 第一阶段最小 Evidence 基线

## 目的

统一第一阶段对 evidence 产物的最低要求，避免 `example-login` 与其他文档口径分叉。

---

## example-login 定位

- `features/example-login/` 是**占位演示示例**
- `feature.json` 中 `demo_only: true` 标记其非真实业务
- evidence 目录中的文件为占位符，不对应真实命令输出
- 第一阶段明确允许占位演示示例存在

---

## 第一阶段最小 evidence 要求

对于第一阶段已产出的治理体系（hooks / rules / skills / templates），evidence 基线为：

| 产物 | 最小 evidence | 存放位置 |
|------|---------------|----------|
| gate-write.js | `tests/verify-hooks.ps1` 18/18 全过 | `tests/verify-hooks.ps1` |
| gate-bash.js | `tests/verify-hooks.ps1` 18/18 全过 | `tests/verify-hooks.ps1` |
| hooks 注册 | 用户级 `~/.claude/settings.json` 含 hooks 配置 | 验证方案文档 |
| 验收清单 25 项 | 逐项审查通过 | `docs/spec-system/验收清单.md` |
| 口径统一 5 条 | 审查报告记录 | `docs/spec-system/验收清单审查报告.md` |

### 占位示例 evidence

`features/example-login/evidence/` 中的 `20260328-100000-check-results.txt`：
- 内容为虚拟命令输出（lint + test），带有明确的占位符声明
- 不作为真实闭环验收依据
- 仅用于演示 evidence 目录结构和文件命名规范

---

## evidence 产物命名规范

```
evidence/<YYYYMMDD>-<HHMMSS>-<描述>.txt
```

示例：`evidence/20260328-100000-check-results.txt`

---

## 本阶段不引入

- 不引入 CI 自动归档
- 不要求真实业务代码的测试 evidence
- 不引入 Stop / SubagentStop 类 hook

## 阶段 03 已引入

- `PostToolUse` 证据沉淀 hooks（`evidence-write.js` / `evidence-bash.js`）
- 标准化 evidence 目录规范（`change-summary.md` / `checks.md` / `iteration-log.md`）
- 详见 `docs/spec-system/evidence目录规范.md`

---

## 后续阶段演进

当阶段 03/04 产出真实可运行示例时，evidence 基线将升级为：
- 真实命令输出（非占位符）
- 真实测试结果
- 可重复执行的验证命令
