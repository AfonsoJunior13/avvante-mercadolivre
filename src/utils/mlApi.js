const axios = require('axios');
const { logJsonEnv, logJsonRec } = require('./jsonLogger');

function sanitizeHeaders(headers = {}) {
  const copy = { ...headers };

  if (copy.Authorization) {
    copy.Authorization = maskAuthorization(copy.Authorization);
  }

  return copy;
}

function maskAuthorization(value) {
  const text = String(value);
  if (!text.startsWith('Bearer ')) {
    return maskValue(text);
  }

  return `Bearer ${maskValue(text.slice(7))}`;
}

function maskValue(value) {
  if (typeof value !== 'string' || value.length <= 8) {
    return '***';
  }

  return `${value.slice(0, 4)}...${value.slice(-4)}`;
}

function parseFormBody(data) {
  if (typeof data !== 'string') {
    return data;
  }

  return Object.fromEntries(
    data.split('&').map((pair) => {
      const [key, value = ''] = pair.split('=');
      return [decodeURIComponent(key), decodeURIComponent(value)];
    })
  );
}

async function get(rotina, url, config = {}) {
  logJsonEnv(rotina, {
    method: 'GET',
    url,
    headers: sanitizeHeaders(config.headers),
    params: config.params || null,
  });

  try {
    const response = await axios.get(url, config);
    logJsonRec(rotina, response.data);
    return response;
  } catch (error) {
    logJsonRec(rotina, error.response?.data || { error: error.message });
    throw error;
  }
}

async function request(rotina, config) {
  logJsonEnv(rotina, {
    method: config.method,
    url: config.url,
    headers: sanitizeHeaders(config.headers),
    data: parseFormBody(config.data),
  });

  try {
    const response = await axios.request(config);
    logJsonRec(rotina, response.data);
    return response;
  } catch (error) {
    logJsonRec(rotina, error.response?.data || { error: error.message });
    throw error;
  }
}

module.exports = { get, request };
