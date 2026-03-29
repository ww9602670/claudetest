# 执行清单

> 小白版模板 — 执行清单
> 对应 AI 执行版：tasks.md

---

## 说明

本清单列出了实现 04 启动前真实前提补齐的所有步骤。每完成一步，在前面打勾 ✅。

**注意**：步骤必须按顺序执行，不能跳过。

---

## 执行步骤

- [ ] 步骤 1：创建真实 feature 目录结构（P0-T2）
  - 创建 `features/step2-engineering-baseline/` 目录
  - 创建小白版 4 件套：goal/plan/steps/acceptance.md
  - 创建 AI 执行版 4 件套：spec/design/tasks/verify.md
  - 创建 feature.json（包含结构化 required_checks）
  - 创建 evidence/ 目录
  - 预计时间：5 分钟
  - 完成标志：ls 命令能列出所有 9 个文件/目录

- [ ] 步骤 2：补齐真实 feature.json（P0-T3）
  - 确认基础字段完整（feature_id/owner/allowed_paths/forbidden_paths）
  - 确认 required_checks 采用结构化 schema（10 字段齐全）
  - 准备 phase2 批准入档框架（标记为"待人工确认"）
  - 预计时间：3 分钟
  - 完成标志：feature.json 可被 JSON 工具正确解析

- [ ] 步骤 3：确认最小工程入口（P0-T4）
  - 审查项目现有脚本和配置
  - 选定至少一条真实可执行命令
  - 确认该命令在 required_checks 中有完整定义
  - 预计时间：5 分钟
  - 完成标志：找到至少一条可在当前环境执行的命令

- [ ] 步骤 4：跑通一次真实命令并留存证据（P0-T5）
  - 在项目根目录执行步骤 3 选定的命令
  - 捕获完整输出（包括错误或失败信息）
  - 将输出保存到 evidence/ 目录
  - 预计时间：2 分钟
  - 完成标志：evidence/ 目录下存在真实输出文件

- [ ] 步骤 5：建立最小 CI 检查链（P1-T6）
  - 根据仓库现状判断是否已有 CI
  - 若无 CI，创建最小配置草案
  - 若需人工确认平台或触发方式，明确说明卡点
  - 预计时间：10 分钟
  - 完成标志：存在 CI 配置文件或明确的卡点记录

- [ ] 步骤 6：产出首份真实映射（P1-T7）
  - 整理 required_checks.id
  - 整理 CI 运行标识
  - 整理 evidence 文件路径
  - 形成三元组映射表
  - 预计时间：5 分钟
  - 完成标志：mapping-table.md 文件存在且内容可追溯

- [ ] 步骤 7：完成前置补齐证据汇总（P1-T8）
  - 逐项核对 E1~E5 的完成情况
  - 列出所有已产出的证据文件路径
  - 给出"是否已满足再次复审条件"的明确结论
  - 预计时间：5 分钟
  - 完成标志：04-precondition-summary.md 汇总文档完整

- [ ] 步骤 8：整体测试
  - 验证所有 required_checks 可执行
  - 确认所有证据文件存在且可访问
  - 完成标志：所有验收标准（见 acceptance.md）均通过

---

## 当前进度

已完成：0 / 8 步
