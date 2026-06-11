const fs = require('fs');
const path = require('path');

const ENV_DIR = path.join(__dirname, '..', '..', 'logs', 'json', 'env');
const REC_DIR = path.join(__dirname, '..', '..', 'logs', 'json', 'rec');

const SENSITIVE_KEYS = [
  'client_secret',
  'mlcn_client_secret',
  'mlcn_token',
  'mlcn_access_token',
  'refresh_token',
  'access_token',
  'authorization',
  'code',
  'mlcn_code',
  'password',
  'code_verifier',
];

function getTimestamp(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  const s = String(date.getSeconds()).padStart(2, '0');
  return `${y}${m}${d}${h}${min}${s}`;
}

function sanitizeRotina(rotina) {
  return String(rotina).replace(/[^a-zA-Z0-9_-]/g, '_');
}

function getUniqueFilePath(dir, rotina, date = new Date()) {
  const base = `${getTimestamp(date)}_${sanitizeRotina(rotina)}`;
  let filePath = path.join(dir, `${base}.json`);
  let counter = 1;

  while (fs.existsSync(filePath)) {
    filePath = path.join(dir, `${base}_${counter}.json`);
    counter += 1;
  }

  return filePath;
}

function maskValue(value) {
  if (typeof value !== 'string' || value.length === 0) {
    return '***';
  }
  if (value.length <= 8) {
    return '***';
  }
  return `${value.slice(0, 4)}...${value.slice(-4)}`;
}

function maskSensitive(data) {
  if (data === null || data === undefined) {
    return data;
  }

  if (Array.isArray(data)) {
    return data.map(maskSensitive);
  }

  if (typeof data !== 'object') {
    return data;
  }

  const masked = {};

  for (const [key, value] of Object.entries(data)) {
    const keyLower = key.toLowerCase();

    if (SENSITIVE_KEYS.some((item) => keyLower.includes(item))) {
      masked[key] = maskValue(String(value));
    } else if (typeof value === 'object') {
      masked[key] = maskSensitive(value);
    } else {
      masked[key] = value;
    }
  }

  return masked;
}

function writeJson(dir, rotina, data) {
  try {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const payload = maskSensitive(data);
    const content = JSON.stringify(payload, null, 2);
    fs.writeFileSync(getUniqueFilePath(dir, rotina), content, 'utf8');
  } catch (_) {
    // não interrompe a execução se falhar a gravação
  }
}

function logJsonEnv(rotina, data) {
  writeJson(ENV_DIR, rotina, data);
}

function logJsonRec(rotina, data) {
  writeJson(REC_DIR, rotina, data);
}

module.exports = { logJsonEnv, logJsonRec };
