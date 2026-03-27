# ⚠️ 迁移说明：specs/ 已停用为执行态目录

## 状态

`specs/` 目录**不再作为执行态目录**。

新的执行态目录为 `features/`。

## 迁移信息

| 旧 | 新 |
|----|----|
| `specs/<功能>/` | `features/<feature-id>/` |
| `/project:spec` | `/spec` |
| `/project:design` | `/design` |
| `/project:tasks` | `/tasks` |
| `/project:implement` | `/implement` |
| `/project:verify` | `/verify` |

## 详细迁移步骤

见 `docs/spec-system/迁移说明.md`

## 本目录现状

本目录保留为**历史归档**。如有已有功能文档，请参考迁移说明迁移到 `features/`。

**禁止**在此目录下创建新功能目录。
