# 验收说明

> 小白版模板 — 验收说明
> 对应 AI 执行版：verify.md

---

## 验收标准

（列出验收时需要检查的每一项，越具体越好）

- [ ] 验收项 1：目录结构完整性
  - 检查内容：`features/step2-engineering-baseline/` 下是否存在 9 个文件/目录
    - 小白版 4 件套：goal.md, plan.md, steps.md, acceptance.md
    - AI 执行版 4 件套：spec.md, design.md, tasks.md, verify.md
    - feature.json
    - evidence/ 目录
  - 检查方式：执行 `ls -la features/step2-engineering-baseline/`
  - 结果：待填写

- [ ] 验收项 2：feature.json 结构化字段完整性
  - 检查内容：required_checks 中每个检查项是否包含 10 个必需字段
    - id, name, shell, command_windows, command_bash
    - cwd, timeout_sec, allow_network, evidence_file, stop_on_fail
  - 检查方式：JSON 验证工具或人工审查
  - 结果：待填写

- [ ] 验收项 3：真实命令执行证据存在
  - 检查内容：evidence/ 目录是否存在至少一份真实命令执行输出
  - 检查方式：执行 `ls -la features/step2-engineering-baseline/evidence/`
  - 结果：待填写

- [ ] 验收项 4：CI 配置或明确卡点记录
  - 检查内容：是否存在 CI 配置文件，或是否明确记录了无法配置的原因
  - 检查方式：查找 .github/workflows/ 或其他 CI 配置，或查看 P1-T6 的说明
  - 结果：待填写

- [ ] 验收项 5：映射表可追溯性
  - 检查内容：是否存在 required_checks.id -> CI -> evidence_file 映射表
  - 检查内容：三元组是否可以互相追溯
  - 检查方式：查看 mapping-table.md 文件
  - 结果：待填写

- [ ] 验收项 6：汇总文档结论明确
  - 检查内容：P1-T8 汇总文档是否明确回答 E1~E5 是否全部关闭
  - 检查内容：是否给出"可再次发起 04 启动复审"的明确结论
  - 检查方式：查看 04-precondition-summary.md
  - 结果：待填写

- [ ] 验收项 7：未伪造关键信息
  - 检查内容：phase2 批准字段是否标记为"待人工确认"，而非伪造为已批准
  - 检查内容：demo_only 是否未设置为 true
  - 检查方式：审查 feature.json 的 phase 和 demo_only 字段
  - 结果：待填写

---

## 验收结论

- 验收日期：待填写
- 验收人：待填写
- 结论：通过 / 未通过 / 部分通过
- 备注：待填写
