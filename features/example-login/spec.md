# 需求规格 — 用户登录

> AI 执行版 | feature-id: example-login

---

## 功能概述

实现基于邮箱+密码的用户认证，支持 7 天 Remember Me，使用 JWT 令牌管理会话。

---

## 需求范围

### In Scope

- FR-01: POST /api/auth/login，接受 email/password/remember 参数
- FR-02: 密码校验（bcrypt）
- FR-03: 登录成功返回 JWT，remember=true 时 expires 7d，否则 24h
- FR-04: POST /api/auth/logout，清除令牌
- NFR-01: 登录接口响应时间 < 500ms
- NFR-02: 密码错误次数 > 5 时锁定 IP 15 分钟

### Out of Scope

- 第三方 OAuth 登录
- 用户注册、密码找回
- 现有权限中间件修改

---

## 成功标准

- AC-01: 正确邮箱+密码返回 200 和 JWT
- AC-02: 错误密码返回 401，body 含 `{ error: "邮箱或密码错误" }`
- AC-03: remember=true 时 JWT expires 7 天
- AC-04: logout 后令牌失效，再次请求返回 401
- AC-05: 5 次失败后第 6 次返回 429

---

## 依赖与约束

- 依赖：User 模型（已存在）、bcrypt、jsonwebtoken
- 禁止修改：`src/core/`、`config/production/`
