# 新站点 API 测试清单

## 目标

验证新站点 API 是否真的能支撑 Claude Code 的核心能力，而不是只支持表面兼容。

重点验证：

1. 基础接入是否稳定
2. 文件读写和 shell 工具调用是否闭环
3. 长上下文处理是否可用
4. 重复命令执行是否稳定
5. 多轮记忆是否可靠
6. 请求模型名、Claude 自述模型、第三方后台计费模型是否一致

## 推荐测试矩阵

至少执行以下两组：

1. `cc` 启动
   标签建议：`sonnet-baseline`
2. `cco` 启动
   标签建议：`opus-baseline`

可选补充组：

3. 自定义模型名环境变量
   标签建议：`custom-model`

## 自动化检查项

所有自动化产物都应写到：

`tests/api-capability-suite/runs/<RunLabel>/`

### 1. 环境快照

文件：

`output/environment_snapshot.json`

验证：

- 记录运行标签
- 记录当前工作目录
- 记录 `ANTHROPIC_BASE_URL`
- 记录 key 来源
- 记录模型相关环境变量
- 记录 Claude 自述的当前模型

### 2. 结构化汇总

文件：

`output/summary.json`

验证：

- 正确读取 `alpha.txt`、`beta.txt`、`gamma.txt`
- 输出文件名列表
- 输出每个文件词数
- 输出排序后的唯一词数组
- 输出最长单词
- 输出总唯一词数
- 输出 `generated_by_model`

### 3. 工具链闭环

文件：

- `output/report.md`
- `output/report.sha256.txt`
- `output/tool_chain_result.json`

验证：

- 能从 `summary.json` 继续生成 `report.md`
- 能调用 shell 计算 `report.md` 的 SHA256
- 能把 hash 结果再写回磁盘
- 能读取 `repeated_commands.json` 和 `report.sha256.txt` 再生成一个下游结果文件

### 4. 长上下文

文件：

- `input/long_context.txt`
- `output/long_context_check.txt`

验证：

- `long_context.txt` 长度至少 5000 字符
- `long_context_check.txt` 中记录的字符数与实际一致
- `first_40` 和 `last_40` 与预览文本一致
  预览文本默认按原文件去掉末尾换行后计算

### 5. 重复命令稳定性

文件：

`logs/repeated_commands.json`

验证：

- 一共执行 10 条短命令
- 每条都有 `id`、`command`、`success`
- 记录结果时不漏项

### 6. 最终评估

文件：

- `output/final_evaluation.md`
- `logs/validator_summary.json`

验证：

- `final_evaluation.md` 至少包含规定章节
- 建议值只能是 `usable`、`usable_with_caution`、`not_stable_enough`
- `validator_summary.json` 能反映自动化检查是否通过

## 人工补充验证项

这些项目不能只靠 Claude 在本地自证，必须人工核对。

### 1. 多轮记忆

按 `MULTI_TURN_SEQUENCE.md` 逐轮发给 Claude。

观察：

- 中间穿插工具调用后，前面给出的标记是否还能正确回忆
- 是否出现混淆、遗漏、编造
- 是否会把未提供的信息当成已知事实

记录到：

`logs/multi_turn_observations.md`

### 2. 后台模型与计费一致性

去第三方平台后台核对：

- 本次运行标签对应的请求次数
- 请求模型名
- 实际计费模型
- token 使用量
- 是否存在静默从 Opus 回退到 Sonnet

记录到：

`logs/provider_observations.md`

### 3. `/model` 切换可信度

如果本次运行中手动执行过 `/model`：

- 记录 Claude 自述切换后的模型
- 对照后台模型和计费模型
- 标记是否出现“界面显示已切换，但后台仍计费旧模型”

## 判定标准

### `usable`

- 自动化关键项全部通过
- 多轮记忆通过
- 后台模型、请求模型、计费模型一致
- 没有明显的静默降级

### `usable_with_caution`

- 自动化大部分通过
- 但存在人工项未完成、偶发失败、模型信息不一致、或有轻微稳定性风险

### `not_stable_enough`

满足任一项即可：

- 自动化关键项失败
- 工具链闭环失败
- 长上下文明显不可靠
- 多轮记忆明显不可靠
- 后台模型或计费出现静默降级且无法解释

## 建议保留的关键证据

- `output/final_evaluation.md`
- `logs/validator_summary.json`
- `logs/repeated_commands.json`
- `logs/multi_turn_observations.md`
- `logs/provider_observations.md`
