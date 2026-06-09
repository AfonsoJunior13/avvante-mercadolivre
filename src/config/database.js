const oracledb = require('oracledb');
require('dotenv').config();

// Inicializa o Oracle Client no modo Thick
// Caminho configurado em ORACLE_CLIENT_LIB_DIR no .env
const libDir = process.env.ORACLE_CLIENT_LIB_DIR;

if (!libDir) {
  console.error('Erro: ORACLE_CLIENT_LIB_DIR não definido no .env');
  process.exit(1);
}

try {
  oracledb.initOracleClient({ libDir });
} catch (err) {
  console.error('Erro ao inicializar o Oracle Client:', err);
  process.exit(1);
}

async function getConnection() {
  try {    
    return await oracledb.getConnection({
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      connectString: process.env.DB_CONNECT
    });
  } catch (err) {
    console.error('Erro ao conectar ao banco:', err);
    throw err;
  }
}

module.exports = { getConnection };
