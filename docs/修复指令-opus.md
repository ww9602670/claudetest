现在进入“第一阶段验收阻断项修复”阶段。不要重做总体设计，不要进入第二阶段，不要修改任何业务代码，只处理治理层阻断项。

当前状态结论：
1. 第一阶段暂不建议签收。
2. 已明确的不通过项是 gate-bash.js 白名单绕过。
3. 已明确的部分通过项是 implementation-gate.md 与 gate-write.js 批准字段校验语义不一致。
4. /project:* 的验收口径、example-login 的定位，仍需明确。
5. 上一次“文档互锁未生效”的测试方法不严谨，因为它是通过 Bash 直接在工作区外 test_workspace 写 design.md，不足以证明 skill / workflow 层的互锁机制是否真实生效。

你现在严格按以下顺序执行，不要跳步：

第一步：修复 gate-bash.js
目标：
- 在 verifying 模式下改为精确匹配允许命令
- 拒绝任何拼接/组合命令，包括但不限于：
  - &&
  - ||
  - ;
  - |
  - >
  - >>
  - <
- 明确说明修改前漏洞成因、修改后拦截策略、可能的误伤边界

第二步：补充 verify-hooks.ps1
目标：
- 增加至少 3 个验证用例，覆盖 verifying 阶段的命令拼接绕过场景
- 必须至少包含：
  1. npm run lint && rm -rf /
  2. npm run lint ; echo hacked
  3. npm run lint | cat
- 输出新增测试项编号、预期结果、实际结果

第三步：修复 gate-write.js 与规则文档不一致
目标：
- 在 approved / implementing / verifying 三个状态都强校验：
  - approved_by
  - approved_at
  - phase_gate_approved
- 增加 approved_at 的时间格式校验
- 若治理规则要求一致，也补上 approved_method 校验
- 同时更新 implementation-gate.md 中与硬拦截层相关的描述，确保文档与代码一致

第四步：不要擅自决定 /project:* 和 example-login 的最终口径
你只需要先输出两个“待人工拍板方案”：
A. /project:* 验收标准：
- 方案 A：仓内字面完全不允许出现
- 方案 B：允许在迁移说明/禁用说明中出现，但不得作为执行入口或推荐命令

B. example-login 定位：
- 方案 A：补成真实闭环示例
- 方案 B：明确降级为占位演示示例

你可以给建议，但不要擅自落地其中一个方案。

第五步：用正确方法重做“文档互锁”验证
注意：
- 不要再用 Bash 直接 cat/echo 写 design.md
- 不要在工作区外 test_workspace 做实验
- 必须在当前仓库的 features/<test-id>/ 下做最小验证
- 故意不创建 spec.md
- 然后通过 /design 对应的 skill / Claude 工作流去推进，观察系统是否拒绝

输出必须包含：
1. 这次验证是通过什么入口推进的
2. 哪个层级识别到违规（rule / skill / workflow / 其他）
3. 是否真正阻止继续
4. 如果仍未阻止，明确写“文档互锁仍未生效”
5. 不要把 shell 直接写文件视为互锁验证通过或失败的依据

第六步：修完后更新两份文档
- docs/spec-system/验收清单.md
- docs/spec-system/验收清单审查报告.md

要求：
- 重新标注通过 / 部分通过 / 不通过 / 需人工复核
- 明确列出本轮修复了哪些阻断项
- 明确列出仍待人工拍板的口径项

输出要求：
- 全程中文
- 先修代码和验证，再改文档
- 每一步都要给出“修改了哪些文件、为什么改、验证结果如何”
- 不要再问“是否继续”
- 不要进入第二阶段