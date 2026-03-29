# 需求规格

> AI 执行版模板 — 需求规格
> 对应小白版：goal.md

---

## 功能概述

**feature-id**: `step2-engineering-baseline`
**状态**: draft
**创建日期**: 2026-03-29
**用途**: 《04 启动前真实前提补齐任务包》的真实工程载体

本 feature 不是用户可见功能，而是用于补齐 04 阶段再次启动复审所需的真实前提与真实证据的工程化基线验证对象。

---

## 需求范围

### In Scope（允许）

- FR-01: 创建符合 04 文档要求的 feature 目录结构
- FR-02: 补齐 feature.json 的结构化 required_checks schema（10 字段）
- FR-03: 确认至少一条真实可执行命令并执行，留存证据
- FR-04: 建立最小 CI 配置或明确记录卡点
- FR-05: 产出 required_checks.id -> CI -> evidence_file 映射表
- FR-06: 完成前置补齐证据汇总（E1~E5 逐项判断）
- NFR-01: 所有操作必须基于仓库真实现状，不得伪造证据
- NFR-02: phase2 批准字段不得伪造，需标记为"待人工确认"

### Out of Scope（禁止）

- 不处理 04 的正式工程化接入实施（T1~T10）
- 不处理 05 阶段的自动化增强内容
- 不伪造 phase2 批准字段
- 不伪造命令执行结果或 CI 运行结果
- 不修改 node_modules/ 或 .git/
- 不把"前置补齐完成"宣称成"04 已完成"

---

## 输入/输出规格

### 输入

| 字段 | 类型 | 必填 | 校验规则 |
|------|------|------|----------|
| feature_id | string | 是 | 必须为 `step2-engineering-baseline` |
| 结构化 required_checks | array | 是 | 每项必须包含 10 个必需字段 |
| 真实命令 | string | 是 | 必须在当前环境可执行 |

### 输出

| 场景 | 状态码 | 返回内容 |
|------|--------|----------|
| 成功 | 200 | feature 目录结构完整，evidence 文件存在 |
| 命令执行失败 | 非0 | 保留真实错误输出，不伪造成功 |
| CI 无法配置 | N/A | 明确记录卡点和原因 |

---

## 成功标准

- AC-01: features/step2-engineering-baseline/ 目录存在且包含 9 个文件/目录
- AC-02: feature.json 的 required_checks 中每项包含完整的 10 个字段
- AC-03: evidence/ 目录存在至少一份真实命令执行输出
- AC-04: 存在 CI 配置文件或明确的卡点记录
- AC-05: 存在 required_checks.id -> CI -> evidence_file 映射表
- AC-06: P1-T8 汇总文档明确回答 E1~E5 是否全部关闭
- AC-07: phase2 批准字段标记为"待人工确认"，未伪造为已批准

---

## 依赖与约束

- 依赖模块：现有仓库结构、可用命令行工具
- 技术约束：当前环境需支持至少一条可执行命令
- 禁止修改：node_modules/, .git/, 05 阶段内容
- 人工确认点：phase2 批准、CI 平台选择（如需）
