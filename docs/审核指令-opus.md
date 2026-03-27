只做“第一阶段最小落地复审”，不得重新做总审计，不得修改文件。

优先只读取：
1. docs/handoff/phase1-plan.json
2. docs/spec-system/迁移说明.md
3. docs/spec-system/验收清单.md
4. Sonnet 本轮完成报告

仅在必要时，补读以下关键文件：
- CLAUDE.md
- .claude/settings.json
- .claude/rules/governance-core.md
- .claude/rules/implementation-gate.md
- .claude/rules/validation-loop.md
- .claude/rules/docs-spec.md
- .claude/rules/spec-workflow.md
- .claude/hooks/gate-write.js
- .claude/hooks/gate-bash.js
- .claude/skills/implement/SKILL.md
- .claude/skills/verify/SKILL.md
- docs/spec-system/模板/AI执行版/feature.json
- features/example-login/feature.json
- specs/README.md

禁止：
- 重读 docs/需求.md 全文
- 重读 docs/技术难点与解决方案.md 全文
- 重新扫描整个 .claude/
- 重新扫描整个 features/
- 修改任何文件

你的任务：
1. 判断 Sonnet 是否真正完成第一阶段最小闭环
2. 判断是否存在越界、遗漏或与阶段目标不符之处
3. 按“通过 / 有条件通过 / 不通过”给出结论
4. 如果不完全通过，列出最小修复清单（只列必须修的项）
5. 如果通过，列出我接下来人工验收时最该检查的 5 个点

输出要求：
- 不复述大文档
- 只输出结论、证据点、问题清单
- 结束后立即停止