#!/usr/bin/env node
/**
 * gate-bash.js — Bash 门禁 Hook
 * verifying 状态：白名单模式，只允许 required_checks 中的命令
 * 其他状态：黑名单模式，拦截高危命令
 * 异常时 exit 0 放行（fail-open）
 */

const fs = require('fs');
const path = require('path');

// 高危命令黑名单（黑名单模式下拦截）
const DANGEROUS_PATTERNS = [
  /rm\s+-rf\s+[\/~]/,
  /git\s+push\s+--force/,
  /git\s+reset\s+--hard/,
  /DROP\s+TABLE/i,
  /TRUNCATE\s+TABLE/i,
  /DELETE\s+FROM\s+\w+\s*;?\s*$/i,
  />\s*\/dev\/sda/,
  /mkfs\./,
  /dd\s+if=.*of=\/dev/,
];

function findFeatureJson(cwd) {
  // 尝试从 CWD 向上找 feature.json
  const featuresDir = path.join(cwd, 'features');
  if (!fs.existsSync(featuresDir)) return null;

  // 读取所有 feature 目录，返回第一个 implementing/verifying 状态的
  const dirs = fs.readdirSync(featuresDir);
  for (const dir of dirs) {
    const jsonPath = path.join(featuresDir, dir, 'feature.json');
    if (fs.existsSync(jsonPath)) {
      try {
        const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
        if (data.status === 'verifying' || data.status === 'implementing') {
          return data;
        }
      } catch (e) {}
    }
  }
  return null;
}

function main() {
  let input = '';
  process.stdin.on('data', chunk => { input += chunk; });
  process.stdin.on('end', () => {
    try {
      const event = JSON.parse(input);
      const toolName = event.tool_name || '';

      if (toolName !== 'Bash') {
        process.exit(0);
      }

      const command = (event.tool_input && event.tool_input.command) || '';
      if (!command) process.exit(0);

      const cwd = process.cwd();
      const featureJson = findFeatureJson(cwd);

      if (featureJson && featureJson.status === 'verifying') {
        // 白名单模式：只允许 required_checks 中的命令
        const requiredChecks = featureJson.required_checks || [];
        const allowedCommands = requiredChecks.map(c => {
          // 优先 command_windows，其次 command_bash
          return (c.command_windows || c.command_bash || '').trim();
        }).filter(Boolean);

        const isAllowed = allowedCommands.some(ac => command.trim().startsWith(ac.split(' ')[0]));
        if (!isAllowed) {
          const msg = `[gate-bash] verifying 模式：命令 "${command.substring(0, 50)}" 不在 required_checks 白名单中，已拦截。`;
          process.stderr.write(msg + '\n');
          process.stdout.write(JSON.stringify({ decision: 'block', reason: msg }));
          process.exit(0);
        }
      } else {
        // 黑名单模式
        for (const pattern of DANGEROUS_PATTERNS) {
          if (pattern.test(command)) {
            const msg = `[gate-bash] 高危命令被拦截: "${command.substring(0, 80)}"`;
            process.stderr.write(msg + '\n');
            process.stdout.write(JSON.stringify({ decision: 'block', reason: msg }));
            process.exit(0);
          }
        }
      }

      process.exit(0);
    } catch (e) {
      // 异常时放行
      process.exit(0);
    }
  });
}

main();
