const fs = require('fs');
const path = require('path');
const util = require('util');
const { logErrorArgs } = require('./logger');

const LOG_DIR = path.join(__dirname, '..', '..', 'logs', 'exec');

const originalConsole = {
  log: console.log.bind(console),
  error: console.error.bind(console),
  warn: console.warn.bind(console),
  info: console.info.bind(console),
};

function getLogFilePath(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return path.join(LOG_DIR, `${y}${m}${d}.log`);
}

function formatTime(date = new Date()) {
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  const s = String(date.getSeconds()).padStart(2, '0');
  return `${h}:${min}:${s}`;
}

function formatMessage(args) {
  return args
    .map((arg) => {
      if (arg instanceof Error) {
        return arg.stack || arg.message;
      }
      if (typeof arg === 'object' && arg !== null) {
        return util.inspect(arg, { depth: null, colors: false });
      }
      return String(arg);
    })
    .join(' ');
}

function writeExecLog(args) {
  try {
    if (!fs.existsSync(LOG_DIR)) {
      fs.mkdirSync(LOG_DIR, { recursive: true });
    }

    const now = new Date();
    const line = `${formatTime(now)} ${formatMessage(args)}\n`;
    fs.appendFileSync(getLogFilePath(now), line, 'utf8');
  } catch (_) {
    // não interrompe a execução se falhar a gravação
  }
}

function wrapConsole(method, originalFn) {
  console[method] = (...args) => {
    writeExecLog(args);
    originalFn(...args);
  };
}

wrapConsole('log', originalConsole.log);
wrapConsole('warn', originalConsole.warn);
wrapConsole('info', originalConsole.info);

console.error = (...args) => {
  writeExecLog(args);
  logErrorArgs(args);
  originalConsole.error(...args);
};

module.exports = { getLogFilePath, writeExecLog };
