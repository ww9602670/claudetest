# 技术设计 — 网页版贪食蛇游戏

> AI 执行版 | feature-id: snake-game
> 
> **设计目标**: 使用简单可行的技术方案验证 spec 驱动开发机制

---

## 设计概述

采用纯前端技术栈（HTML/CSS/JavaScript）实现单页面贪食蛇游戏，使用 Canvas API 进行图形渲染，通过 `requestAnimationFrame` 实现游戏循环，使用二维数组存储游戏状态。整体方案简洁、无外部依赖、易于理解和维护。

---

## 架构决策

### 方案选择

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 纯 HTML/CSS/JS + Canvas | 简单、无依赖、易部署 | 不适合复杂游戏 | **选用** |
| HTML5 游戏引擎（Phaser） | 功能强大、易扩展 | 引入复杂依赖、过度设计 | 放弃 |
| React + Canvas | 组件化、状态管理 | 需要构建工具、增加复杂度 | 放弃 |
| 纯 DOM 操作 | 简单易懂 | 性能较差、不适合频繁渲染 | 放弃 |

**选用方案说明**: 
- 验证机制优先，不需要复杂技术栈
- 单文件即可运行，便于部署和测试
- 代码结构清晰，便于 non-programmer 理解
- 符合"简单可行"原则

---

## 数据结构设计

### 核心数据结构

```javascript
// 游戏配置
const config = {
  gridSize: 20,        // 网格大小（像素）
  tileCount: 20,       // 网格数量
  initialSpeed: 150,   // 初始速度（毫秒/帧）
  speedIncrement: 5,   // 每次吃食物后速度提升量
  minSpeed: 50         // 最快速度限制
};

// 游戏状态
const gameState = {
  snake: [],           // 蛇身坐标数组 [{x, y}, ...]
  food: {x, y},       // 食物坐标
  direction: {x, y},  // 当前移动方向
  nextDirection: {x, y}, // 下一帧的移动方向（防止快速按键bug）
  score: 0,           // 当前得分
  speed: 150,         // 当前速度
  isGameOver: false,  // 游戏是否结束
  isPaused: false     // 是否暂停（可选）
};
```

### 状态机设计

```
[初始化] → [游戏进行中] → [游戏结束] → [重新开始] → [游戏进行中]
            ↓
         [暂停状态]（可选）
```

---

## 核心算法设计

### 1. 游戏主循环

```javascript
function gameLoop() {
  if (gameState.isGameOver) return;
  
  // 更新方向（防止快速按键导致掉头）
  gameState.direction = gameState.nextDirection;
  
  // 计算新的蛇头位置
  const newHead = {
    x: gameState.snake[0].x + gameState.direction.x,
    y: gameState.snake[0].y + gameState.direction.y
  };
  
  // 碰撞检测
  if (checkCollision(newHead)) {
    gameOver();
    return;
  }
  
  // 移动蛇
  gameState.snake.unshift(newHead);
  
  // 检测是否吃到食物
  if (newHead.x === gameState.food.x && newHead.y === gameState.food.y) {
    eatFood();
  } else {
    gameState.snake.pop(); // 没吃到食物，移除蛇尾
  }
  
  // 渲染画面
  render();
  
  // 安排下一帧
  setTimeout(() => requestAnimationFrame(gameLoop), gameState.speed);
}
```

### 2. 碰撞检测算法

```javascript
function checkCollision(head) {
  // 检测撞墙
  if (head.x < 0 || head.x >= config.tileCount || 
      head.y < 0 || head.y >= config.tileCount) {
    return true;
  }
  
  // 检测撞到自己
  for (let segment of gameState.snake) {
    if (head.x === segment.x && head.y === segment.y) {
      return true;
    }
  }
  
  return false;
}
```

### 3. 食物生成算法

```javascript
function generateFood() {
  let food;
  do {
    food = {
      x: Math.floor(Math.random() * config.tileCount),
      y: Math.floor(Math.random() * config.tileCount)
    };
  } while (isOnSnake(food)); // 确保食物不在蛇身上
  
  return food;
}
```

---

## 文件结构设计

### 方案A：单文件实现（推荐）

```
features/snake-game/
├── index.html          # 包含 HTML、CSS、JavaScript 的单文件
└── README.md           # 项目说明
```

**优点**: 结构最简单、易于部署、便于理解  
**缺点**: 文件较大时不易维护

### 方案B：多文件实现

```
features/snake-game/
├── index.html          # HTML 结构
├── style.css           # 样式
├── game.js             # 游戏逻辑
└── README.md           # 项目说明
```

**优点**: 代码分离、结构清晰  
**缺点**: 文件较多、部署时需要同步

**结论**: 优先采用方案A（单文件），如果代码超过500行可考虑拆分为方案B。

---

## 用户界面设计

### 页面布局

```
┌─────────────────────────────────────┐
│         贪食蛇游戏                  │
├─────────────────────────────────────┤
│  得分: 0                            │
├─────────────────────────────────────┤
│                                     │
│         [游戏画布 400x400]          │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  使用方向键控制移动                 │
│  撞墙或撞到自己游戏结束             │
└─────────────────────────────────────┘
```

### 游戏结束界面

```
┌─────────────────────────────────────┐
│         游戏结束                    │
├─────────────────────────────────────┤
│  最终得分: 120                      │
│                                     │
│     [重新开始] [关闭]               │
└─────────────────────────────────────┘
```

### 视觉风格

- 背景色: 浅灰色 (#f0f0f0)
- 游戏区域: 白色背景 (#ffffff)
- 蛇身: 绿色 (#4CAF50)
- 蛇头: 深绿色 (#2E7D32)
- 食物: 红色 (#F44336)
- 文字: 黑色 (#000000)
- 按钮: 蓝色 (#2196F3)

---

## 技术实现要点

### 1. Canvas 渲染优化

- 使用 `requestAnimationFrame` 保证流畅动画
- 只在状态变化时重新渲染
- 使用网格坐标系统简化计算

### 2. 按键响应优化

- 使用 `nextDirection` 缓冲下一次方向，防止快速按键导致蛇掉头
- 忽略与当前方向相反的按键（防止直接掉头）

### 3. 速度控制实现

- 使用 `setTimeout` 控制帧间隔时间
- 每次吃食物后减少间隔时间（提高速度）
- 设置最小速度限制，防止过快无法操作

### 4. 响应式设计（可选）

- 如果屏幕较小，自动调整画布大小
- 保持网格比例不变

---

## 测试策略

### 单元测试（可选）

- 碰撞检测函数测试
- 食物生成函数测试
- 坐标计算测试

### 手动测试清单

1. 基本移动测试
   - 按上键，蛇向上移动
   - 按下键，蛇向下移动
   - 按左键，蛇向左移动
   - 按右键，蛇向右移动

2. 吃食物测试
   - 蛇移动到食物位置，得分增加
   - 蛇身增长
   - 新食物随机出现

3. 碰撞测试
   - 蛇撞墙，游戏结束
   - 蛇撞自己，游戏结束

4. 速度测试
   - 初始速度适中
   - 吃到食物后速度提升
   - 速度提升有明显感受

5. 重新开始测试
   - 游戏结束后点击重新开始，游戏重置

---

## 性能考虑

| 指标 | 目标值 | 实现方式 |
|------|--------|---------|
| 首次加载时间 | < 2秒 | 单文件、无外部依赖 |
| 按键响应延迟 | < 100ms | 使用键盘事件监听 |
| 帧率 | 60fps | requestAnimationFrame |
| 内存占用 | < 10MB | 简单数据结构 |

---

## 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 快速按键导致蛇掉头bug | 中 | 高 | 使用 nextDirection 缓冲 |
| 速度过快无法操作 | 中 | 中 | 设置最小速度限制 |
| 浏览器兼容性问题 | 低 | 低 | 使用标准 Canvas API |
| 性能问题 | 低 | 低 | 简单渲染逻辑、无复杂计算 |

---

## 后续扩展方向（非本次范围）

- 添加关卡系统
- 添加障碍物
- 添加特殊道具（加速、减速、穿墙）
- 添加音效
- 移动端适配
- 在线排行榜

**注意**: 本次任务不实现这些扩展，仅作为未来可能的方向记录。
