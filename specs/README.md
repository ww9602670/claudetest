# Specs 文档库

本目录存放所有功能的 Spec 驱动开发文档。

## 目录结构

```
specs/
├── <功能名>/
│   ├── spec.md          ← 需求规格（/project:spec 生成）
│   ├── design.md        ← 技术设计（/project:design 生成）
│   ├── tasks.md         ← 任务清单（/project:tasks 生成）
│   └── verify.md        ← 验收报告（/project:verify 生成）
```

## 工作流

```
/project:spec <需求描述>
    ↓
/project:design <功能名>
    ↓
/project:tasks <功能名>
    ↓
/project:implement <功能名>  （可多次执行，断点续做）
    ↓
/project:verify <功能名>
```
