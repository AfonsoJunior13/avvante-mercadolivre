const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const oracledb = require('oracledb');

async function tpAnuncioUpdate(data) {
  
  const connection = await getConnection();

  try {
    for (const item of data) {
        await connection.execute(
        `BEGIN PRC_MLAPI_TP_ANUNCIO_UPDATE(:P_MLTA_ID, :P_MLTA_NAME, :P_TRANSACTION); END;`,
        {
            P_MLTA_ID: item.id,        
            P_MLTA_NAME: item.name,
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
  tpAnuncioUpdate
};
