# 第一阶段执行任务清单（给 Sonnet）

> 生成时间：2026-03-28
> 生成者：Opus 审计（第 1~8 步完整输出后）
> 状态：待人工批准后执行
> 替代文件：本文件替代旧的 phase1-plan.json

---

## 前置说明

本清单列出了第一阶段剩余需要落地的所有文件修改。
Sonnet 在执行前应确认：
1. 已读取本文件全部内容
2. 不修改任何业务代码
3. 每次修改后检查文件是否符合预期
4. 不得自行扩展范围
5. 所有追加内容必须原样使用，不要改写措辞

---

## 任务列表

### T-01：为 5 个 rules 文件追加执行层级标注

**可直接执行，无需额外批准。**

在以下 5 个文件的**末尾**追加对应段落（不要修改文件已有内容）。

#### 1. `.claude/rules/governance-core.md` — 在文件末尾追加：

```markdown

---

## 执行层级标注

| 约束项 | 层级 | 执行机制 |
|--------|------|----------|
| 状态机顺序流转（禁止跳跃） | 生效层 | AI 自觉遵守 |
| 禁止 AI 自动推进状态 | 生效层 | AI 自觉遵守 |
| blocked 需说明 block_reason | 生效层 | AI 自觉遵守 |
| approved_by 不得为空 | 硬拦截层 | gate-write.js 在 implementing/verifying 状态下检查 |
| approved_at 为有效时间戳 | 硬拦截层 | gate-write.js 在 implementing/verifying 状态下检查 |
| phase_gate_approved 为 true | 硬拦截层 | gate-write.js 在 implementing/verifying 状态下检查 |
| feature.json 是唯一状态源 | 生效层 | AI 自觉遵守 |
| 禁止 feature.yaml | 生效层 | AI 自觉遵守 |
| 阶段切换必须人工确认 | 生效层 | AI 自觉遵守 + feature.json phase_gate_approved 字段控制 |
```

#### 2. `.claude/rules/implementation-gate.md` — 在文件末尾追加：

```markdown

---

## 执行层级标注

| 检查项 | 层级 | 执行机制 |
|--------|------|----------|
| 1. feature.json 存在 | 硬拦截层 | gate-write.js（无活跃 feature 时拒绝业务写入） |
| 2. status 为 approved/implementing | 硬拦截层 | gate-write.js（只放行 approved/implementing/verifying） |
| 3. approved_by 不为空 | 硬拦截层 | gate-write.js 检查 |
| 4. approved_at 存在 | 硬拦截层 | gate-write.js 检查 |
| 5. phase_gate_approved 为 true | 硬拦截层 | gate-write.js 检查 |
| 6. spec.md 已存在 | 生效层 | AI 自觉遵守 |
| 7. design.md 已存在 | 生效层 | AI 自觉遵守 |
| 8. tasks.md 已存在 | 生效层 | AI 自觉遵守 |
| 9. 路径在 allowed_paths 内 | 硬拦截层 | gate-write.js 检查 |
| 10. 路径不在 forbidden_paths 内 | 硬拦截层 | gate-write.js 检查 |
| 11. 修改对应 tasks.md 中某任务 | 生效层 | AI 自觉遵守 |
| 12. 不在 main/master 分支 | 生效层 | AI 自觉遵守 |
| 13. 未超出 max_fix_rounds | 生效层 | AI 自觉遵守 |
| 14. 无未解决 blocked 依赖 | 生效层 | AI 自觉遵守 |

> **小结**：14 项中有 7 项（#1-5, #9-10）由 gate-write.js 硬拦截，其余 7 项靠 AI 自觉遵守。
```

#### 3. `.claude/rules/validation-loop.md` — 在文件末尾追加：

```markdown

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
```

#### 4. `.claude/rules/docs-spec.md` — 在文件末尾追加：

```markdown

---

## 执行层级标注

本规则中的所有约束均为**生效层**（AI 自觉遵守），无硬拦截支撑。

具体约束：
- 双文档映射关系 → AI 自觉
- 一致性检查 → AI 自觉（在 /verify 中执行）
- 变更同步规则 → AI 自觉
- 命名规范 → AI 自觉
```

#### 5. `.claude/rules/spec-workflow.md` — 在文件末尾追加：

```markdown

---

## 执行层级标注

本规则中的所有约束均为**生效层**（AI 自觉遵守），无硬拦截支撑。

具体约束：
- 文档互锁（spec→design→tasks 顺序）→ AI 自觉
- 变更同步 → AI 自觉
- 命名规范 → AI 自觉
```

**验证方式**：逐一读取 5 个文件，确认末尾已追加对应段落，原有内容未被修改。

---

### T-02：修正验收清单第 8 项

**可直接执行，无需额外批准。**

**操作**：编辑 `docs/spec-system/验收清单.md`

将：
```
- [ ] 8. `.claude/settings.json` 已追加 hooks 注册段
```

改为：
```
- [ ] 8. 用户级 `~/.claude/settings.json` 已配置 hooks 注册段（注意：非项目级 `.claude/settings.json`）
```

**验证方式**：读取文件确认第 8 项已更新，其他行未变。

---

### T-03：删除 5 个 commands 文件（方案 A，已批准）

**✅ 用户已批准方案 A：直接删除 commands 文件。可直接执行。**

**理由**：同名 skills 已完整覆盖所有命令功能且路径正确，commands 中仍残留旧的 `specs/` 路径和 `/project:*` 引用，保留只会造成混乱。

**操作**：删除以下 5 个文件：

```
.claude/commands/spec.md
.claude/commands/design.md
.claude/commands/tasks.md
.claude/commands/implement.md
.claude/commands/verify.md
```

删除后，如果 `.claude/commands/` 目录为空，一并删除该空目录。

**验证方式**：
1. 确认 `.claude/commands/` 目录不存在或为空
2. 确认 `.claude/skills/` 下 5 个 SKILL.md 仍完好（spec/design/tasks/implement/verify）
3. 在 Claude Code 中输入 `/spec` 等命令，确认仍能正确触发对应 skill

---

### T-04：为 designer.md 和 spec-writer.md 追加兼容警告

**可直接执行，无需额外批准。**

#### 1. 编辑 `.claude/agents/designer.md`

在第 12 行 `---`（frontmatter 结束标记）之后、第 14 行 `你是一名资深技术架构师` 之前，插入：

```markdown

> ⚠️ **兼容遗留**：本 Agent 中引用的 `specs/` 输出路径为旧体系路径。
> 新功能请使用 `features/<feature-id>/` 目录。
> 本 Agent 将在第二阶段迁移到新路径体系。

```

#### 2. 编辑 `.claude/agents/spec-writer.md`

在第 12 行 `---`（frontmatter 结束标记）之后、第 14 行 `你是一名资深需求分析师` 之前，插入：

```markdown

> ⚠️ **兼容遗留**：本 Agent 中引用的 `specs/` 输出路径为旧体系路径。
> 新功能请使用 `features/<feature-id>/` 目录。
> 本 Agent 将在第二阶段迁移到新路径体系。

```

**验证方式**：两个文件的 frontmatter 后均可见警告段落，原有内容（角色描述、工作原则等）未被修改。

---

## 任务依赖关系

```
T-01（rules 标注）  ──┐
T-02（验收清单修正）──┼── 无依赖，可并行执行
T-03（commands 删除）──┤
T-04（agents 警告） ──┘
```

## 执行完成后的后续步骤

1. 运行 `tests/verify-hooks.ps1` 确认 hooks 回归通过（PowerShell 中执行）
2. 人工逐项勾选 `docs/spec-system/验收清单.md`（19 项正向 + 6 项负向）
3. 全部通过后，人工宣布第一阶段验收完成
4. 不要自动进入第二阶段
