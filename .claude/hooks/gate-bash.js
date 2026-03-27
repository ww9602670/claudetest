#!/usr/bin/env node
/**
 * gate-bash.js — Bash 门禁 Hook
 * verifying 状态：白名单模式，只允许 required_checks 中的命令
 * 其他状态：黑名单模式，拦截高危命令
 * 拒绝时：exit 2 + stderr 原因（Claude Code 标准拦截协议）
 * 放行时：exit 0（不写 stdout）
 * 异常时：exit 0 放行（fail-open）
 */

const fs = require('fs');
const path = require('path');

// 项目根目录：从脚本位置（.claude/hooks/）向上两级推算，与 process.cwd() 无关
const PROJECT_ROOT = path.resolve(__dirname, '..', '..');

// 高危命令黑名单
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

function block(msg) {
  process.stderr.write(msg + '\n');
  process.exit(2);
}

function allow() {
  process.exit(0);
}

function findActiveFeatureJson(cwd) {
  const featuresDir = path.join(cwd, 'features');
  if (!fs.existsSync(featuresDir)) return null;

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

      if (toolName !== 'Bash') allow();

      const command = (event.tool_input && event.tool_input.command) || '';
      if (!command) allow();

      const featureJson = findActiveFeatureJson(PROJECT_ROOT);

      if (featureJson && featureJson.status === 'verifying') {
        // 白名单模式：只允许 required_checks 中命令的首个词（命令名）
        const requiredChecks = featureJson.required_checks || [];
        const allowedBins = requiredChecks.map(c => {
          const cmd = (c.command_windows || c.command_bash || '').trim();
          return cmd.split(/\s+/)[0]; // 取命令名，如 "npm"
        }).filter(Boolean);

        const cmdBin = command.trim().split(/\s+/)[0];
        if (!allowedBins.includes(cmdBin)) {
          block(`[gate-bash] verifying 模式：命令 "${command.substring(0, 60)}" 不在 required_checks 白名单中，已拦截。`);
        }
      } else {
        // 黑名单模式
        for (const pattern of DANGEROUS_PATTERNS) {
          if (pattern.test(command)) {
            block(`[gate-bash] 高危命令被拦截: "${command.substring(0, 80)}"`);
          }
        }
      }

      allow();
    } catch (e) {
      // 异常时放行（fail-open）
      allow();
    }
  });
}

main();
