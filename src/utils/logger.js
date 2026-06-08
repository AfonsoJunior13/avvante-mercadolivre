const fs = require('fs');
const path = require('path');

function logError(error) {
  const filePath = path.join(__dirname, '..', 'error.log');
  const logMessage = `[${new Date().toISOString()}] ${error.stack || error}\n\n`;
  fs.appendFileSync(filePath, logMessage, 'utf8');
}

module.exports = { logError };