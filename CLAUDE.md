# 开发规范（最小常驻入口）

## 核心原则

1. **features/ 是唯一执行态根目录** — 每个功能在 `features/<feature-id>/` 下工作
2. **feature.json 是唯一状态源** — 每个功能目录必须有 `feature.json`
3. **先规格、后实现** — 状态未到 `approved` 禁止写入业务代码
4. **任务原子化** — 按 tasks.md 逐条执行，每完成一条标记 ✅

## 命令体系（扁平，无前缀）

| 命令 | 作用 | 产出 |
|------|------|------|
| `/spec` | 需求分析 | `goal.md` + `spec.md` |
| `/design` | 技术设计 | `plan.md` + `design.md` |
| `/tasks` | 任务拆解 | `steps.md` + `tasks.md` |
| `/implement` | 逐步实现 | 业务代码（须 approved） |
| `/verify` | 验收检查 | `verify.md` + 双文档对比 |

## 状态机（严格有序）

```
draft → review → approved → implementing → verifying → done | blocked
```

- `approved` 之前：禁止任何 Edit / Write / MultiEdit 到业务路径
- 状态变更必须人工确认，AI 不得自动推进阶段

## 目录结构

```
features/<feature-id>/
├── feature.json          ← 唯一状态源
├── goal.md               ← 小白版：目标说明
├── plan.md               ← 小白版：方案翻译
├── steps.md              ← 小白版：执行清单
├── acceptance.md         ← 小白版：验收说明
├── spec.md               ← AI 执行版：需求规格
├── design.md             ← AI 执行版：技术设计
├── tasks.md              ← AI 执行版：任务清单
├── verify.md             ← AI 执行版：验证报告
└── evidence/             ← 验证证据链
```

## 关键禁止项

- 禁止使用 `/project:*` 命令
- 禁止使用 `feature.yaml`（只用 `feature.json`）
- 禁止把 `specs/` 当执行态目录（已迁移，见 specs/README.md）
- 禁止新增嵌套 `CLAUDE.md` / `.claude/rules/` / `.claude/skills/`
- 禁止在未 approved 状态下写入业务代码
- 禁止 AI 自动推进阶段闸门

## 规则索引

- 治理核心：`.claude/rules/governance-core.md`
- 实现门禁：`.claude/rules/implementation-gate.md`
- 验证循环：`.claude/rules/validation-loop.md`
- 文档规范：`.claude/rules/docs-spec.md`
- 工作流互锁：`.claude/rules/spec-workflow.md`

## 模板位置

- 小白版：`docs/spec-system/模板/小白版/`
- AI 执行版：`docs/spec-system/模板/AI执行版/`
- 迁移说明：`docs/spec-system/迁移说明.md`
