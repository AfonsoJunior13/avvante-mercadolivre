const fs = require('fs');
const path = require('path');
const util = require('util');

const ERROR_DIR = path.join(__dirname, '..', '..', 'logs', 'error');

function getErrorLogFilePath(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return path.join(ERROR_DIR, `${y}${m}${d}.logError`);
}

function formatTime(date = new Date()) {
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  const s = String(date.getSeconds()).padStart(2, '0');
  return `${h}:${min}:${s}`;
}

function formatErrorMessage(value) {
  if (value instanceof Error) {
    return value.stack || value.message;
  }
  if (typeof value === 'object' && value !== null) {
    return util.inspect(value, { depth: null, colors: false });
  }
  return String(value);
}

function writeErrorLog(content) {
  try {
    if (!fs.existsSync(ERROR_DIR)) {
      fs.mkdirSync(ERROR_DIR, { recursive: true });
    }

    const now = new Date();
    const line = `${formatTime(now)} ${content}\n\n`;
    fs.appendFileSync(getErrorLogFilePath(now), line, 'utf8');
  } catch (_) {
    // não interrompe a execução se falhar a gravação
  }
}

function logError(error) {
  writeErrorLog(formatErrorMessage(error));
}

function logErrorArgs(args) {
  const content = args.map(formatErrorMessage).join(' ');
  writeErrorLog(content);
}

module.exports = { logError, logErrorArgs, getErrorLogFilePath };
