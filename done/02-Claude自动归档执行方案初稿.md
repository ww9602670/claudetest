# Claude 自动归档执行方案初稿

## 1. 方案定位

本方案采用“自动识别 + 自动生成计划 + 人工批准 + 自动执行 + 自动留痕”的混合模式。

原则上：

- 可以自动分析和建议
- 可以自动移动和标记
- 不做无人值守的自动硬删除
- 不让 Claude 直接凭会话记忆判断文档状态

这是一个可重复使用的治理能力，不应依赖本次仓库中的具体文件名硬编码。

## 2. 总体架构

### 2.1 事实源

新增以下项目级事实文件：

1. `docs/spec-system/active-stage.json`
   - 当前激活阶段编号
   - 当前主任务书路径
   - 当前最新审查报告路径
   - 更新时间

2. `docs/spec-system/doc-lifecycle-rules.json`
   - 文档角色判定规则
   - 状态优先级
   - 保护名单
   - 归档目录映射
   - 风险动作白名单

3. `docs/spec-system/doc-registry.json`
   - 每个已识别文档的当前状态
   - 替代关系
   - 最后一次判定时间
   - 是否已归档

### 2.2 自动化执行层

分成四层：

- Hook 层：负责拦截高风险误操作、记录证据
- Skill 层：负责归档计划与归档执行
- Agent 层：负责只读分析与复核
- 文档与清单层：负责输出对人类可审核的计划、报告、manifest

## 3. 建议新增的 Hook

### 3.1 `doc-archive-guard-bash.js`

事件：

- `PreToolUse(Bash)`

职责：

- 拦截针对 `docs/**` 的高风险删除、移动、批量改名命令
- 允许普通读取命令
- 只在满足“存在批准过的 archive plan”时允许执行归档动作

重点拦截：

- `Remove-Item docs\\...`
- `Move-Item docs\\...`
- `git rm docs/...`
- `git mv docs/...`
- 批量通配符删除

允许条件：

- 当前命令由 `/archive-apply` 触发
- 提供合法 `archive-manifest` 路径
- manifest 与 plan 均存在且未过期

### 3.2 `doc-archive-guard-write.js`

事件：

- `PreToolUse(Edit|MultiEdit|Write)`

职责：

- 防止直接修改已归档文档
- 防止未批准就给当前基线文档加失效标记
- 防止直接改写 `active-stage.json`、`doc-registry.json` 中的高风险字段

保护对象：

- `CLAUDE.md`
- `docs/需求.md`
- `docs/spec-system/验收清单.md`
- 当前激活阶段主文档
- 最新阶段审查报告
- 已归档目录中的文档

### 3.3 `doc-archive-record-bash.js`

事件：

- `PostToolUse(Bash)`

职责：

- 记录实际归档执行动作
- 记录被移动的文件、目标路径、时间戳、执行结果
- 输出到 `docs/spec-system/archive-evidence/actions.md`

### 3.4 `doc-archive-record-write.js`

事件：

- `PostToolUse(Edit|MultiEdit|Write)`

职责：

- 记录归档计划文件、registry、manifest 的修改痕迹
- 输出到 `docs/spec-system/archive-evidence/changes.md`

说明：这两类记录型 Hook 可参考现有 `evidence-write.js` / `evidence-bash.js` 的设计模式，但产物目录独立，避免和 `features/**/evidence/` 混用。

## 4. 建议新增的 Skill

### 4.1 `/archive-plan`

定位：

- 高风险前置技能
- `user-invocable: true`
- `disable-model-invocation: true`

输入：

- 作用域，例如 `project-docs` 或 `docs/spec-system`

职责：

1. 读取 `active-stage.json`
2. 读取 `doc-lifecycle-rules.json`
3. 扫描目标文档
4. 调用只读 Agent 做分类建议
5. 生成：
   - `docs/spec-system/archive-plan/<timestamp>.md`
   - `docs/spec-system/archive-plan/<timestamp>.json`
6. 标出：
   - 保留
   - 归档
   - 加失效标记
   - 暂缓处理

### 4.2 `/archive-apply`

定位：

- 高风险执行技能
- `user-invocable: true`
- `disable-model-invocation: true`

输入：

- 已批准的 plan id

职责：

1. 校验 plan 是否存在
2. 校验是否有人工批准标记
3. 再次读取 `active-stage.json`，确认计划没有过期
4. 执行移动或标记动作
5. 更新 `doc-registry.json`
6. 生成：
   - `docs/spec-system/archive-manifest/<timestamp>.json`
   - `docs/spec-system/archive-report/<timestamp>.md`

### 4.3 `/archive-audit`

定位：

- 低风险审计技能

职责：

- 对当前 registry 和实际文件树做差异检查
- 找出未登记的新文档、已丢失文档、错误状态文档
- 生成复核报告

## 5. 建议新增的 Agent

### 5.1 `archive-planner`

权限：

- 只读

职责：

- 根据规则对文档做初步分类
- 给出 `doc_role`、`lifecycle_status`、`reason`
- 输出候选清单，不直接执行改动

### 5.2 `archive-reviewer`

权限：

- 只读

职责：

- 复核 `archive-planner` 的结果
- 专门检查误归档风险
- 重点关注：
  - 当前激活阶段主文档
  - 最新审查报告
  - 当前验收清单
  - 仍被主文档引用的支撑说明

### 5.3 与现有 Agent 的关系

- 现有 `reviewer` 不直接负责归档执行，仍保持代码/实现审查定位
- 文档归档建议新增专用只读 Agent，而不是复用实现侧 Agent
- 自动写入动作应由 Skill 主导，不应让 Agent 直接修改文件

## 6. 推荐执行流程

### 阶段 A：建立事实源

1. 人工确认当前阶段
2. 写入 `active-stage.json`
3. 初始化 `doc-lifecycle-rules.json`
4. 首次生成 `doc-registry.json`

### 阶段 B：只做计划，不做移动

1. 手动触发 `/archive-plan project-docs`
2. `archive-planner` 生成候选结果
3. `archive-reviewer` 做误判复核
4. 产出 plan 文档

### 阶段 C：人工批准

1. 人工查看 plan
2. 只批准低风险项：
   - 临时执行文档归档
   - 已完成旧阶段文档归档
   - 已存在归档目录的补登记
3. 形成批准记录

### 阶段 D：自动执行

1. 手动触发 `/archive-apply <plan-id>`
2. Hook 校验计划与批准
3. Skill 执行移动、标记、登记
4. PostToolUse 记录证据

### 阶段 E：审计复核

1. 运行 `/archive-audit`
2. 对比 registry、manifest、文件树
3. 生成异常清单

## 7. 当前项目的首批规则建议

### 7.1 永久保护

- `CLAUDE.md`
- `docs/需求.md`
- `docs/spec-system/验收清单.md`

### 7.2 当前基线

由 `active-stage.json` 显式指定：

- 当前阶段主任务书
- 最新阶段审查报告

### 7.3 常驻参考

- `docs/spec-system/hooks验证方案.md`
- `docs/spec-system/evidence目录规范.md`
- `docs/spec-system/迁移说明.md`
- `docs/技术难点与解决方案.md`

### 7.4 历史归档候选

- 已完成的旧阶段主文档
- 非最新的阶段审查报告
- `docs/收口执行报告.md`
- 已被新规范覆盖的 `docs/spec-system/第一阶段evidence基线.md`

### 7.5 临时执行文档候选

- `docs/执行指令*.md`
- `docs/继续执行指令.md`
- `docs/收口执行指令.md`
- `docs/审核指令-opus.md`
- `docs/修复指令-opus.md`
- `docs/handoff/*`

## 8. 可复用设计

为了让该方案能复用到其他项目，不应把规则写死在 Hook 里，而应做到：

- Hook 只负责校验和拦截
- 文档分类规则存放在 `doc-lifecycle-rules.json`
- 当前阶段存放在 `active-stage.json`
- 实际判定结果存放在 `doc-registry.json`
- Skill 只读取配置和 registry，不硬编码项目特例

这样迁移到其他仓库时，主要替换的是规则文件，而不是重写 Hook 本体。

## 9. 风险控制策略

### 9.1 不自动做的事

- 不自动硬删除文档
- 不自动降级保护文档
- 不自动修改 `.claude/**`
- 不自动更新当前阶段，必须有明确事实源变更

### 9.2 必须二次确认的事

- 删除
- 当前基线文档降级
- 归档目录结构调整
- 大批量移动超过阈值的归档动作

### 9.3 必须幂等

- 相同 plan 重复执行不得重复移动
- 已归档文档再次执行时应被识别为“已处理”
- manifest 应记录唯一 plan id 和执行批次

## 10. 建议的第一版落地顺序

1. 先补事实源：
   - `active-stage.json`
   - `doc-lifecycle-rules.json`
2. 再做只读能力：
   - `archive-planner`
   - `/archive-plan`
3. 再做保护 Hook：
   - `doc-archive-guard-bash.js`
   - `doc-archive-guard-write.js`
4. 最后做执行技能：
   - `/archive-apply`
   - manifest / report / evidence

## 11. 预期结果

最终效果应是：

- Claude 不再凭感觉处理文档归档
- 当前执行基线不会被旧材料污染
- 文档移动前先有计划，移动后有证据
- 高风险操作有 Hook 拦截
- 归档逻辑可以在本项目反复执行，也可以迁移到其他项目复用
