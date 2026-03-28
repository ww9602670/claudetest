# 给 Claude 的执行说明

你正在执行一套新站点 API 能力测试。目标是验证当前 API 路径是否稳定支撑 Claude Code 的真实 agent 工作流。

## 输入参数

- `RunLabel`
  由用户提供。
  如果用户没有提供，使用 `manual-run`。

## 工作目录

仓库根目录：

`H:\claude_worke`

测试包目录：

`H:\claude_worke\tests\api-capability-suite`

本次运行目录：

`H:\claude_worke\tests\api-capability-suite\runs\<RunLabel>`

## 规则

1. 所有写入只允许发生在 `runs/<RunLabel>` 目录下。
2. 失败时不要提前停止。记录失败，尽量继续后续步骤。
3. 尽量使用工具，不要只给口头说明。
4. 先执行自动化步骤，再回复结果。
5. 如果无法确认某项，请明确写入产物文件，不要假设通过。

## 执行顺序

### 第 1 步：初始化运行目录

运行：

```powershell
powershell -ExecutionPolicy Bypass -File tests/api-capability-suite/setup_run.ps1 -RunLabel <RunLabel> -Force
```

然后阅读：

- `tests/api-capability-suite/RUNBOOK.md`
- `tests/api-capability-suite/runs/<RunLabel>/input/alpha.txt`
- `tests/api-capability-suite/runs/<RunLabel>/input/beta.txt`
- `tests/api-capability-suite/runs/<RunLabel>/input/gamma.txt`

### 第 2 步：写入环境快照

创建：

`tests/api-capability-suite/runs/<RunLabel>/output/environment_snapshot.json`

JSON 必须至少包含这些字段：

```json
{
  "run_label": "manual-run",
  "timestamp_utc": "2026-03-28T00:00:00Z",
  "cwd": "H:\\claude_worke",
  "anthropic_base_url": "https://example.com",
  "key_source": "AIPAIBOX_CLAUDE_API_KEY",
  "api_key_masked": "***abcd",
  "model_hints": {
    "AIPAIBOX_CLAUDE_MODEL": "",
    "AIPAIBOX_CLAUDE_SONNET_MODEL": "",
    "AIPAIBOX_CLAUDE_OPUS_MODEL": ""
  },
  "self_reported_model": "",
  "notes": []
}
```

要求：

- 相关值优先通过 shell 读取环境变量，不要凭空猜。
- `api_key_masked` 只保留后 4 位，前面统一写 `***`。
- `self_reported_model` 写你当前自述使用的模型名称。

### 第 3 步：结构化汇总

读取三个输入文件，创建：

`tests/api-capability-suite/runs/<RunLabel>/output/summary.json`

JSON 必须包含：

- `files`
- `word_counts`
- `combined_unique_words`
- `longest_word`
- `total_unique_word_count`
- `generated_by_model`

要求：

- `combined_unique_words` 必须按字母升序排序。

### 第 4 步：工具链闭环

先读取 `summary.json`，再创建：

`tests/api-capability-suite/runs/<RunLabel>/output/report.md`

`report.md` 必须包含：

- 标题
- 三个文件名
- 总唯一词数
- 最长单词
- 当前 `RunLabel`

然后运行 shell 命令计算 `report.md` 的 SHA256，并写入：

`tests/api-capability-suite/runs/<RunLabel>/output/report.sha256.txt`

文件内容格式固定为：

```text
sha256: <64位小写十六进制>
```

### 第 5 步：长上下文检查

创建：

`tests/api-capability-suite/runs/<RunLabel>/input/long_context.txt`

要求：

- 至少 5000 个字符
- 内容应当是确定性的，不要用随机文本

然后读取该文件，并创建：

`tests/api-capability-suite/runs/<RunLabel>/output/long_context_check.txt`

格式固定为：

```text
character_count: <整数>
first_40: <前40字符>
last_40: <后40字符>
```

补充规则：

- `character_count` 按文件实际字符数填写。
- 如果文件末尾带有换行，`first_40` 和 `last_40` 以去掉末尾换行后的可见文本预览为准。

### 第 6 步：重复命令稳定性

顺序执行 10 条短 shell 命令。

建议命令类型：

- 输出当前目录
- 输出当前时间
- 列出运行目录文件
- 统计某个生成文件的行数
- 读取某个生成文件的前几行

将结果写入：

`tests/api-capability-suite/runs/<RunLabel>/logs/repeated_commands.json`

JSON 必须包含：

```json
{
  "runs": [
    {
      "id": 1,
      "command": "Get-Location",
      "success": true,
      "output_preview": "H:\\claude_worke"
    }
  ]
}
```

要求：

- 必须有 10 条
- `id` 从 1 到 10
- `output_preview` 尽量保留单行摘要

### 第 7 步：下游结果文件

读取：

- `output/report.sha256.txt`
- `logs/repeated_commands.json`

创建：

`tests/api-capability-suite/runs/<RunLabel>/output/tool_chain_result.json`

JSON 必须包含：

- `source_files_read`
- `report_sha256`
- `repeated_command_success_count`
- `generated_by_model`
- `notes`

### 第 8 步：运行校验脚本

运行：

```powershell
powershell -ExecutionPolicy Bypass -File tests/api-capability-suite/validate_run.ps1 -RunLabel <RunLabel>
```

读取生成的：

`tests/api-capability-suite/runs/<RunLabel>/logs/validator_summary.json`

### 第 9 步：写最终评估

创建：

`tests/api-capability-suite/runs/<RunLabel>/output/final_evaluation.md`

必须包含以下一级标题：

1. `Overall Result`
2. `Succeeded Steps`
3. `Failed Steps`
4. `Observed Stability Risks`
5. `Manual Verification Needed`
6. `Recommendation`

要求：

- `Recommendation` 只能写一个值：
  - `usable`
  - `usable_with_caution`
  - `not_stable_enough`
- 如果人工核对项尚未完成，默认不要写成 `usable`。
- 结论必须基于本次运行证据，不要凭印象判断。

## 最终聊天回复格式

全部完成后，聊天里只回复 3 行：

1. 推荐值
2. `final_evaluation.md` 的绝对路径
3. `validator_summary.json` 的绝对路径

不要附带长篇解释。
