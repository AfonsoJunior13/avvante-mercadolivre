const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const oracledb = require('oracledb');

async function configFind(unidade_empresarial_id) {

  const connection = await getConnection();
  try {
    const binds = {      
      UNIDADE_EMPRESARIAL_ID: unidade_empresarial_id
    };

    const result = await connection.execute(
      `SELECT * FROM VIEW_MERC_LIVRE_CONFIG WHERE UNIDADE_EMPRESARIAL_ID = :UNIDADE_EMPRESARIAL_ID`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    return result.rows;
    
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

async function configUpdate(unidade_empresarial_id, token, access_token, userID, expires_in) {
  
  const connection = await getConnection();
  try {
    
    await connection.execute(
      `BEGIN PRC_MLAPI_TOKEN_UPDATE(:P_UNIDADE_EMPRESARIAL_ID, :P_MLCN_TOKEN, :P_MLCN_ACCESS_TOKEN, :P_MLCN_USER_ID, :P_TIME_SEC, :P_TRANSACTION); END;`,
      {
        P_UNIDADE_EMPRESARIAL_ID: unidade_empresarial_id,        
        P_MLCN_TOKEN: token,
        P_MLCN_ACCESS_TOKEN: access_token,
        P_MLCN_USER_ID: userID,
        P_TIME_SEC: expires_in,
        P_TRANSACTION: '0'
      }
    );
    
    return {success: true};

  } catch (err) {
    logError(errorMsg);
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
  configFind,
  configUpdate
};
