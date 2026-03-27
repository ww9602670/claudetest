# 开发规范

本工作区使用 **Spec 驱动开发流程**，所有功能开发必须遵循以下规范。

## 核心原则

1. **先规格、后实现**：任何功能必须先产出 Spec 文档，经确认后才能编码
2. **可追溯**：每个功能的 Spec → Design → Tasks → 代码 形成完整链路
3. **任务原子化**：实现阶段按 Task 清单逐条执行，每完成一条标记 ✅
4. **持续验证**：每个 Task 完成后立即验证，而非全部完成后再检查

## 开发流程（必须按顺序执行）

```
需求输入 → /project:spec → /project:design → /project:tasks → /project:implement → /project:verify
```

### 阶段说明

| 阶段 | 命令 | 产出物 | 存放位置 |
|------|------|--------|----------|
| 需求分析 | `/project:spec` | `spec.md` | `specs/<功能名>/spec.md` |
| 技术设计 | `/project:design` | `design.md` | `specs/<功能名>/design.md` |
| 任务拆解 | `/project:tasks` | `tasks.md` | `specs/<功能名>/tasks.md` |
| 逐步实现 | `/project:implement` | 代码文件 | 项目源码目录 |
| 验收检查 | `/project:verify` | `verify.md` | `specs/<功能名>/verify.md` |

## 文档规范

- Spec 文档使用中文
- 文件名使用英文小写 + 连字符（kebab-case）
- 每个功能模块在 `specs/` 下建立独立目录
- 功能目录名应简洁明确，如 `user-auth`、`data-export`

## 代码规范

- 新增代码必须与现有项目风格保持一致
- 修改前先阅读相关现有代码
- 每个 Task 的改动应尽量独立，避免跨 Task 耦合
- 如需修改公共模块，在 Task 描述中明确标注影响范围

## 沟通规范

- 遇到需求模糊时，**主动提问**而非假设
- 每个阶段完成后向用户汇报产出物路径
- 发现 Spec 与实际实现有冲突时，先更新 Spec 再继续
