# 任务清单

> AI 执行版模板 — 任务清单
> 对应小白版：steps.md

---

## 说明

每条任务必须：
- 原子化：单一职责，不可再拆分
- 可验证：完成后有明确的验证方法
- 有范围：明确修改哪些文件

完成一条在前面标记 ✅，未完成为 [ ]。

---

## 任务列表

- [ ] T-01: 创建 features/step2-engineering-baseline/ 目录结构
  - 修改文件：创建目录及 9 个文件/目录
  - 验证方法：`ls -la features/step2-engineering-baseline/` 列出完整清单
  - 影响范围：仅新增目录，不影响现有功能

- [ ] T-02: 填充小白版 4 件套（goal/plan/steps/acceptance.md）
  - 修改文件：features/step2-engineering-baseline/{goal,plan,steps,acceptance}.md
  - 验证方法：每个文件内容非空，且符合模板结构
  - 影响范围：仅新增文档

- [ ] T-03: 填充 AI 执行版 4 件套（spec/design/tasks/verify.md）
  - 修改文件：features/step2-engineering-baseline/{spec,design,tasks,verify}.md
  - 验证方法：每个文件内容非空，且符合模板结构
  - 影响范围：仅新增文档

- [ ] T-04: 创建 feature.json 并补齐结构化 required_checks
  - 修改文件：features/step2-engineering-baseline/feature.json
  - 验证方法：JSON 格式正确，required_checks 中每项包含 10 个字段
  - 影响范围：仅新增文件

- [ ] T-05: 确认最小工程入口并执行真实命令
  - 修改文件：无（仅执行命令）
  - 验证方法：命令成功执行，输出保存到 evidence/
  - 影响范围：仅产生 evidence 文件

- [ ] T-06: 建立 CI 配置或明确记录卡点
  - 修改文件：.github/workflows/ 或其他 CI 配置（如适用）
  - 验证方法：配置文件存在，或文档明确说明卡点
  - 影响范围：可能新增 CI 配置

- [ ] T-07: 产出 required_checks.id -> CI -> evidence 映射表
  - 修改文件：features/step2-engineering-baseline/evidence/mapping-table.md
  - 验证方法：三元组可互相追溯，至少有一条记录
  - 影响范围：仅新增 evidence 文件

- [ ] T-08: 完成前置补齐证据汇总
  - 修改文件：features/step2-engineering-baseline/evidence/04-precondition-summary.md
  - 验证方法：文档明确回答 E1~E5 是否全部关闭
  - 影响范围：仅新增 evidence 文件

---

## 完成记录

| 任务 | 完成时间 | 执行人 | 备注 |
|------|----------|--------|------|
| T-01 | 2026-03-29 | Sonnet | |
| T-02 | 2026-03-29 | Sonnet | |
| T-03 | 2026-03-29 | Sonnet | |
| T-04 | 2026-03-29 | Sonnet | |
| T-05 | 待执行 | Sonnet | |
| T-06 | 待执行 | Sonnet | |
| T-07 | 待执行 | Sonnet | |
| T-08 | 待执行 | Sonnet | |
