# 技术设计

> AI 执行版模板 — 技术设计
> 对应小白版：plan.md

---

## 设计概述

本 feature 采用最小化工程方案：在项目根目录创建 `features/step2-engineering-baseline/` 目录，包含完整的双版本文档（小白版 4 件套 + AI 执行版 4 件套）、结构化 feature.json，以及 evidence/ 目录用于存放所有验证证据。

核心思路：使用最基础的命令（如 ls/cat）作为最小工程入口，确保在当前环境可执行，然后建立完整的可追溯证据链。

---

## 架构决策

### 方案选择

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 方案 A：使用 npm test 作为入口 | 可能覆盖更多测试 | 项目无 npm scripts 配置 | 放弃 |
| 方案 B：使用基础命令（ls/cat） | 100% 可执行，适用于任何环境 | 功能覆盖较少 | **选用** |
| 方案 C：等待添加构建脚本 | 更符合工程化标准 | 需要修改现有项目，增加依赖 | 放弃 |

**选用方案 B**：本 feature 的目标是为 04 启动补齐真实前提，不是建立完整测试体系。使用 ls/cat 等基础命令足以验证 required_checks -> command -> evidence -> CI 的完整闭环。

---

## 数据模型变更

本 feature 不涉及数据库变更。

核心数据结构为 feature.json 中的 required_checks：

```json
{
  "required_checks": [
    {
      "id": "check-id",
      "name": "检查项名称",
      "shell": "bash",
      "command_windows": "Windows 命令",
      "command_bash": "Bash 命令",
      "cwd": "执行目录",
      "timeout_sec": 10,
      "allow_network": false,
      "evidence_file": "evidence/输出文件.txt",
      "stop_on_fail": true
    }
  ]
}
```

---

## API 设计

本 feature 不涉及 API 变更。

所有操作通过命令行工具完成：
- `ls`: 列出目录结构
- `cat`: 输出文件内容
- `echo`: 输出文本

---

## 文件变更清单

| 路径 | 操作 | 说明 |
|------|------|------|
| `features/step2-engineering-baseline/goal.md` | 新增 | 小白版 - 功能目标 |
| `features/step2-engineering-baseline/plan.md` | 新增 | 小白版 - 方案翻译 |
| `features/step2-engineering-baseline/steps.md` | 新增 | 小白版 - 执行清单 |
| `features/step2-engineering-baseline/acceptance.md` | 新增 | 小白版 - 验收说明 |
| `features/step2-engineering-baseline/spec.md` | 新增 | AI 执行版 - 需求规格 |
| `features/step2-engineering-baseline/design.md` | 新增 | AI 执行版 - 技术设计 |
| `features/step2-engineering-baseline/tasks.md` | 新增 | AI 执行版 - 任务清单 |
| `features/step2-engineering-baseline/verify.md` | 新增 | AI 执行版 - 验证报告 |
| `features/step2-engineering-baseline/feature.json` | 新增 | 元数据 + 结构化 required_checks |
| `features/step2-engineering-baseline/evidence/` | 新增 | 证据存放目录 |
| `.github/workflows/` | 可能新增 | CI 配置（如仓库支持） |

---

## 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 找不到真实可执行命令 | 低 | 高 | 使用 ls/cat 等基础命令作为保底方案 |
| CI 平台不明确 | 中 | 中 | 明确记录卡点，等待人工确认平台选择 |
| phase2 批准未及时给出 | 中 | 高 | 不伪造批准信息，标记为"待人工确认" |
| 目录权限问题 | 低 | 低 | 在当前项目目录下操作，通常无权限问题 |
