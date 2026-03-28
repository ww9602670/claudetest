# 新站点 API 能力测试包

这套测试包用于验证接入新站点 API 的 Claude Code 是否能稳定完成真实 agent 工作流，而不是只完成单轮聊天。

## 目录说明

- `EXECUTE_WITH_CLAUDE.md`
  给 Claude 自己读取并执行的指令文件。
- `RUNBOOK.md`
  完整测试清单、通过标准、人工补充验证项。
- `MULTI_TURN_SEQUENCE.md`
  需要你手动逐轮发送给 Claude 的多轮记忆测试提示词。
- `setup_run.ps1`
  初始化单次测试运行目录、输入文件、人工观察模板。
- `validate_run.ps1`
  校验 Claude 生成的产物是否齐全、格式是否正确，并给出结构化结果。

## 推荐执行方式

至少跑两次：

1. `cc`
   建议标签：`sonnet-baseline`
2. `cco`
   建议标签：`opus-baseline`

如果你怀疑第三方网关要求自定义模型名，再额外跑一次：

3. 自定义模型环境变量
   建议标签：`custom-model`

## 给 Claude 的入口

在对应会话里直接让 Claude 读取这份文件：

`tests/api-capability-suite/EXECUTE_WITH_CLAUDE.md`

建议你在提示里补上本次运行标签，例如：

```text
请读取 tests/api-capability-suite/EXECUTE_WITH_CLAUDE.md，并使用 RunLabel=sonnet-baseline 严格执行。
```

## 执行后你要做的两件事

1. 按 `MULTI_TURN_SEQUENCE.md` 逐轮发消息，补测真正的多轮记忆。
2. 去第三方平台后台核对模型、token、计费是否与本次运行标签一致。

这两项都不能只靠 Claude 自己在本地完成，所以 `RUNBOOK.md` 里单独列成了人工核对项。
