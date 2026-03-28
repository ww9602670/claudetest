#!/usr/bin/env node
/**
 * evidence-write.js — PostToolUse 证据沉淀 Hook（写入类）
 * 覆盖：Edit | MultiEdit | Write
 * 功能：在活跃 feature 的 evidence/change-summary.md 中追加变更记录
 * 本 hook 为 PostToolUse，不拦截操作，仅记录证据
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..', '..');

function findActiveFeature(cwd) {
  const featuresDir = path.join(cwd, 'features');
  if (!fs.existsSync(featuresDir)) return null;
  try {
    const dirs = fs.readdirSync(featuresDir);
    for (const dir of dirs) {
      const jsonPath = path.join(featuresDir, dir, 'feature.json');
      if (fs.existsSync(jsonPath)) {
        try {
          const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
          if (['implementing', 'verifying'].includes(data.status)) {
            return { id: dir, data: data };
          }
        } catch (e) { /* skip */ }
      }
    }
  } catch (e) { /* skip */ }
  return null;
}

function main() {
  let input = '';
  process.stdin.on('data', chunk => { input += chunk; });
  process.stdin.on('end', () => {
    try {
      const event = JSON.parse(input);
      const toolName = event.tool_name || '';

      // 只处理写入类工具
      if (toolName !== 'Edit' && toolName !== 'MultiEdit' && toolName !== 'Write') {
        process.exit(0);
        return;
      }

      const feature = findActiveFeature(PROJECT_ROOT);
      if (!feature) {
        process.exit(0);
        return;
      }

      const filePath = (event.tool_input && (event.tool_input.file_path || event.tool_input.path)) || '(unknown)';
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      const evidenceDir = path.join(PROJECT_ROOT, 'features', feature.id, 'evidence');

      // 确保 evidence 目录存在
      if (!fs.existsSync(evidenceDir)) {
        fs.mkdirSync(evidenceDir, { recursive: true });
      }

      const summaryPath = path.join(evidenceDir, 'change-summary.md');

      // 如果文件不存在，写入标题
      if (!fs.existsSync(summaryPath)) {
        fs.writeFileSync(summaryPath, '# 变更摘要记录\n\n由 PostToolUse(evidence-write) 自动生成。\n\n---\n\n', 'utf8');
      }

      // 追加记录
      const record = `- **${timestamp}** | \`${toolName}\` | \`${filePath}\`\n`;
      fs.appendFileSync(summaryPath, record, 'utf8');

    } catch (e) {
      // PostToolUse 不拦截，静默失败
    }
    process.exit(0);
  });
}

main();
