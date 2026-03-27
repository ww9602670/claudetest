# 技术设计 — 用户登录

> AI 执行版 | feature-id: example-login

---

## 设计概述

新增 `src/auth/` 模块，实现 JWT 认证。不修改现有中间件，通过新增路由挂载。

---

## 架构决策

选用 JWT（无状态令牌）方案，避免引入 Redis 依赖。Remember Me = 7d exp，否则 24h exp。

---

## 文件变更清单

| 路径 | 操作 | 说明 |
|------|------|------|
| `src/auth/login.controller.js` | 新增 | 登录/登出控制器 |
| `src/auth/auth.service.js` | 新增 | 认证业务逻辑（密码校验、JWT 签发） |
| `src/auth/auth.router.js` | 新增 | 路由定义 |
| `src/auth/rate-limiter.js` | 新增 | IP 限流（5 次失败锁定） |
| `src/app.js` | 修改 | 挂载 auth router |
| `tests/auth/login.test.js` | 新增 | 单元测试 |

---

## API 设计

```
POST /api/auth/login
Body: { email, password, remember? }
200: { token, expires_at }
401: { error: "邮箱或密码错误" }
429: { error: "登录尝试过多，请 15 分钟后重试" }

POST /api/auth/logout
Header: Authorization: Bearer <token>
200: { message: "已退出登录" }
```
