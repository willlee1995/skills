#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { existsSync, readdirSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const require = createRequire(import.meta.url);

function resolveExistingPath(candidate) {
  if (!candidate) return '';
  const resolved = path.resolve(candidate);
  return existsSync(resolved) ? resolved : '';
}

function lookupCommand(command) {
  const binary = process.platform === 'win32' ? 'where' : 'which';
  try {
    const output = execFileSync(binary, [command], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    return output
      .split(/\r?\n/)
      .map(line => line.trim())
      .find(line => line && existsSync(line)) || '';
  } catch {
    return '';
  }
}

function playwrightChromiumPath() {
  for (const packageName of ['playwright', 'playwright-core']) {
    try {
      return resolveExistingPath(require(packageName).chromium.executablePath());
    } catch {
      continue;
    }
  }
  return '';
}

function macChromeCandidates() {
  if (process.platform !== 'darwin') return [];
  return [
    path.join(path.sep, 'Applications', 'Google Chrome.app', 'Contents', 'MacOS', 'Google Chrome'),
    path.join(path.sep, 'Applications', 'Chromium.app', 'Contents', 'MacOS', 'Chromium'),
    path.join(path.sep, 'Applications', 'Microsoft Edge.app', 'Contents', 'MacOS', 'Microsoft Edge'),
  ];
}

export function resolveChromeExecutablePath() {
  if (process.env.CHROME_PATH) {
    return resolveExistingPath(process.env.CHROME_PATH);
  }

  const resolvedByPlaywright = playwrightChromiumPath();
  if (resolvedByPlaywright) return resolvedByPlaywright;

  const commands = process.platform === 'win32'
    ? ['chrome.exe', 'chromium.exe', 'msedge.exe']
    : ['google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser', 'chrome', 'microsoft-edge'];

  for (const command of commands) {
    const resolved = lookupCommand(command);
    if (resolved) return resolved;
  }

  for (const candidate of macChromeCandidates()) {
    const resolved = resolveExistingPath(candidate);
    if (resolved) return resolved;
  }

  return '';
}

export function getChromeExecutablePath() {
  const resolved = resolveChromeExecutablePath();
  if (resolved) return resolved;
  throw new Error(
    'Chrome executable not found. Set CHROME_PATH to a local Chrome/Chromium executable and rerun the validation.',
  );
}

// Playwright 浏览器缓存根目录(按平台;PLAYWRIGHT_BROWSERS_PATH 显式覆盖优先)。
function playwrightCacheRoots() {
  if (process.env.PLAYWRIGHT_BROWSERS_PATH && process.env.PLAYWRIGHT_BROWSERS_PATH !== '0') {
    return [process.env.PLAYWRIGHT_BROWSERS_PATH];
  }
  if (process.platform === 'darwin') return [path.join(os.homedir(), 'Library', 'Caches', 'ms-playwright')];
  if (process.platform === 'win32') return [path.join(os.homedir(), 'AppData', 'Local', 'ms-playwright')];
  return [path.join(os.homedir(), '.cache', 'ms-playwright')];
}

// chromium headless shell:无 ProcessSingleton 的无头专用二进制。沙箱型宿主(如豆包)
// 的 seatbelt 会拦完整版 Chrome 在 confstr 临时目录创建单例锁 socket(报
// "Failed to create a ProcessSingleton"),而 headless shell 没有这套机制,同一沙箱下
// 可正常启动——导出(headless 截图/CDP)场景优先使用它。
export function resolveHeadlessShellPath() {
  const shellBinary = process.platform === 'win32' ? 'chrome-headless-shell.exe' : 'chrome-headless-shell';
  for (const root of playwrightCacheRoots()) {
    let entries;
    try {
      entries = readdirSync(root);
    } catch {
      continue;
    }
    const revisions = entries
      .filter(name => name.startsWith('chromium_headless_shell-'))
      .sort((a, b) => Number(b.split('-')[1] || 0) - Number(a.split('-')[1] || 0));
    for (const revision of revisions) {
      const revisionDir = path.join(root, revision);
      let platformDirs;
      try {
        platformDirs = readdirSync(revisionDir).filter(name => name.startsWith('chrome-headless-shell'));
      } catch {
        continue;
      }
      for (const platformDir of platformDirs) {
        const candidate = path.join(revisionDir, platformDir, shellBinary);
        if (existsSync(candidate)) return candidate;
      }
    }
  }
  return '';
}

// 导出链路的浏览器解析:CHROME_PATH 显式覆盖 > headless shell > 常规完整版链路。
export function getExportBrowserPath() {
  if (process.env.CHROME_PATH) {
    const explicit = resolveExistingPath(process.env.CHROME_PATH);
    if (explicit) return explicit;
  }
  const shell = resolveHeadlessShellPath();
  if (shell) return shell;
  return getChromeExecutablePath();
}
