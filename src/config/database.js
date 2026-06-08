const oracledb = require('oracledb');
require('dotenv').config();

// Inicializa o Oracle Client no modo Thick
// Ajuste o caminho abaixo para onde você instalou o Instant Client
try {  
  oracledb.initOracleClient({ libDir: 'C:\\app\\client\\product\\21.0.0\\client_1\\bin' });
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
