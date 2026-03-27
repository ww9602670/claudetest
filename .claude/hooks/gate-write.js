#!/usr/bin/env node
/**
 * gate-write.js — 写入门禁 Hook
 * 覆盖：Edit | MultiEdit | Write
 * 检查：feature.json 状态、批准协议、allowed_paths/forbidden_paths
 * 拒绝时：exit 2 + stderr 原因（Claude Code 标准拦截协议）
 * 放行时：exit 0（不写 stdout）
 * 异常时：exit 0 放行（fail-open）
 */

const fs = require('fs');
const path = require('path');

function block(msg) {
  process.stderr.write(msg + '\n');
  process.exit(2);
}

function allow() {
  process.exit(0);
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
        allow();
      }

      const filePath = event.tool_input && (event.tool_input.file_path || event.tool_input.path || '');
      if (!filePath) allow();

      // 检查是否在 features/ 目录下
      const normalized = filePath.replace(/\/g, '/');
      if (!normalized.includes('/features/')) allow();

      // 提取 feature-id
      const match = normalized.match(/features\/([^\/]+)\//);
      if (!match) allow();
      const featureId = match[1];

      // 查找 feature.json
      const featureJsonPath = path.join(process.cwd(), 'features', featureId, 'feature.json');
      if (!fs.existsSync(featureJsonPath)) allow(); // feature.json 不存在时放行

      const featureJson = JSON.parse(fs.readFileSync(featureJsonPath, 'utf8'));
      const status = featureJson.status || '';

      // 状态检查：未 approved 时禁止写入
      const allowedStatuses = ['approved', 'implementing', 'verifying'];
      if (!allowedStatuses.includes(status)) {
        block(`[gate-write] 拒绝写入: feature "${featureId}" 当前状态为 "${status}"，须达到 approved 才能修改文件。`);
      }

      // 批准协议检查
      if (status === 'implementing' || status === 'verifying') {
        if (!featureJson.approved_by || !featureJson.approved_at || !featureJson.phase_gate_approved) {
          block(`[gate-write] 拒绝写入: feature "${featureId}" 缺少批准信息 (approved_by/approved_at/phase_gate_approved)。`);
        }
      }

      // allowed_paths 检查
      const allowedPaths = featureJson.allowed_paths || [];
      if (allowedPaths.length > 0) {
        const isAllowed = allowedPaths.some(ap => normalized.includes(ap.replace(/\/g, '/')));
        if (!isAllowed) {
          block(`[gate-write] 拒绝写入: "${filePath}" 不在 allowed_paths 列表中。`);
        }
      }

      // forbidden_paths 检查
      const forbiddenPaths = featureJson.forbidden_paths || [];
      for (const fp of forbiddenPaths) {
        if (normalized.includes(fp.replace(/\/g, '/'))) {
          block(`[gate-write] 拒绝写入: "${filePath}" 命中 forbidden_paths。`);
        }
      }

      // 通过所有检查
      allow();
    } catch (e) {
      // 异常时放行（fail-open）
      allow();
    }
  });
}

main();
