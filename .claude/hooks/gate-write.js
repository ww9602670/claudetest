#!/usr/bin/env node
/**
 * gate-write.js — 写入门禁 Hook
 * 覆盖：Edit | MultiEdit | Write
 * 逻辑：
 *   - 豁免路径（.claude/ docs/ specs/ features/ 下的文档区）直接放行
 *   - 其余路径（业务代码，如 src/）：必须存在活跃 feature，且目标路径在其 allowed_paths 内
 * 拒绝时：exit 2 + stderr 原因
 * 放行时：exit 0
 * 异常时：exit 2（fail-closed，防止异常被利用绕过闸门）
 */

const fs = require('fs');
const path = require('path');

// 豁免前缀：这些路径下的写入不受门禁（治理配置、文档、specs 历史归档）
const EXEMPT_PREFIXES = [
  '.claude/',
  'docs/',
  'specs/',
  'features/',
  'CLAUDE.md',
];

function block(msg) {
  process.stderr.write(msg + '\n');
  process.exitCode = 2;
}

function allow() {
  process.exitCode = 0;
}

function normalizePath(p) {
  if (!p) return '';
  return p.split(path.sep).join('/').replace(/^[A-Za-z]:\//, '/');
}

function isExempt(normalizedRelPath) {
  return EXEMPT_PREFIXES.some(prefix => normalizedRelPath.startsWith(prefix));
}

// 项目根目录：从脚本位置（.claude/hooks/）向上两级推算，与 process.cwd() 无关
const PROJECT_ROOT = path.resolve(__dirname, '..', '..');

function findActiveFeatureJson(cwd) {
  const featuresDir = path.join(cwd, 'features');
  if (!fs.existsSync(featuresDir)) return null;
  try {
    const dirs = fs.readdirSync(featuresDir);
    for (const dir of dirs) {
      const jsonPath = path.join(featuresDir, dir, 'feature.json');
      if (fs.existsSync(jsonPath)) {
        try {
          const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
          const activeStatuses = ['approved', 'implementing', 'verifying'];
          if (activeStatuses.includes(data.status)) return data;
        } catch (e) { /* 单个 feature.json 解析失败，继续检查下一个 */ }
      }
    }
  } catch (e) { /* 读取目录失败 */ }
  return null;
}

function handleEvent(event) {
  const toolName = event.tool_name || '';

  // 非写入工具直接放行
  if (toolName !== 'Edit' && toolName !== 'MultiEdit' && toolName !== 'Write') {
    allow();
    return;
  }

  // 提取目标文件路径
  const absFilePath = event.tool_input && (event.tool_input.file_path || event.tool_input.path || '');
  if (!absFilePath) {
    allow();
    return;
  }

  const cwd = PROJECT_ROOT;
  const normalizedAbs = normalizePath(absFilePath);
  const normalizedCwd = normalizePath(cwd);

  // 计算相对路径
  let relPath = normalizedAbs;
  if (normalizedCwd && relPath.startsWith(normalizedCwd + '/')) {
    relPath = relPath.slice(normalizedCwd.length + 1);
  } else if (normalizedCwd && relPath.startsWith(normalizedCwd)) {
    relPath = relPath.slice(normalizedCwd.length).replace(/^\//, '');
  }

  // 豁免路径直接放行
  if (isExempt(relPath)) {
    allow();
    return;
  }

  // 业务代码路径：必须有活跃 feature 且路径在 allowed_paths 内
  const featureJson = findActiveFeatureJson(cwd);

  if (!featureJson) {
    block('[gate-write] 拒绝写入: "' + relPath + '" 属于业务代码路径，但当前无处于 approved/implementing/verifying 状态的 feature。');
    return;
  }

  const status = featureJson.status;
  const featureId = featureJson.feature_id || '(unknown)';

  // 批准协议检查：approved / implementing / verifying 三个状态都强校验
  if (status === 'approved' || status === 'implementing' || status === 'verifying') {
    if (!featureJson.approved_by) {
      block('[gate-write] 拒绝写入: feature "' + featureId + '" 缺少 approved_by 字段。');
      return;
    }
    if (!featureJson.approved_at) {
      block('[gate-write] 拒绝写入: feature "' + featureId + '" 缺少 approved_at 字段。');
      return;
    }
    // approved_at 时间格式校验：必须为有效 ISO 8601 时间戳
    var parsedTime = Date.parse(featureJson.approved_at);
    if (isNaN(parsedTime)) {
      block('[gate-write] 拒绝写入: feature "' + featureId + '" 的 approved_at 不是有效的 ISO 时间戳: "' + featureJson.approved_at + '"。');
      return;
    }
    if (!featureJson.phase_gate_approved) {
      block('[gate-write] 拒绝写入: feature "' + featureId + '" 的 phase_gate_approved 不为 true。');
      return;
    }
    // approved_method 校验：治理规则要求存在
    if (!featureJson.approved_method) {
      block('[gate-write] 拒绝写入: feature "' + featureId + '" 缺少 approved_method 字段（治理规则要求标明批准方式）。');
      return;
    }
  }

  // allowed_paths 检查
  const allowedPaths = featureJson.allowed_paths || [];
  const isAllowed = allowedPaths.some(function(ap) {
    var normalizedAp = ap.split(path.sep).join('/');
    return relPath.startsWith(normalizedAp) || normalizedAbs.includes(normalizedAp);
  });
  if (!isAllowed) {
    block('[gate-write] 拒绝写入: "' + relPath + '" 不在 feature "' + featureId + '" 的 allowed_paths 列表中。');
    return;
  }

  // forbidden_paths 检查
  var forbiddenPaths = featureJson.forbidden_paths || [];
  for (var i = 0; i < forbiddenPaths.length; i++) {
    var normalizedFp = forbiddenPaths[i].split(path.sep).join('/');
    if (relPath.startsWith(normalizedFp) || normalizedAbs.includes(normalizedFp)) {
      block('[gate-write] 拒绝写入: "' + relPath + '" 命中 feature "' + featureId + '" 的 forbidden_paths。');
      return;
    }
  }

  // 全部检查通过
  allow();
}

function main() {
  // 默认 fail-closed：如果脚本异常退出，拒绝放行
  process.exitCode = 2;

  var input = '';
  process.stdin.on('data', function(chunk) { input += chunk; });
  process.stdin.on('end', function() {
    try {
      var event = JSON.parse(input);
      handleEvent(event);
    } catch (e) {
      // JSON 解析失败或其他异常：fail-closed
      process.stderr.write('[gate-write] 异常: ' + e.message + '\n');
      block('[gate-write] 因异常拒绝放行（fail-closed）');
    }
  });
}

main();
