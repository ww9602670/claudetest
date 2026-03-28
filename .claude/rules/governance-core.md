# 治理核心规则

全局生效，无路径限制。

## 状态机约束

feature.json 的 `status` 字段必须严格遵循以下顺序流转：

```
draft → review → approved → implementing → verifying → done | blocked
```

- 禁止跳跃状态（如从 draft 直接到 implementing）
- 禁止 AI 自动推进状态，每次状态变更必须人工确认
- `blocked` 状态需在 feature.json 的 `block_reason` 字段说明原因

## 批准协议

进入 `implementing` 状态的前置条件：

1. `status` 必须为 `approved`
2. `approved_by` 字段不得为空
3. `approved_at` 字段为有效 ISO 时间戳
4. `approved_method` 字段标明批准方式（human / auto-gate）
5. `phase_gate_approved` 为 `true`

## 单一事实源

- `feature.json` 是功能状态的唯一权威来源
- 禁止在 auto memory 中写入治理状态作为执行依据
- 禁止使用 `feature.yaml`，只允许 `feature.json`

## 阶段闸门

- 第一阶段完成后不得自动进入第二阶段
- 阶段切换必须人工确认
- AI 在完成当前阶段后必须停止并等待指令

---

## 执行层级标注

| 约束项 | 层级 | 执行机制 |
|--------|------|----------|
| 状态机顺序流转（禁止跳跃） | 生效层 | AI 自觉遵守 |
| 禁止 AI 自动推进状态 | 生效层 | AI 自觉遵守 |
| blocked 需说明 block_reason | 生效层 | AI 自觉遵守 |
| approved_by 不得为空 | 硬拦截层 | gate-write.js 在 approved/implementing/verifying 状态下检查 |
| approved_at 为有效时间戳 | 硬拦截层 | gate-write.js 在 approved/implementing/verifying 状态下检查（含 ISO 格式校验） |
| approved_method 不得为空 | 硬拦截层 | gate-write.js 在 approved/implementing/verifying 状态下检查 |
| phase_gate_approved 为 true | 硬拦截层 | gate-write.js 在 approved/implementing/verifying 状态下检查 |
| feature.json 是唯一状态源 | 生效层 | AI 自觉遵守 |
| 禁止 feature.yaml | 生效层 | AI 自觉遵守 |
| 阶段切换必须人工确认 | 生效层 | AI 自觉遵守 + feature.json phase_gate_approved 字段控制 |
