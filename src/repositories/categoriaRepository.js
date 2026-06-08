const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const oracledb = require('oracledb');

async function categoriaUpdate(data) {
  
  const connection = await getConnection();

  try {
    for (const item of data) {
        await connection.execute(
        `BEGIN PRC_MLAPI_CATEGORIA_UPDATE(:P_MLCA_ID, :P_MLCA_NAME, :P_TRANSACTION); END;`,
        {
            P_MLCA_ID: item.id,        
            P_MLCA_NAME: item.name,
            P_TRANSACTION: 0
        }
        );
    }
    return {success: true};

  } catch (err) {        
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    } else {
      throw new Error('Erro inesperado: ' + err.message);
    }
  } finally {
    await connection.close();
  }
}

module.exports = {  
  categoriaUpdate
};
