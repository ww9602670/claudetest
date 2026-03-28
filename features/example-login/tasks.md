# 任务清单 — 用户登录

> AI 执行版 | feature-id: example-login

> ⚠️ **占位演示示例**：本目录为第一阶段治理体系的结构演示，任务与完成状态均为演示用途，不对应真实代码执行。真实可运行示例留到后续阶段。

---

- ✅ T-01: 创建 `src/auth/` 目录和文件骨架
  - 修改文件：`src/auth/auth.service.js`、`src/auth/login.controller.js`、`src/auth/auth.router.js`、`src/auth/rate-limiter.js`
  - 验证方法：文件存在，无语法错误

- ✅ T-02: 实现 `auth.service.js` — 密码校验（bcrypt）+ JWT 签发
  - 修改文件：`src/auth/auth.service.js`
  - 验证方法：单元测试 `tests/auth/login.test.js` T-02 用例通过

- ✅ T-03: 实现 `login.controller.js` — 登录/退出控制器
  - 修改文件：`src/auth/login.controller.js`
  - 验证方法：单元测试 T-03 用例通过

- ✅ T-04: 实现 `rate-limiter.js` — IP 限流（5 次锁定 15 分钟）
  - 修改文件：`src/auth/rate-limiter.js`
  - 验证方法：单元测试 T-04 用例通过

- ✅ T-05: 修改 `src/app.js` 挂载 auth router
  - 修改文件：`src/app.js`
  - 影响范围：所有路由（确认无冲突）
  - 验证方法：`npm start` 启动无报错，`POST /api/auth/login` 可访问

- ✅ T-06: 编写测试 `tests/auth/login.test.js`，覆盖 AC-01 到 AC-05
  - 修改文件：`tests/auth/login.test.js`
  - 验证方法：`npm test -- --testPathPattern=auth` 全部通过

---

完成记录：所有任务已完成（示例数据）
